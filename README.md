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
For Windows systems, checkout [Ruby Installer For Windows](http://rubyinstaller.org/)

### Install required packages
CD to the root project directory inside a ruby command prompt.  Then to setup your ruby environment with the gems required by the application (per the Gemfile and using [bundler](http://bundler.io/) type the following commands:
```
gem install bundler
bundler install
```

## Creating Things
Your amazon credentials need to be in the appropriate location for the Amazon Ruby SDK , as defined at [this page](http://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs).  The easiest way to do this is through the [Amazon CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) as described [here](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-quick-configuration)

Once you've setup your credentials you are ready to use the add_amazon_iot_thing.rb script to add things.  Invoke with no arguments for command line usage.  In general you just need to specify a serial number and optionally a basename to use.
