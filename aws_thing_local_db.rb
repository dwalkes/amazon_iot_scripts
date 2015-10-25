# !/bin/ruby
# Dan Walkes
# 2015-10-24
# Abstraction for database storing local information (keys & certs) related to things

require_relative 'aws_shared.rb'

# As a simple rudamentary implementation we will store keys/certs in the filesystem
# under directory THING_FILE_DB_ROOT.  This has an added benefit that we can use the
# keys and certs with outside (ie command line) implementations
# In a production implementation you probably want a real database for this
class AwsThingLocalDb
  DB_KEY_THING_CERT="cert.pem"
  DB_KEY_THING_PRIVATE_KEY="thing_private_key.pem"
  DB_KEY_THING_PUBLIC_KEY="thing_public_key.pem"
  DB_KEY_THING_DESCRIPTION="thing_description.json"
  def initialize(thing_name)
    @name=thing_name
  end
  # @return true if the thing exists in the database
  def exist?
    Dir.exist?(get_db_dir)
  end
  # For key values, see DB_KEY definitions above
  def write(key,value)
    if !exist?
      FileUtils.mkdir_p(get_db_dir)
    end
    File.open(File.join(get_db_dir,key),'w') { | f | f.write(value) }
  end
  # For key values, see DB_KEY definitions above
  def read(key,value)
    string=nil
    File.open(File.join(get_db_dir,key),'r') { | f | string=f.read }
    string
  end
  def remove
    FileUtils.rm_rf(get_db_dir)
  end
  def location_description
    get_db_dir
  end
  private
  # Don't use these outside the class, file system specific implementation
  def get_db_dir
    File.join(THING_FILE_DB_ROOT,@name)
  end
end
