# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Script used to test MQTT send/receive functionality for a thing in Amazon IoT
require 'getoptlong'
require_relative 'aws_thing_local_db'
require_relative 'aws_shared.rb'
require_relative 'aws_iot_mqtt.rb'

APPLICATION_NAME='mqtt_client_test'
DEFAULT_TOPIC='topic/test'
DEFAULT_MESSAGE='Hello, World'

def printusage
  puts "#{APPLICATION_NAME} --thing_sn thing_unique_sn [--thing_name thing_name_prefix --topic topic --message mesagename]"
  puts "      Uses keys and certificates for a device created by add_amaozon_iot_thing.rb"
  puts "      to demonstrate basic MQTT client functionality"
  puts "        thing_unique_sn - A unique serial number assigned to this thing (string)"
  puts "        thing_name_prefix - An optional name prefix.  #{AwsIotShared::THING_NAME_PREFIX} if not specified"
  puts "        topic - A topic to use with publish.  \"#{DEFAULT_TOPIC}\" if not specified"
  puts "        message - A message to use with publish.  \"#{DEFAULT_MESSAGE}\" if not specified"
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--thing_sn', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--thing_name', '-n', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--topic', '-t', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--message', '-m', GetoptLong::REQUIRED_ARGUMENT ],
)

thing_name_prefix=AwsIotShared::THING_NAME_PREFIX
thing_sn=nil
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

thing_name=AwsIotShared::get_thing_name(thing_sn,thing_name_prefix)
puts "Publishing topic #{topic} message #{message} to thing #{thing_name}"
mqtt=AwsIotMqtt.new(thing_name)
mqtt.send_message_and_verify_response(topic,message)
mqtt.disconnect
