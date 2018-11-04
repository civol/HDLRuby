module HDLRuby


    ## The HDLRuby general error class.
    class AnyError < ::StandardError
    end

    module High
        ## The HDLRuby::High error class.
        class AnyError < HDLRuby::AnyError
        end

        ## The HDLRuby error class replacing the standard Ruby NoMethodError
        class NotDefinedError < AnyError
        end
    end

    module Low
        ## The HDLRuby::Low error class.
        class AnyError < HDLRuby::AnyError
        end
    end

    ## Execution context for processing error messages in +code+.
    #  The relevant error message to are assumed to be the ones whose file
    #  name is one given in +files+.
    def error_manager(files,&code)
        begin
            code.call
        rescue ::StandardError => e
            # pp e.backtrace
            # Keep the relevant 
            e.backtrace.select! do |mess|
                files.find {|file| mess.include?(File.basename(file))}
            end
            puts "#{e.backtrace[0]}: #{e.message}"
            e.backtrace[1..-1].each { |mess| puts "   from #{mess}"}
            exit
        rescue 
            raise "Big Bad Bug"
        end
    end
    
end
