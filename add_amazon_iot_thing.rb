# !/bin/ruby
# Dan Walkes
# 2015-10-24
# script used to add a thing to Amazon Iot
require 'getoptlong'
require_relative 'aws_shared'
require_relative 'aws_thing_local_db'
# This application file
APPLICATION_NAME='add_amazon_iot_thing.rb'
THING_SERIAL_NUMBER_ATTRIBUTE='ThingSerialNumber'
POLICY_DEFAULT_NAME="PubSubToAnyTopic"
POLICY_DEFAULT_CONTENT= <<POLICY_DEFAULT_CONTENT_END
{
    "Version": "2012-10-17", 
    "Statement": [{
        "Effect": "Allow",
        "Action":["iot:*"],
        "Resource": ["*"]
    }]
}
POLICY_DEFAULT_CONTENT_END
def printusage
  puts "#{APPLICATION_NAME} --thing_sn thing_unique_sn [--thing_name thing_name_prefix]"
  puts "      Creates (or deletes) a thing in Amazon IOT and sets up thing certificates"
  puts "      and keys in a folder at #{AwsThingLocalDb::THING_DB_ROOT}/name_prefix_thing_sn"
  puts "        thing_unique_sn - A unique serial number assigned to this thing (string)"
  puts "        thing_name_prefix - An optional name prefix.  #{AwsIotShared::THING_NAME_PREFIX} if not specified"
  puts "        delete : delete the device instead of creating.  Note: This also deletes any certs"
  puts "                  and keys associated with the device and removes from the local db"
  puts "                  please use with caution"
end

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--thing_sn', '-s', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--thing_name', '-n', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--delete', '-d', GetoptLong::NO_ARGUMENT]
)

thing_name_prefix=AwsIotShared::THING_NAME_PREFIX
thing_sn=nil
delete_thing_request=false
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
      delete_thing_request=true
  end
end

if thing_sn == nil
  puts "Missing thing_sn argument"
  printusage
  exit 1
end

thing_name=AwsIotShared::get_thing_name(thing_sn,thing_name_prefix)
thing_db_item=AwsThingLocalDb.new(thing_name)

iot=AwsIotShared::get_iot

if delete_thing_request
  puts "Attempting to delete thing based on passed argument"
  list_principals=iot.list_thing_principals({ thing_name: thing_name })
  list_principals.principals.each { |principal|
    puts "Detaching principal #{principal} from thing"
    iot.detach_thing_principal( {
      thing_name: thing_name,
      principal: principal
    })
    cert_regex_match=/:cert\/([a-z0-9]+)/.match(principal)
    if cert_regex_match == nil
      puts "Principal #{principal} is not a cert.  You may need to delete this manually"
    else
      cert_id=cert_regex_match[1]
      puts "Deleting principal: #{principal} with cert id #{cert_id}" 
      begin
        list_policies=iot.list_principal_policies( {
          principal: principal
        })
        list_policies.policies.each { | policy |
          puts "Principal has policy #{policy.inspect} attached, detaching this first"
          iot.detach_principal_policy({
            policy_name: policy.policy_name,
            principal: principal
          })
        }
        puts "Updating cert #{principal} to mark inactive"
        iot.update_certificate({
          certificate_id: cert_id,
          new_status: "INACTIVE"
        })
        puts "Deleting certificate #{principal}"
        iot.delete_certificate({
          certificate_id:cert_id
        })
      rescue=>e
        puts "Caught exception #{e.inspect} attempting to delete certificate"
        puts "You may need to delete certificate manually"
      end
    end
  }
  iot.delete_thing({ thing_name: thing_name })
  if thing_db_item.exist?
    thing_db_item.remove
  end
  puts "Thing #{thing_name} deleted.  Re-run without the delete argument to re-create with new certs and keys"
  exit 0
end

if thing_db_item.exist?
  puts "Thing at #{thing_db_item.location_description} already exists"
  puts "Please specify a unique thing name/serial number combination"
  puts "Or use the --delete option to delete, then re-create"
end

puts "Creating thing with name #{thing_name} and serial number attribute #{THING_SERIAL_NUMBER_ATTRIBUTE} set to #{thing_sn}"
create_thing_resp=iot.create_thing({
  thing_name: thing_name,
  attribute_payload: {
    attributes: {
      THING_SERIAL_NUMBER_ATTRIBUTE => thing_sn,
    },
  },
})
describe_thing_resp=iot.describe_thing({
  thing_name: thing_name,
})
puts "Writing #{AwsThingLocalDb::DB_KEY_THING_DESCRIPTION} based on return from describe_thing" 
thing_db_item.write(AwsThingLocalDb::DB_KEY_THING_DESCRIPTION,describe_thing_resp.attributes)
create_keys_resp=iot.create_keys_and_certificate({
  set_as_active: true,
})
puts "Writing certificates and public/private keys to thing database at #{thing_db_item.location_description} based on return from create_keys_and_certificate" 
thing_db_item.write(AwsThingLocalDb::DB_KEY_THING_CERT,create_keys_resp.certificate_pem)
thing_db_item.write(AwsThingLocalDb::DB_KEY_THING_PRIVATE_KEY,create_keys_resp.key_pair.private_key)
thing_db_item.write(AwsThingLocalDb::DB_KEY_THING_PUBLIC_KEY,create_keys_resp.key_pair.public_key)
policy_resp=nil
begin
  policy_resp=iot.get_policy({
    policy_name: POLICY_DEFAULT_NAME
  })
rescue Aws::IoT::Errors::ServiceError
end
if policy_resp==nil
  puts "Policy #{POLICY_DEFAULT_NAME} does not exist, creating"
  policy_resp=iot.create_policy({
    policy_name: POLICY_DEFAULT_NAME,
    policy_document: POLICY_DEFAULT_CONTENT 
  })
else
  puts "Skipping policy create since this has already been performed for policy #{POLICY_DEFAULT_NAME}"
end
puts "Attaching prinicipal policy #{POLICY_DEFAULT_NAME} to certificate with attach_principal_policy"
iot.attach_principal_policy({
  policy_name: POLICY_DEFAULT_NAME,
  principal: create_keys_resp.certificate_arn
})
puts "Attaching certificate to thing with attach_thing_principal"
iot.attach_thing_principal({
  thing_name: thing_name,
  principal: create_keys_resp.certificate_arn
})
