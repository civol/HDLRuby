require "HDLRuby/hruby_rsim"

##
# Library for enhancing the Ruby simulator with VCD support
#
########################################################################
module HDLRuby::High

    ## Converts a HDLRuby name to a VCD name.
    def self.vcd_name(name)
        return name.to_s.gsub(/[^a-zA-Z0-9_$]/,"$")
    end

    ##
    # Enhance the system type class with VCD support.
    class SystemT

        ## Initializes the displayer for generating a vcd on +vcdout+
        def show_init(vcdout)
            # puts "show_init"
            @vcdout = vcdout
            # Show the date.
            @vcdout << "$date\n"
            @vcdout << "   #{Time.now}\n"
            @vcdout << "$end\n"
            # Show the version.
            @vcdout << "$version\n"
            @vcdout << "  #{VERSION}\n"
            @vcdout << "$end\n"
            # Show the comment section.
            @vcdout << "$comment\n"
            @vcdout << "   Generated from HDLRuby Ruby simulator\n"
            @vcdout << "$end\n"
            # Show the time scale.
            @vcdout << "$timescale\n"
            @vcdout << "   1ps\n"
            @vcdout << "$end\n"
            # Displays the hierarchy of the variables.
            self.show_hierarchy(@vcdout)
            # Closes the header.
            @vcdout << "$enddefinitions $end\n"
            # Initializes the variables with their name.
            @vars_with_fullname = self.get_vars_with_fullname
            @vcdout << "$dumpvars\n"
            @vars_with_fullname.each_pair do |sig,fullname|
                if sig.f_value then
                    @vcdout << "   b#{sig.f_value.to_vstr} #{fullname}\n"
                else
                    # @vcdout << "   b#{"x"*sig.type.width} #{fullname}\n"
                    @vcdout << "   b#{"x"} #{fullname}\n"
                end
            end
            @vcdout << "$end\n"
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # Adds the signals of the interface of the system.
            self.each_signal do |sig|
                vars_with_fullname[sig] = HDLRuby::High.vcd_name(sig.fullname)
            end
            # Recurse on the scope.
            return self.scope.get_vars_with_fullname(vars_with_fullname)
        end

        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # puts "show_hierarchy for module #{self} (#{self.name})"
            # Shows the current level of hierarchy.
            vcdout << "$scope module #{HDLRuby::High.vcd_name(self.name)} $end\n"
            # Shows the interface signals.
            self.each_signal do |sig|
                # puts "showing signal #{HDLRuby::High.vcd_name(sig.fullname)}"
                vcdout << "$var wire #{sig.type.width} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.fullname)} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.name)} $end\n"
            end
            # Recurse on the scope.
            self.scope.show_hierarchy(vcdout)
            # Close the current level of hierarchy.
            vcdout << "$upscope $end\n"
        end

        ## Displays the time.
        def show_time
            @vcdout << "##{@time}\n"
        end

        ## Display the value of signal +sig+.
        def show_signal(sig)
            @vcdout << "b#{sig.f_value.to_vstr} "
            @vcdout << "#{@vars_with_fullname[sig]}\n"
        end
    end


    ##
    # Enhance the scope class with VCD support.
    class Scope
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # puts "show_hierarchy for scope=#{self}"
            # Shows the current level of hierarchy if there is a name.
            ismodule = false
            if  !self.name.empty? && !self.parent.is_a?(SystemT) then
                vcdout << "$scope module #{HDLRuby::High.vcd_name(self.fullname)} $end\n"
                ismodule = true
            end
            # Shows the inner signals.
            self.each_inner do |sig|
                # puts "showing inner signal #{HDLRuby::High.vcd_name(sig.fullname)}"
                vcdout << "$var wire #{sig.type.width} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.fullname)} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.name)} $end\n"
            end
            # Recurse on the behaviors' blocks
            self.each_behavior do |beh|
                beh.block.show_hierarchy(vcdout)
            end
            # Recurse on the systemI's Eigen system.
            self.each_systemI do |sys|
                sys.systemT.show_hierarchy(vcdout)
            end
            # Recurse on the subscopes.
            self.each_scope do |scope|
                scope.show_hierarchy(vcdout)
            end
            # Close the current level of hierarchy if there is a name.
            if ismodule then
                vcdout << "$upscope $end\n"
            end
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # Adds the inner signals.
            self.each_inner do |sig|
                vars_with_fullname[sig] = HDLRuby::High.vcd_name(sig.fullname)
            end
            # Recurse on the behaviors' blocks
            self.each_behavior do |beh|
                beh.block.get_vars_with_fullname(vars_with_fullname)
            end
            # Recurse on the systemI's Eigen system.
            self.each_systemI do |sys|
                sys.systemT.get_vars_with_fullname(vars_with_fullname)
            end
            # Recurse on the subscopes.
            self.each_scope do |scope|
                scope.get_vars_with_fullname(vars_with_fullname)
            end
            return vars_with_fullname
        end
    end


    ##
    # Enhance the Transmit class with VCD support.
    class Transmit
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # By default: nothing to do.
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # By default: nothing to do
        end
    end

    ##
    # Enhance the TimeWait class with VCD support.
    class TimeWait
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # By default: nothing to do.
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # By default: nothing to do
        end
    end

    ##
    # Enhance the Print class with VCD support.
    class Print
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # By default: nothing to do.
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # By default: nothing to do
        end
    end


    ## Module adding show_hierarchyto block objects.
    module BlockHierarchy
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # puts "show_hierarchy for block=#{self}"
            # Shows the current level of hierarchy if there is a name.
            ismodule = false
            unless self.name.empty?
                vcdout << "$scope module #{HDLRuby::High.vcd_name(self.name)} $end\n"
                ismodule = true
            end
            # Shows the inner signals.
            self.each_inner do |sig|
                # puts "showing inner signal #{HDLRuby::High.vcd_name(sig.fullname)}"
                vcdout << "$var wire #{sig.type.width} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.fullname)} "
                vcdout << "#{HDLRuby::High.vcd_name(sig.name)} $end\n"
            end
            # Recurse on the statements
            self.each_statement do |stmnt|
                stmnt.show_hierarchy(vcdout)
            end
            # Close the current level of hierarchy if there is a name.
            if ismodule then
                vcdout << "$upscope $end\n"
            end
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # Adds the inner signals.
            self.each_inner do |sig|
                vars_with_fullname[sig] = HDLRuby::High.vcd_name(sig.fullname)
            end
            # Recurse on the statements.
            self.each_statement do |stmnt|
                stmnt.get_vars_with_fullname(vars_with_fullname)
            end
            return vars_with_fullname
        end
    end


    ##
    # Enhance the block class with VCD support.
    class Block
        include HDLRuby::High::BlockHierarchy
    end


    ##
    # Enhance the block class with VCD support.
    class TimeBlock
        include HDLRuby::High::BlockHierarchy
    end


    ##
    # Enhance the if class with VCD support.
    class If
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # Recurse on the yes.
            self.yes.show_hierarchy(vcdout)
            # Recurse on the noifs.
            self.each_noif do |cond,stmnt|
                stmnt.show_hierarchy(vcdout)
            end
            # Recure on the no if any.
            self.no.show_hierarchy(vcdout) if self.no
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # Recurse on the yes.
            self.yes.get_vars_with_fullname(vars_with_fullname)
            # Recurse on the noifs.
            self.each_noif do |cond,stmnt|
                stmnt.get_vars_with_fullname(vars_with_fullname)
            end
            # Recure on the no if any.
            self.no.get_vars_with_fullname(vars_with_fullname) if self.no
            return vars_with_fullname
        end
    end


    ##
    # Enhance the Case class with VCD support.
    class Case
        ## Shows the hierarchy of the variables.
        def show_hierarchy(vcdout)
            # Recurse on each when.
            self.each_when do |w|
                w.statement.show_hierarchy(vcdout)
            end
            # Recurse on the default if any.
            self.default.show_hierarchy(vcdout)
        end

        ## Gets the VCD variables with their long name.
        def get_vars_with_fullname(vars_with_fullname = {})
            # Recurse on each when.
            self.each_when do |w|
                w.statement.get_vars_with_fullname(vars_with_fullname)
            end
            # Recurse on the default if any.
            self.default.get_vars_with_fullname(vars_with_fullname)
            return vars_with_fullname
        end
    end
end
