require 'logger'

# Add in multiple device logging directly into Logger class

class Logger
  # Creates or opens a secondary log file.
  def attach(name)
    @logdev.attach(name)
  end

  # Closes a secondary log file.
  def detach(name)
    @logdev.detach(name)
  end

  class LogDevice # :nodoc:
    attr_reader :devs

    def attach(log)
      @devs ||= {}
      @devs[log] = open_logfile(log)
    end

    def detach(log)
      @devs ||= {}
      @devs[log].close
      @devs.delete(log)
    end

    alias_method :old_write, :write

    def write(message)
      old_write(message)

      @devs ||= {}
      @devs.each do |log, dev|
        dev.write(message)
      end
    end
  end
end