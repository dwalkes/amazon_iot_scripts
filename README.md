# Amazon Iot Scripts
This project is a collection of scripts which automate the instructions in the [Aws IoT Quickstart](https://docs.aws.amazon.com/iot/latest/developerguide/iot-quickstart.html)

These scripts allow you to automate some of the setup tasks related to creating devices and keys which would otherwse need to be performed using the Amazon CLI

They also provide some basice troubleshooting to ensure communication with AWS is working as expected and provides some starter code examples for your IoT implementation

## Installation

### Setup Ruby
Start by setting up Ruby if you haven't already.
For Ubuntu this would be something like
```
sudo apt-get install ruby rubygems
```
For Windows systems, checkout [Ruby Installer For Windows](http://rubyinstaller.org/).
**Be sure to use verson 2.0 or later for TLS 1.2 support in ruby.**  This is important for the MQTT example.  See [this link](http://stackoverflow.com/questions/11059059/is-it-possible-to-enable-tls-v1-2-in-ruby-if-so-how) for background

### Install required packages
CD to the root project directory inside a ruby command prompt.  Then to setup your ruby environment with the gems required by the application (per the Gemfile and using [bundler](http://bundler.io/) type the following commands:
```
gem install bundler
bundler install
```

## Creating Things
Your amazon credentials need to be in the appropriate location for the Amazon Ruby SDK , as defined at [this page](http://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs).  The easiest way to do this is through the [Amazon CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) as described [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration)

Once you've setup your credentials you are ready to use the add_amazon_iot_thing.rb script to add things.  Invoke with no arguments for command line usage (ruby add_amazon_iot_thing.rb from the ruby command prompt).  In general you just need to specify a serial number and optionally a basename to use.

## Running MQTT Tests
Use the mqtt_client_test.rb to test mqtt operation.  Pay attention to the notes about ruby setup above... you need to ensure your OpenSSL has support for TLS version 1.2

This test implements the [MQTT Publish/Subscribe](https://docs.aws.amazon.com/iot/latest/developerguide/verify-pub-sub.html) messages example in ruby and provides some example code you could use within your IoT device if it happens to have ruby support.

Run with no arguments for usage instructions.

This test will use the database keyfiles created during the "Creating Things" step above.

## Running Device Shadow Test
Use the device_shadow_test.rb to test MQTT plsu device shadows.  Pay attention to the notes about ruby setup above
This test implements the get, delete, and update MQTT topics as described in the [Device Shadow MQTT Publish](http://docs.aws.amazon.com/iot/latest/developerguide/thing-shadow-mqtt.html) documentation.

Run with no arguments for usage instructions

Note:  --get will time out when the device state is empty or deleted, since the accepted MQTT endpoint is not being updated.  I haven't yet figured out how to resolve this.

This test will use the database keyfiles created during the "Creating Things" step above.
