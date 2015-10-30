# Dan Walkes
# 2015-10-25

require 'json'
require_relative 'aws_iot_mqtt'

# A class which extends AwsIotMqtt to add support for device shadows
class AwsIotMqttShadow < AwsIotMqtt
  class AwsIotMqttShadowException < StandardError; end
  def initialize(thing_name)
    super
  end
  def request_state(hash)
    shadow_hash=publish_shadow("update",{ :state => { :desired =>  hash  } })
    if !shadow_hash.has_key?("state")
      raise AwsIotMqttShadowException.new("request_state: Expected #{shadow_hash.inspect} to contain hash key :state")
    elsif !shadow_hash["state"].has_key?("desired")
      raise AwsIotMqttShadowException.new("request_state: Expected #{shadow_hash.inspect} [:state] to contain hash key :reported")
    elsif shadow_hash["state"]["desired"] != hash 
      raise AwsIotMqttShadowException.new("request_state: Expected state #{hash.inspect}, but got #{shadow_hash.inspect} instead")
    end
    shadow_hash
  end

  def delete
    publish_shadow("delete",{ "state" => nil }) 
  end

  def report_state(hash)
    shadow_hash=publish_shadow("update",{ "state" => { "reported" => hash  } })
    if !shadow_hash.has_key?("state")
      raise AwsIotMqttShadowException.new("report_state: Expected #{shadow_hash.inspect} to contain hash key :state")
    elsif !shadow_hash["state"].has_key?("reported")
      raise AwsIotMqttShadowException.new("report_state: Expected #{shadow_hash.inspect} [:state] to contain hash key :reported")
    elsif shadow_hash["state"]["reported"] != hash 
      raise AwsIotMqttShadowException.new("report_state: Expected state #{hash.inspect}, but got #{shadow_hash.inspect} instead")
    end
    shadow_hash
  end

  def get
    publish_shadow("get", { "state" => "get" })
  end
  private
  def publish_shadow(endpoint,hash)
    base_topic="$aws/things/#{thing_name}/shadow/#{endpoint}"
    if hash != nil
       send_message=hash.to_json
    else
       send_message="unused"
    end
    message=send_message_and_return_response(base_topic,base_topic+"/accepted",send_message)
    JSON.parse(message)
  end
end
