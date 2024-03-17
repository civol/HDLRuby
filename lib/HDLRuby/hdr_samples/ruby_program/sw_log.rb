require "rubyHDL.rb"

# Ruby program that logs some date from an input port.
# The log resuts are samed on file: sw_log.log

$logout = nil
$logger = nil

# Intialize the logging.
def boot
    # Create the log file.
    $logout = File.new("sw_log.log","w")
    # Create the logging function.
    $logger = Thread.new do
        loop do
            # Enter a waiting state.
            RubyHDL.ack = 0
            sleep
            # Get the value.
            val = RubyHDL.din
            # Log it.
            $logout.puts("At #{Time.now}, got #{val}")
            # Tell the value has been read.
            RubyHDL.ack = 1
            sleep
        end
    end
end

# Wakes the logging thread.
def log
    $logger.run
end
