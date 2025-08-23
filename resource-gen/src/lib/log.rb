#
#  log.rb
#
#
#  Created by JSilver on 2025/08/23.
#

module Log
    def self.print(level, message)
        case level
        when :debug
            puts "[DEBUG] #{message}"
        
        when :info
            puts "[INFO] #{message}"
        
        when :warn
            puts "[WARN] #{message}"
        
        when :error
            puts "[ERROR] #{message}"
        
        when :fatal
            puts "[FATAL] #{message}"
        end
    end
    
    def self.debug(message)
        print(:debug, message)
    end
    
    def self.info(message)
        print(:info, message)
    end
    
    def self.warn(message)
        print(:warn, message)
    end
    
    def self.error(message)
        print(:error, message)
    end
    
    def self.fatal(message)
        print(:fatal, message)
    end
end
