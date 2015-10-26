# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Script used to test MQTT send/receive functionality for a thing in Amazon IoT
require 'mqtt'
require 'eat'
require 'getoptlong'
require_relative 'aws_thing_local_db'
require_relative 'aws_shared.rb'
APPLICATION_NAME='mqtt_client_test'
DEFAULT_TOPIC='topic/test'
DEFAULT_MESSAGE='Hello, World'

def printusage
  puts "#{APPLICATION_NAME} --thing_sn thing_unique_sn [--thing_name thing_name_prefix --topic topic --message mesagename]"
  puts "      Uses keys and certificates for a device created by add_amaozon_iot_thing.rb"
  puts "      to demonstrate basic MQTT client functionality"
  puts "        thing_unique_sn - A unique serial number assigned to this thing (string)"
  puts "        thing_name_prefix - An optional name prefix.  #{THING_NAME_PREFIX} if not specified"
  puts "        topic - A topic to use with publish.  \"#{DEFAULT_TOPIC}\" if not specified"
  puts "        message - A message to use with publish.  \"#{DEFAULT_MESSAGE}\" if not specified"
end

# @return a path to the root CA, downloading if necessary
def get_path_to_root_ca
  path="rootCA.pem"
  if !File.exist?(path)
    puts "rootCA.pem does not exist, downloading"
    root_ca_str=eat("https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem")
    # get rid of ^M's which are in this file by default
    root_ca_str.gsub!("\r",'')
    File.open(path,'w') { | f | f.write(root_ca_str) }
  end
  path
end

# I initially had problems connecting to Amazon
# I found through troubleshooting that Ruby 1.9X used an old version of TLS, version 1
# and it appears Amazon requires version 1.2.  When I upgraded to Ruby 2.1 the problem
# went away.  Leaving this method here in case it's still useful to someone.  As long as
# your openssl includes TLS v1.2, however, the first connection attempt succeds in my experience
# @param connect_hash the parameters to pass to MQTT::Client.new
# @return a MQTT client with connection
def try_connect_methods(connect_hash)
  default_error=nil
  has_connection=true
  client = MQTT::Client.new(connect_hash)
  begin
    client.connect
  rescue OpenSSL::SSL::SSLError => default_error
    has_connection=false
    puts "Caught SSL error #{default_error.inspect} using default connect method"
    method_list=OpenSSL::SSL::SSLContext::METHODS.select{ |method| /TLS/.match(method) }
    puts "Trying supported TLS methods in #{method_list.inspect}"
    method_list.each { |method|
      puts "Trying method #{method} instead"
      client = MQTT::Client.new(connect_hash)
      client.ssl_context.ssl_version=method
      begin
        client.connect
        puts "Connection succeeded with type #{method}, using this method"
        has_connection=true
        break
      rescue OpenSSL::SSL::SSLError => e
        puts "Caught SSL error #{default_error.inspect} using connect method #{method}"
      end
    }
  end
  if !has_connection
    puts "Could not establish connection.  Make sure you have support for TLS v 1.2"
    puts "This probably requires openssl bundled with Ruby 2.0 or later"
    raise default_error
  end
  client
end

# @return a new mqtt connection based on passed params
def get_new_mqtt_connection(iot,thing_local_db)
  path_to_root_ca=get_path_to_root_ca
  address=iot.describe_endpoint.endpoint_address
  cert_file=thing_local_db.get_file_path(AwsThingLocalDb::DB_KEY_THING_CERT)
  key_file=thing_local_db.get_file_path(AwsThingLocalDb::DB_KEY_THING_PRIVATE_KEY)
  puts "Starting MQTT connection to address #{address} with cert file #{cert_file} key file #{key_file} and rootCA #{path_to_root_ca}"
  connect_hash= {
    :host => address,
    :port => 8883,
    :ssl => true,
    :cert_file => cert_file,
    :key_file => key_file,
    :ca_file => path_to_root_ca
  }
  try_connect_methods(connect_hash)
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--thing_sn', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--thing_name', '-n', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--topic', '-t', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--message', '-m', GetoptLong::REQUIRED_ARGUMENT ],
)

thing_name_prefix=THING_NAME_PREFIX
thing_sn=nil
delete_thing_request=false
topic=DEFAULT_TOPIC
message=DEFAULT_MESSAGE
opts.each do |opt,arg|
  case opt
    when '--help'
      printusage
      exit 1
    when '--thing_sn'
      thing_sn=arg
    when '--thing_name'
      thing_name_prefix=arg
    when '--topic'
      topic=arg
    when '--message'
      message=arg
  end
end
if thing_sn == nil
  puts "Missing thing_sn argument"
  printusage
  exit 1
end


# Receives a single message
# Intended to be run in a thread
class MQTTMessageReceiver
  attr_reader :topic
  attr_reader :message
  def initialize(client,topic)
    @client=client
    @topic=topic
  end
  def run
    @client.subscribe(@topic)
    @topic,@message=@client.get
    puts "Recieved topic #{@topic} message #{@message}"
  end 
  def disconnect
    @client.disconnect
  end
end

thing_name=get_thing_name(thing_sn,thing_name_prefix)
thing_local_db=AwsThingLocalDb.new(thing_name)
iot=get_iot

message_receiver=MQTTMessageReceiver.new(get_new_mqtt_connection(iot,thing_local_db),topic)
recever_thread = Thread.new { message_receiver.run }

mqtt_client=get_new_mqtt_connection(iot,thing_local_db)

puts "Publishing topic #{topic} message #{message}"
mqtt_client.publish(topic,message)
puts "Waiting for receiver thread to complete"
receiver_thread.join
success=true
if topic != message_receiver.topic
  puts "Error!  Expected topic #{topic} but found #{message_receiver.topic} in response"
  success=false
else
  puts "Found expected topic response #{topic} in receiver"
end

if message != message_receiver.message
  puts "Error!  Expected message #{message} but found #{message_receiver.message} in response"
  success=false
else
  puts "Found expected message response #{message} in receiver"
end

message_receiver.disconnect
mqtt_client.disconnect
if !success
  exit 1
end
