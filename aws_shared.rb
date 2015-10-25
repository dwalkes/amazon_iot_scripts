# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Shared data and methods for aws implementations

require 'parseconfig'

# This application file
APPLICATION_NAME='add_amazon_iot_thing.rb'
# The default prefix name of the thing
THING_NAME_PREFIX='iot_test_thing'
# The location of the thing database (see aws_thing_local_db)
THING_FILE_DB_ROOT='./thing_db'
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

def setup_aws_region
  if ENV['AWS_REGION'] == nil
    aws_config_file=File.join(Dir.home,".aws","config")
    if File.exist?(aws_config_file)
      config=ParseConfig.new(aws_config_file)
      params=config.get_params
      region=config['default']['region']
      puts "Region is not defined in environment variable ENV['AWS_REGION'], using #{region} from #{aws_config_file}"
      ENV['AWS_REGION']=region
    else
      puts "Region is not defined in environment varialbe ENV['AWS_REGION'] and could not be found in a config file at #{aws_config_file}"
      puts "Attempt to access aws may fail"
      puts "Please ensure you have configured AWS credentials properly and set environment variable AWS_REGION if necessary"
    end
  end
end
