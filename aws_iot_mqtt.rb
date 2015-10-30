# Dan Walkes
# 2015-10-24

require 'mqtt'
require 'eat'
require 'timeout'
require_relative 'app_logger'
require_relative 'aws_thing_local_db'

# A class wrapper around an Mqtt instance and AwsThingLocalDb
# which can create Mqtt clients setup for access to things (by name)
class AwsIotMqtt
  ROOTCA_PEM_FILE_PATH="rootCA.pem"
  include AppLogger
  attr_reader :thing_name
  class AwsIotMqttException < StandardError; end

  # Receives a single message on a topic
  # Intended to be run in a thread
  class MqttMessageReceiverThread
    attr_reader :topic
    include AppLogger

    def initialize(client,topic)
      @client=client
      @topic=topic
      @message=nil
    end
    def run
      @message=nil
      loop do 
        topic,message=@client.get(@topic)
        logger.debug { "Received message #{message} on topic #{topic}" } 
        if topic == @topic
          @message=message
        else
          logger.warn { "Expected topic #{@topic} got topic #{topic} instead" }
        end
        break if @message != nil
      end
    end
    def get_last_message
      @message
    end
  end
  def initialize(thing_name)
    @thing_name=thing_name
    @response_timeout=10
  end

  # @return a new mqtt connection based on passed params
  def get_client
    @client ||= create_mqtt_connected_client
  end

  def send_message_and_return_response(topic,accepted_topic,message)
    receiver_client=create_mqtt_connected_client
    receiver=MqttMessageReceiverThread.new(receiver_client,accepted_topic)
    thread=Thread.new { receiver.run }
    get_client.publish(topic,message)
    begin
      Timeout::timeout(@response_timeout) {
        thread.join 
      }
    rescue Timeout::Error
      thread.terminate
      raise AwsIotMqttException.new("Timed out after #{@response_timeout} seconds waiting for response from mqtt client on topic #{accepted_topic}")
    ensure 
      receiver_client.disconnect
    end
    receiver.get_last_message
  end

  def send_message_and_verify_response_on_topic(topic,accepted_topic,message)
    if message != send_message_and_return_response(topic,accepted_topic,message)
      raise AwsIotMqttException.new("Expected message #{message} from server, got #{receiver.get_last_message}")
    end
  end

  def send_message_and_verify_response(topic,message)
    # By default, use the same topic for the accepted topic
    send_message_and_verify_response_on_topic(topic,topic,message)
  end
  def disconnect
    get_client.disconnect
  end    
 
  private

  def get_thing_local_db
    @thing_local_db ||= AwsThingLocalDb.new(@thing_name)
  end

  def get_iot
    @iot ||= AwsIotShared.get_iot
  end 

  def create_mqtt_connected_client
    iot=get_iot
    thing_local_db=get_thing_local_db
    path_to_root_ca=get_path_to_root_ca
    address=iot.describe_endpoint.endpoint_address
    cert_file=thing_local_db.get_file_path(AwsThingLocalDb::DB_KEY_THING_CERT)
    key_file=thing_local_db.get_file_path(AwsThingLocalDb::DB_KEY_THING_PRIVATE_KEY)
    logger.debug { "Starting MQTT connection to address #{address} with cert file #{cert_file} key file #{key_file} and rootCA #{path_to_root_ca}" }
    client = MQTT::Client.new({
      :host => address,
      :port => 8883,
      :ssl => true,
      :cert_file => cert_file,
      :key_file => key_file,
      :ca_file => path_to_root_ca
    })
    client.connect
    client
  end
  # @return a path to the root CA, downloading if necessary
  def get_path_to_root_ca
    path=ROOTCA_PEM_FILE_PATH
    if !File.exist?(path)
      logger.debug { "rootCA.pem does not exist, downloading" }
      root_ca_str=eat("https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem")
      # get rid of ^M's which are in this file by default
      root_ca_str.gsub!("\r",'')
      File.open(path,'w') { | f | f.write(root_ca_str) }
    end
    path
  end
end
