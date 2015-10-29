require 'logger'

module AppLogger
  @@default_logger=STDOUT
  @@default_level=Logger::DEBUG

  def logger
    @logger ||= AppLogger.configure_logger_for(self)
  end
 
  class << self
    # Configures a logger for a class
    # selfptr the self pointer for a class which includes AppLogger
    def configure_logger_for(selfptr,file=@@default_logger)
      logger=Logger.new(file)
      logger.progname=selfptr.class.name
      logger.level=@@default_level
      logger
    end

    def set_default_level(level)
      @@default_level=level
    end
  end
end
