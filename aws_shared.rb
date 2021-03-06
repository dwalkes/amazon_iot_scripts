# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Shared data and methods for aws implementations

require 'parseconfig'
require 'aws-sdk'

class AwsIotShared
  # The default prefix name of the thing
  THING_NAME_PREFIX='iot_test_thing'

  def self.get_thing_name(thing_sn,thing_name_prefix=THING_NAME_PREFIX)
    "#{thing_name_prefix}_#{thing_sn}"
  end

  def self.setup_aws_region
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

  def self.get_iot
    if Gem.win_platform?
      # see https://github.com/aws/aws-sdk-core-ruby/issues/166
      # Avoids certificate error on Windows platforms
      Aws.use_bundled_cert!
    end
    setup_aws_region
    iot=Aws::IoT::Client.new
    iot
  end
end
