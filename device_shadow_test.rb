# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Test for device shadows

require 'getoptlong'
require 'json'
require_relative 'aws_shared'
require_relative 'aws_iot_mqtt_shadow'

APPLICATION_NAME='device_shadow_test.rb'
def printusage
  puts "#{APPLICATION_NAME} --thing_sn thing_unique_sn [--thing_name thing_name_prefix --update update_data --delete --get --request request_state]"
  puts "      Demonstrates AWS device shadows for Iot"
  puts "        thing_unique_sn - A unique serial number assigned to this thing (string) (see add_amazon_iot_thing command)"
  puts "        thing_name_prefix - An optional name prefix.  #{AwsIotShared::THING_NAME_PREFIX} if not specified"
  puts "                  and keys associated with the device and removes from the local db"
  puts "        --update specify update_data to use as key->value pairs for device (using JSON.parse syntax)"
  puts "              for instance '{\"val\":\"test\",\"val2\":\"test2\"}'"
  puts "        --delete delete all state data associated with this device shadow"
  puts "        --get get the device data"
  puts "        --request Instead of an --update state reflecting the current device state,"
  puts "            request a device update with this state.  Simulate another client who is"
  puts "            requesting a change of device state on another IoT device"
  puts "            Uses the same JSON.parse format for request_state as the format used by --update"  
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--thing_sn', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--thing_name', '-n', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--update', '-u', GetoptLong::REQUIRED_ARGUMENT],
  [ '--delete', '-d', GetoptLong::NO_ARGUMENT],
  [ '--get', '-g', GetoptLong::NO_ARGUMENT],
  [ '--request', '-r', GetoptLong::REQUIRED_ARGUMENT]
)

thing_name_prefix=AwsIotShared::THING_NAME_PREFIX
thing_sn=nil
delete=false
update=nil
delete=false
get=false
request=nil
opts.each do |opt,arg|
  case opt
    when '--help'
      printusage
      exit 1
    when '--thing_sn'
      thing_sn=arg
    when '--thing_name'
      thing_name_prefix=arg
    when '--delete'
      delete=true
    when '--update'
      update=arg
    when '--get'
      get=true
    when '--request'
      request=arg
  end
end

if update == nil && delete == false && get == false && request == nil
  puts "Must specify one of --update, --delete --get or --request"
  printusage
  exit 1
end
thing_name=AwsIotShared::get_thing_name(thing_sn,thing_name_prefix)
shadow=AwsIotMqttShadow.new(thing_name)
if update != nil
  puts "Reporting state #{update}"
  STDOUT.flush
  update_hash=JSON.parse(update)
  shadow.report_state(update_hash)
end

if delete
  shadow.delete
end

if get
  hash=shadow.get
  puts "Thing #{thing_name} has state #{hash.to_json}"
end

if request != nil
  puts "Requesting state #{request}"
  request_hash=JSON.parse(request)
  shadow.request_state(request_hash)
end
