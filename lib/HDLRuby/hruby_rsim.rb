require "HDLRuby/hruby_high"
# require "HDLRuby/hruby_low_resolve"
require "HDLRuby/hruby_bstr"
require "HDLRuby/hruby_values"



module HDLRuby::High

##
# Library for describing the Ruby simulator of HDLRuby
#
########################################################################



    class SystemT
        ## Enhance a system type with Ruby simulation.

        # Tell if the simulation is in multithread mode or not.
        attr_reader :multithread

        # The current global time.
        attr_reader :time

        ## Add untimed objet +obj+
        def add_untimed(obj)
            @untimeds << obj
        end

        ## Add timed behavior +beh+.
        #  Returns the id of the timed behavior.
        def add_timed_behavior(beh)
            @timed_behaviors << beh
            @total_timed_behaviors += 1
            return @total_timed_behaviors - 1
        end

        ## Remove timed beahvior +beh+
        def remove_timed_behavior(beh)
            # puts "remove_timed_behavior"
            @timed_behaviors.delete(beh)
        end

        ## Add +sig+ to the list of active signals.
        def add_sig_active(sig)
            # puts "Adding activated signal=#{sig.fullname}"
            @sig_active << sig
        end

        ## Advance the global simulator.
        def advance
            # # Display the time
            # self.show_time
            shown_values = {}
            # Get the behaviors waiting on activated signals.
            until @sig_active.empty? do
                # puts "sig_active.size=#{@sig_active.size}"
                # puts "sig_active=#{@sig_active.map {|sig| sig.fullname}}"
                # Look for the behavior sensitive to the signals.
                # @sig_active.each do |sig|
                #     sig.each_anyedge { |beh| @sig_exec << beh }
                #     if (sig.c_value.zero? && !sig.f_value.zero?) then
                #         # puts "sig.c_value=#{sig.c_value.content}"
                #         sig.each_posedge { |beh| @sig_exec << beh }
                #     elsif (!sig.c_value.zero? && sig.f_value.zero?) then
                #         sig.each_negedge { |beh| @sig_exec << beh }
                #     end
                # end
                @sig_active.each do |sig|
                    next if (sig.c_value.eql?(sig.f_value))
                    # next if (sig.c_value.to_vstr == sig.f_value.to_vstr)
                    # puts "for sig=#{sig.fullname}"
                    sig.each_anyedge { |beh| @sig_exec << beh }
                    if (sig.c_value.zero?) then
                        # puts "sig.c_value=#{sig.c_value.content}"
                        sig.each_posedge { |beh| @sig_exec << beh }
                    elsif (!sig.c_value.zero?) then
                        sig.each_negedge { |beh| @sig_exec << beh }
                    end
                end
                # Update the signals.
                @sig_active.each { |sig| sig.c_value = sig.f_value }
                # puts "first @sig_exec.size=#{@sig_exec.size}"
                @sig_exec.uniq! {|beh| beh.object_id }
                # puts "now @sig_exec.size=#{@sig_exec.size}"
                # Display the activated signals.
                @sig_active.each do |sig|
                    if !shown_values[sig].eql?(sig.f_value) then
                        self.show_signal(sig) 
                        shown_values[sig] = sig.f_value
                    end
                end
                # Clear the list of active signals.
                @sig_active.clear
                # puts "sig_exec.size=#{@sig_exec.size}"
                # Execute the relevant behaviors and connections.
                @sig_exec.each { |obj| obj.execute(:par) }
                @sig_exec.clear
                @sig_active.uniq! {|sig| sig.object_id }
                # puts "@sig_active.size=#{@sig_active.size}"
                # Compute the nearest next time stamp.
                @time = (@timed_behaviors.min {|b0,b1|  b0.time <=> b1.time }).time
            end
            # puts "@time=#{@time}"
            # Display the time
            self.show_time
        end

        ## Run the simulation from the current systemT and outputs the resuts
        #  on simout.
        def sim(simout)
            HDLRuby.show "Initializing Ruby-level simulator..."
            HDLRuby.show "#{Time.now}#{show_mem}"
            # Merge the included.
            self.merge_included!
            # Process par in seq.
            self.par_in_seq2seq!
            # Initializes the time.
            @time = 0
            # Initializes the time and signals execution buffers.
            @tim_exec = []
            @sig_exec = []
            # Initilize the list of untimed objects.
            @untimeds = []
            # Initialize the list of currently exisiting timed behavior.
            @timed_behaviors = []
            # Initialize the list of activated signals.
            @sig_active = []
            # Initializes the total number of timed behaviors (currently
            # existing or not: used for generating the id of the behaviors).
            @total_timed_behaviors = 0
            # Initilizes the simulation.
            self.init_sim(self)
            # Initialize the displayer.
            self.show_init(simout)

            # Initialize the untimed objects.
            self.init_untimeds
            # puts "End of init_untimed."

            # Maybe there is nothing to execute.
            return if @total_timed_behaviors == 0

            # Is there more than one timed behavior.
            if @total_timed_behaviors <= 1 then
                # No, no need of multithreading.
                @multithread = false
                # Simple execute the block of the behavior.
                @timed_behaviors[0].block.execute(:seq)
            else
                # Yes, need of multithreading.
                @multithread = true
                # Initializes the run mutex and the conditions.
                @mutex = Mutex.new
                @master = ConditionVariable.new
                @master_flag = 0
                @slave = ConditionVariable.new
                @slave_flags_not = 0
                @num_done = 0

                # First all the timed behaviors are to be executed.
                @timed_behaviors.each {|beh| @tim_exec << beh }
                # But starts locked.
                @slave_flags_not = 2**@timed_behaviors.size - 1
                # Starts the threads.
                @timed_behaviors.each {|beh| beh.make_thread }

                HDLRuby.show "Starting Ruby-level simulator..."
                HDLRuby.show "#{Time.now}#{show_mem}"
                # Run the simulation.
                self.run_init do
                    # # Wake the behaviors.
                    # @timed_behaviors.each {|beh| beh.run }
                    until @tim_exec.empty? do
                        # Execute the time behaviors that are ready.
                        self.run_ack
                        self.run_wait
                        # Advance the global simulator.
                        self.advance
                        # # Display the time
                        # self.show_time
                        # shown_values = {}
                        # # Get the behaviors waiting on activated signals.
                        # until @sig_active.empty? do
                        #     # # Update the signals.
                        #     # @sig_active.each { |sig| sig.c_value = sig.f_value }
                        #     # puts "sig_active.size=#{@sig_active.size}"
                        #     # Look for the behavior sensitive to the signals.
                        #     @sig_active.each do |sig|
                        #         sig.each_anyedge { |beh| @sig_exec << beh }
                        #         if (sig.c_value.zero? && !sig.f_value.zero?) then
                        #             # puts "sig.c_value=#{sig.c_value.content}"
                        #             sig.each_posedge { |beh| @sig_exec << beh }
                        #         elsif (!sig.c_value.zero? && sig.f_value.zero?) then
                        #             sig.each_negedge { |beh| @sig_exec << beh }
                        #         end
                        #     end
                        #     # Update the signals.
                        #     @sig_active.each { |sig| sig.c_value = sig.f_value }
                        #     # puts "first @sig_exec.size=#{@sig_exec.size}"
                        #     @sig_exec.uniq! {|beh| beh.object_id }
                        #     # Display the activated signals.
                        #     @sig_active.each do |sig|
                        #         if !shown_values[sig].eql?(sig.f_value) then
                        #             self.show_signal(sig) 
                        #             shown_values[sig] = sig.f_value
                        #         end
                        #     end
                        #     # Clear the list of active signals.
                        #     @sig_active.clear
                        #     # puts "sig_exec.size=#{@sig_exec.size}"
                        #     # Execute the relevant behaviors and connections.
                        #     @sig_exec.each { |obj| obj.execute(:par) }
                        #     @sig_exec.clear
                        #     @sig_active.uniq! {|sig| sig.object_id }
                        #     # puts "@sig_active.size=#{@sig_active.size}"
                        # end

                        # # Advance time.
                        # @time = (@timed_behaviors.min {|b0,b1|  b0.time <=> b1.time }).time
                        break if @timed_behaviors.empty?
                        # Schedule the next timed behavior to execute.
                        @tim_exec = []
                        @timed_behaviors.each do |beh|
                            @tim_exec << beh if beh.time == @time
                        end
                        # puts "@tim_exec.size=#{@tim_exec.size}"
                        # puts "@timed_bevaviors.size=#{@timed_behaviors.size}"
                    end
                end
            end
        end

        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # puts "init_sim for #{self} (#{self.name})"
            # Recurse on the signals.
            self.each_signal { |sig| sig.init_sim(systemT) }
            # Recure on the scope.
            self.scope.init_sim(systemT)
        end

        ## Initialize the untimed objects.
        def init_untimeds
            @untimeds.each do |obj|
                if obj.is_a?(Behavior) then
                    obj.block.execute(:seq)
                else
                    obj.execute(:seq)
                end
            end
        end
        
        ## Initialize run for executing +ruby_block+
        def run_init(&ruby_block)
            @mutex.synchronize(&ruby_block)
        end
        
        ## Request for running for timed behavior +id+
        def run_req(id)
            # puts "run_req with id=#{id} and @slave_flags_not=#{@slave_flags_not}"
            @slave.wait(@mutex) while @slave_flags_not[id] == 1
        end

        ## Tell running part done for timed behavior +id+.
        def run_done(id)
            # puts "run_done with id=#{id}"
            @num_done += 1
            @slave_flags_not |= 2**id
            if @num_done == @tim_exec.size
                # puts "All done."
                @master_flag = 1
                @master.signal
            end
        end

        ## Wait for all the run to complete.
        def run_wait
            # puts "run_wait"
            @master.wait(@mutex) unless @master_flag == 1
            @num_done = 0
            @master_flag = 0
        end

        ## Acknowledge the run request the executable timed behavior.
        def run_ack
            # puts "run_ack"
            mask = 0
            @tim_exec.each { |beh| mask |= 2**beh.id }
            mask = 2**@total_timed_behaviors - 1 - mask
            @slave_flags_not &= mask
            @slave.broadcast
        end

        ## Initializes the displayer
        def show_init(simout)
            # Sets the simulation output.
            @simout = simout
        end

        ## Displays the time.
        def show_time
            @simout.puts("# #{@time}ps")
        end

        ## Displays the value of signal +sig+.
        def show_signal(sig)
            @simout.puts("#{sig.fullname}: #{sig.f_value.to_vstr}")
        end

        ## Displays value +val+.
        def show_value(val)
            @simout.print(val.to_vstr)
        end

        ## Displays string +str+.
        def show_string(str)
            @simout.print(str)
        end


        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= (self.parent ? self.parent.fullname + ":" : "") + 
                self.name.to_s
            return @fullname
        end
    end


    class Scope
        ## Enhance a scope with Ruby simulation.
        
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the inner signals.
            self.each_inner { |sig| sig.init_sim(systemT) }
            # Recurse on the behaviors.
            self.each_behavior { |beh| beh.init_sim(systemT) }
            # Recurse on the systemI.
            self.each_systemI { |sys| sys.init_sim(systemT) }
            # Recurse on the connections.
            # self.each_connection { |cnx| cnx.init_sim(systemT) }
            self.each_connection do |cnx|
                # Connection to a real expression?
                if !cnx.right.is_a?(RefObject) then
                    # Yes.
                    cnx.init_sim(systemT)
                else
                    # No, maybe the reverse connection is also required.
                    # puts "cnx.left.object=#{cnx.left.object.fullname} cnx.right.object=#{cnx.right.object.fullname}"
                    cnx.init_sim(systemT)
                    if cnx.left.is_a?(RefObject) then
                        sigL = cnx.left.object
                        prtL = sigL.parent
                        if prtL.is_a?(SystemT) and prtL.each_inout.any?{|e| e.object_id == sigL.object_id} then
                            # puts "write to right with sigL=#{sigL.fullname}."
                            Connection.new(cnx.right.clone,cnx.left.clone).init_sim(systemT)
                        end
                    end
                end
            end
            # Recurse on the sub scopes.
            self.each_scope { |sco| sco.init_sim(systemT) }
        end

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
        end
    end


    ## Extends the TypeTuple class for Ruby simulation.
    class TypeTuple
        # Add the possibility to change the direction.
        def direction=(dir)
            @direction = dir == :little ? :little : :big
        end
    end

    ## Extends the TypeStruct class for Ruby simulation.
    class TypeStruct
        # Add the possibility to change the direction.
        def direction=(dir)
            @direction = dir == :little ? :little : :big
        end
    end


    ##
    # Describes a behavior.
    class Behavior

        ## Execute the expression.
        def execute(mode)
            return self.block.execute(mode)
        end

        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Add the behavior to the list of untimed objects.
            systemT.add_untimed(self)
            # Process the sensitivity list.
            # Is it a clocked behavior?
            events = self.each_event.to_a
            if events.empty? then
                # No events, this is not a clock behavior.
                # And it is not a time behavior neigther.
                # Generate the events list from the right values.
                # First get the references.
                refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefObject) && !node.leftvalue? && 
                        !node.parent.is_a?(RefObject) 
                end.to_a
                # Keep only one ref per signal.
                refs.uniq! { |node| node.fullname }
                # puts "refs=#{refs.map {|node| node.fullname}}"
                # The get the left references: the will be removed from the
                # events.
                left_refs = self.block.each_node_deep.select do |node|
                    node.is_a?(RefObject) && node.leftvalue? && 
                        !node.parent.is_a?(RefObject) 
                end.to_a
                # Keep only one left ref per signal.
                left_refs.uniq! { |node| node.fullname }
                # Remove the inner signals from the list.
                self.block.each_inner do |inner|
                    refs.delete_if {|r| r.fullname == inner.fullname }
                end
                # Remove the left refs.
                left_refs.each do |l| 
                    refs.delete_if {|r| r.fullname == l.fullname }
                end
                # Generate the event.
                events = refs.map {|ref| Event.new(:anyedge,ref.clone) }
                # Add them to the behavior for further processing.
                events.each {|event| self.add_event(event) }
            end
            # Now process the events: add the behavior to the corresponding
            # activation list of the signals of the events.
            self.each_event do |event|
                sig = event.ref.object
                case event.type
                when :posedge
                    sig.add_posedge(self)
                when :negedge
                    sig.add_negedge(self)
                else
                    sig.add_anyedge(self)
                end
            end
            # Now process the block.
            self.block.init_sim(systemT)
        end

        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end


    ##
    # Describes a timed behavior.
    #
    # NOTE: 
    # * this is the only kind of behavior that can include time statements. 
    # * this kind of behavior is not synthesizable!
    class TimeBehavior
        ## Get the current time of the behavior.
        attr_accessor :time
        ## Get the id of the timed behavior.
        attr_reader :id

        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            @sim = systemT
            # Add the behavior to the list of timed behavior.
            @id = systemT.add_timed_behavior(self)
            # Initialize the time to 0.
            @time = 0
            # Initialize the statements.
            self.block.init_sim(systemT)
        end

        # Create the execution thread
        def make_thread
            systemT = @sim
            @thread = Thread.new do
                # puts "In thread."
                # sleep
                systemT.run_init do
                    begin
                        # puts "Starting thread"
                        systemT.run_req(@id)
                        # self.block.execute(:par)
                        self.block.execute(:seq)
                        # puts "Ending thread"
                    rescue => e
                        puts "Got exception: #{e.full_message}"
                    end
                    systemT.remove_timed_behavior(self)
                    systemT.run_done(@id)
                end
            end
        end

        ## (Re)start execution of the thread.
        def run
            # Run.
            @thread.run
        end
    end


    ## 
    # Describes an event.
    class Event
        # Nothing to do.
    end


    ##
    # Module for extending signal classes with Ruby-level simulation.
    module SimSignal
        # Access the current and future value.
        attr_accessor :c_value, :f_value

        ## Initialize the simulation for +systemT+
        def init_sim(systemT)
            # Initialize the local time to -1
            @time = -1
            @sim = systemT
            # Recurse on the sub signals if any.
            if self.each_signal.any? then
                self.each_signal {|sig| sig.init_sim(systemT) }
                return
            end
            # No sub signal, really initialize the current signal.
            if self.value then
                @c_value = self.value.execute(:par).to_value
                @f_value = @c_value.to_value
                # puts "init signal value at=#{@c_value.to_bstr}"
                # The signal is considered active.
                systemT.add_sig_active(self)
            else
                # @c_value = Value.new(self.type,"x" * self.type.width)
                # @f_value = Value.new(self.type,"x" * self.type.width)
                @c_value = Value.new(self.type,"x")
                @f_value = Value.new(self.type,"x")
            end
        end

        ## Adds behavior +beh+ activated on a positive edge of the signal.
        def add_posedge(beh)
            # Recurse on the sub signals.
            self.each_signal {|sig| sig.add_posedge(beh) }
            # Apply on current signal.
            @posedge_behaviors ||= []
            @posedge_behaviors << beh
        end

        ## Adds behavior +beh+ activated on a negative edge of the signal.
        def add_negedge(beh)
            # Recurse on the sub signals.
            self.each_signal {|sig| sig.add_negedge(beh) }
            # Apply on current signal.
            @negedge_behaviors ||= []
            @negedge_behaviors << beh
        end

        ## Adds behavior +beh+ activated on a any edge of the signal.
        def add_anyedge(beh)
            # Recurse on the sub signals.
            self.each_signal {|sig| sig.add_anyedge(beh) }
            # Apply on current signal.
            @anyedge_behaviors ||= []
            @anyedge_behaviors << beh
        end

        ## Iterates over the behaviors activated on a positive edge.
        def each_posedge(&ruby_block)
            @posedge_behaviors ||= []
            @posedge_behaviors.each(&ruby_block)
        end

        ## Iterates over the behaviors activated on a negative edge.
        def each_negedge(&ruby_block)
            @negedge_behaviors ||= []
            @negedge_behaviors.each(&ruby_block)
        end

        ## Iterates over the behaviors activated on any edge.
        def each_anyedge(&ruby_block)
            @anyedge_behaviors ||= []
            @anyedge_behaviors.each(&ruby_block)
        end


        ## Execute the expression.
        def execute(mode)
            # puts "Executing signal=#{self.fullname} in mode=#{mode}  with c_value=#{self.c_value} and f_value=#{self.f_value}"
            return @mode == :seq ? self.f_value : self.c_value
            # return @mode == :seq || mode == :seq ? self.f_value : self.c_value
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            # # Set the next value.
            # @f_value = value
            # Set the mode.
            @mode = mode
            # @f_value = value.cast(self.type) # Cast not always inserted by HDLRuby normally
            if @sim.time > @time or !value.impedence? then
                # puts "assign #{value.content} to #{self.fullname}"
                @f_value = value.cast(self.type) # Cast not always inserted by HDLRuby normally
                @time = @sim.time
            end
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # @f_value = @f_value.assign_at(mode,value,index)
            # Sets the next value.
            if (@f_value.equal?(@c_value)) then
                # Need to duplicate @f_value to avoid side effect.
                @f_value = Value.new(@f_value.type,@f_value.content.clone)
            end
            @f_value[index] = value
            # Sets the mode
            @mode = mode
        end



        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
        end

    end

    ##
    # Describes a signal.
    class SignalI
        include SimSignal
    end

    ##
    # Describes a constant signal.
    class SignalC
        include SimSignal
    end


    ## 
    # Describes a system instance.
    # 
    # NOTE: an instance can actually represented muliple layers
    #       of systems, the first one being the one actually instantiated
    #       in the final RTL code.
    #       This layering can be used for describing software or partial
    #       (re)configuration.
    class SystemI
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the Eigen system.
            self.systemT.init_sim(systemT)
        end
    end


    ##
    # Describes a non-HDLRuby code chunk.
    class Chunk
        # TODO
    end


    ##
    # Decribes a set of non-HDLRuby code chunks.
    class Code
        # TODO
    end


    ## 
    # Describes a statement.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Statement
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            raise "init_sim must be implemented in class #{self.class}"
        end

        ## Executes the statement in +mode+ (:blocking or :nonblocking)
        #  NOTE: to be overrided.
        def execute(mode)
            raise "execute must be implemented in class #{self.class}"
        end
    end


    ## 
    # Decribes a transmission statement.
    class Transmit
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.left.init_sim(systemT)
            self.right.init_sim(systemT)
        end

        ## Executes the statement.
        def execute(mode)
            # puts "execute Transmit in mode=#{mode} for left=#{self.left.object.fullname}" if left.is_a?(RefObject)
            self.left.assign(mode,self.right.execute(mode))
        end
    end


    ## 
    # Describes an if statement.
    class If
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.yes.init_sim(systemT)
            # self.each_noif { |cond,stmnt| stmnt.init_sim(systemT) } 
            self.each_noif do |cond,stmnt| 
                cond.init_sim(systemT)
                stmnt.init_sim(systemT)
            end
            self.no.init_sim(systemT) if self.no
        end

        ## Executes the statement.
        def execute(mode)
            # puts "execute hif with mode=#{mode}"
            # Check the main condition.
            if !(self.condition.execute(mode).zero?) then
                self.yes.execute(mode)
            else
                # Check the other conditions (elsif)
                success = false
                self.each_noif do |cond,stmnt|
                    if !(cond.execute(mode).zero?) then
                        stmnt.execute(mode)
                        success = true
                        break
                    end
                end
                self.no.execute(mode) if self.no && !success
            end
        end
    end


    ##
    # Describes a when for a case statement.
    class When
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.statement.init_sim(systemT)
        end
    end


    ## 
    # Describes a case statement.
    class Case
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.each_when { |wh| wh.init_sim(systemT) }
            self.default.init_sim(systemT) if self.default
        end

        ## Executes the statement.
        def execute(mode)
            unless self.each_when.find do |wh|
                if wh.match.eql?(self.value.execute(mode)) then
                    wh.statement.execute(mode)
                    return
                end
            end
            self.default.execute(mode) if self.default
            end
        end
    end


    ##
    # Describes a delay: not synthesizable.
    class Delay
        ## Get the time of the delay in pico seconds.
        def time_ps
            case self.unit
            when :ps
                return self.value.to_i 
            when :ns
                return self.value.to_i * 1000
            when :us
                return self.value.to_i * 1000000
            when :ms
                return self.value.to_i * 1000000000
            when :s
                return self.value.to_i * 1000000000000
            end
        end
    end


    ## 
    # Describes a print statement: not synthesizable!
    class Print
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            @sim = systemT
        end

        ## Executes the statement.
        def execute(mode)
            self.each_arg.map do |arg|
                case arg
                when StringE
                    @sim.show_string(arg.content)
                when SignalI
                    @sim.show_signal(arg)
                when SignalC
                    @sim.show_signal(arg)
                else
                    @sim.show_value(arg.execute(mode))
                end
            end
        end
    end


    ## 
    # Describes a system instance (re)configuration statement: not synthesizable!
    class Configure
        ## TODO
    end


    ## 
    # Describes a wait statement: not synthesizable!
    class TimeWait
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            @sim = systemT
        end

        ## Executes the statement.
        def execute(mode)
            @behavior ||= self.behavior
            @behavior.time += self.delay.time_ps
            if @sim.multithread then
                # Multi thread mode: synchronize.
                # puts "Stopping #{@behavior.object_id} (@behavior.time=#{@behavior.time})..."
                @sim.run_done(@behavior.id)
                # puts "Rerunning #{@behavior.object_id} (@behavior.time=#{@behavior.time})..."
                @sim.run_req(@behavior.id)
            else
                # No thread mode, need to advance the global simulator.
                @sim.advance
            end
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurde on the statement.
            self.statement.init_sim(systemT)
        end

        ## Executes the statement.
        def execute(mode)
            self.number.times { self.statement.execute(mode) }
        end
    end


    ## 
    # Describes a timed terminate statement: not synthesizable!
    class TimeTerminate
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            @sim = systemT
        end

        ## Executes the statement.
        def execute(mode)
            # @behavior ||= self.get_behavior
            # @behavior.terminate
            exit
        end
    end


    ## 
    # Describes a block.
    class Block
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the inner signals.
            self.each_inner { |sig| sig.init_sim(systemT) }
            # Recurde on the statements.
            self.each_statement { |stmnt| stmnt.init_sim(systemT) }
        end

        ## Executes the statement.
        def execute(mode)
            # puts "execute block of mode=#{self.mode}"
            self.each_statement { |stmnt| stmnt.execute(self.mode) }
        end

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
        end
    end

    class If
        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end

    class When
        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end

    class Case
        ## Returns the name of the signal with its hierarchy.
        def fullname
            return self.parent.fullname
        end
    end

    # Describes a timed block.
    #
    # NOTE: 
    # * this is the only kind of block that can include time statements. 
    # * this kind of block is not synthesizable!
    class TimeBlock
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.each_statement { |stmnt| stmnt.init_sim(systemT) }
        end

        ## Executes the statement.
        def execute(mode)
            # puts "TimeBlock"
            self.each_statement do |stmnt|
                # puts "Going to execute statement: #{stmnt}"
                stmnt.execute(self.mode)
            end
            # puts "End TimeBlock"
        end
    end


    ## 
    # Describes a connection.
    class Connection

        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Add the connection to the list of untimed objets.
            systemT.add_untimed(self)
            # Recurse on the left and right.
            self.left.init_sim(systemT)
            self.right.init_sim(systemT)
            # Process the sensitivity list.
            # Is it a clocked behavior?
            events = []
            # Generate the events list from the right values.
            # First get the references.
            refs = self.right.each_node_deep.select do |node|
                node.is_a?(RefObject) && !node.parent.is_a?(RefObject) 
            end.to_a
            # Keep only one ref per signal.
            refs.uniq! { |node| node.fullname }
            # puts "connection input: #{self.left.fullname}"
            # puts "connection refs=#{refs.map {|node| node.fullname}}"
            # # Generate the event.
            # events = refs.map {|ref| Event.new(:anyedge,ref) }
            # # Add them to the behavior for further processing.
            # events.each {|event| self.add_event(event) }
            # Now process the events: add the connection to the corresponding
            # activation list of the signals of the events.
            refs.each {|ref| ref.object.add_anyedge(self) }
        end

        ## Executes the statement.
        def execute(mode)
            # puts "connection left=#{left.object.fullname}"
            # self.left.assign(mode,self.right.execute(mode))
            self.left.assign(:seq,self.right.execute(mode))
        end
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # By default: do nothing.
        end

        ## Executes the expression in +mode+ (:blocking or :nonblocking)
        #  NOTE: to be overrided.
        def execute(mode)
            raise "execute must be implemented in class #{self.class}"
        end
    end

    
    ##
    # Describes a value.
    class Value
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Nothing to do.
        end

        # include Vprocess

        ## Executes the expression.
        def execute(mode)
            return self
        end
    end


    ##
    # Describes a cast.
    class Cast
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the child.
            self.child.init_sim(systemT)
        end

        ## Executes the expression.
        def execute(mode)
            # puts "child=#{self.child}"
            # puts "child object=#{self.child.object}(#{self.child.object.name})" if self.child.is_a?(RefObject)
            # Shall we reverse the content of a concat.
            if self.child.is_a?(Concat) && 
                    self.type.direction != self.child.type.direction then
                # Yes, do it.
                res = self.child.execute(mode,:reverse)
            else
                res = self.child.execute(mode)
            end
            # puts "res=#{res}"
            # Cast it.
            res = res.cast(self.type,true)
            # Returns the result.
            return res
        end
    end


    ##
    # Describes an operation.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Operation
        ## Left to the children.
    end


    ## 
    # Describes an unary operation.
    class Unary
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the child.
            self.child.init_sim(systemT)
        end

        ## Execute the expression.
        def execute(mode)
            # puts "Unary with operator=#{self.operator}"
            # Recurse on the child.
            tmp = self.child.execute(mode)
            # puts "tmp=#{tmp}"
            # Apply the operator.
            return tmp.send(self.operator)
        end
    end


    ##
    # Describes an binary operation.
    class Binary
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the children.
            self.left.init_sim(systemT)
            self.right.init_sim(systemT)
        end

        ## Execute the expression.
        def execute(mode)
            # Recurse on the children.
            tmpl = self.left.execute(mode)
            tmpr = self.right.execute(mode)
            # Apply the operator.
            return tmpl.send(self.operator,tmpr)
        end
    end


    ##
    # Describes a selection operation (generalization of the ternary operator).
    #
    # NOTE: choice is using the value of +select+ as an index.
    class Select
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the children.
            self.select.init_sim(systemT)
            self.each_choice { |choice| choice.init_sim(systemT) }
        end

        ## Execute the expression.
        def execute(mode)
            unless @mask then
                # Need to initialize the execution of the select.
                width = (@choices.size-1).width
                width = 1 if width == 0
                @mask = 2**width - 1
                @choices.concat([@choices[-1]] * (2**width-@choices.size))
            end
            # Recurse on the select.
            tmps = self.select.execute(mode).to_i & @mask
            # puts "select tmps=#{tmps}, @choices.size=#{@choices.size}"
            # Recurse on the selection result.
            return @choices[tmps].execute(mode)
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the children.
            self.each_expression { |expr| expr.init_sim(systemT) }
        end

        ## Execute the expression.
        def execute(mode, reverse=false)
            # Recurse on the children.
            tmpe = self.each_expression.map { |expr| expr.execute(mode) }
            # Ensure the order of the elements matches the type.
            if (self.type.direction == :little && !reverse) || 
               (self.type.direction == :big && reverse) then
                tmpe.reverse!
            end
            # puts "concat result=#{Vprocess.concat(*tmpe).to_bstr}"
            # Concatenate the result.
            return Vprocess.concat(*tmpe)
        end
    end


    ## 
    # Describes a reference expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Ref
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            raise "assign must be implemented in class #{self.class}"
        end

        ## Assigns +value+ to the reference.
        #  Must be overriden.
        def assign(mode,value)
            raise "assign must be implemented in class #{self.class}"
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            raise "assign_at must be implemented in class #{self.class}"
        end
    end


    ##
    # Describes concatenation reference.
    class RefConcat
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.each_ref { |ref| ref.init_sim(systemT) }
        end

        ## Execute the expression.
        def execute(mode)
            # Recurse on the children.
            tmpe = self.each_ref.map { |ref| ref.execute(mode) }
            # Concatenate the result.
            return tmpe.reduce(:concat)
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            # puts "self.type=#{self.type}"
            # Flatten the value type.
            value.type = [value.type.width].to_type
            pos = 0
            width = 0
            # Recurse on the children.
            @refs.reverse_each do |ref|
                # puts "ref.type=#{ref.type}"
                width = ref.type.width
                # puts "pos=#{pos} width=#{width}, pos+width-1=#{pos+width-1}"
                # puts "value.content=#{value.content}"
                # puts "value[(pos+width-1).to_expr..pos.to_expr].content=#{value[(pos+width-1).to_expr..pos.to_expr].content}"
                ref.assign(mode,value[(pos+width-1).to_expr..pos.to_expr])
                # Prepare for the next reference.
                pos += width
            end
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # Get the refered value.
            refv = self.execute(mode,value)
            # Assign to it.
            refv.assign_at(mode,value,index)
            # Update the reference.
            self.assign(mode,refv)
        end
    end


    ## 
    # Describes a index reference.
    class RefIndex
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.ref.init_sim(systemT)
        end

        ## Execute the expression.
        def execute(mode)
            # Recurse on the children.
            tmpr = self.ref.execute(mode)
            idx = self.index.execute(mode)
            # puts "tmpr=#{tmpr} idx=#{idx} tmpr[idx]=#{tmpr[idx]}"
            return tmpr[idx]
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            # Compute the index.
            idx = self.index.execute(mode).to_i
            # Assigns.
            self.ref.assign_at(mode,value,idx)
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # Get the refered value.
            refv = self.execute(mode)
            # Assign to it.
            refv = refv.assign_at(mode,value,index)
            # Update the refered value.
            self.assign(mode,refv)
        end

    end


    ## 
    # Describes a range reference.
    class RefRange
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.ref.init_sim(systemT)
        end

        ## Execute the expression.
        def execute(mode)
            # Recurse on the children.
            tmpr = self.ref.execute(mode)
            rng  = (self.range.first.execute(mode))..
                (self.range.last.execute(mode))
            # puts "tmpr=#{tmpr} rng=#{rng} tmpr[rng]=#{tmpr[rng]}"
            return tmpr[rng]
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            # Compute the index range.
            rng = (self.range.first.execute(mode).to_i)..
                (self.range.last.execute(mode).to_i)
            # Assigns.
            self.ref.assign_at(mode,value,rng)
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # Get the refered value.
            refv = self.execute(mode)
            # Assign to it.
            refv = refv.assign_at(mode,value,index)
            # Update the refered value.
            self.assign(mode,refv)
        end
    end


    ##
    # Describes a name reference.
    class RefName
        # Not used?
    end


    ## 
    # Describe a this reference.
    #
    # This is the current system.
    class RefThis
        # Not used.
    end


    ##
    # Describes a high-level object reference: no low-level equivalent!
    class RefObject
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # puts "init_sim for RefObject=#{self}"
            @sim = systemT

            # Modify the exectute and assign methods if the object has
            # sub signals (for faster execution).
            if self.object.each_signal.any? then
                ## Execute the expression.
                self.define_singleton_method(:execute) do |mode|
                    # Recurse on the children.
                    iter = self.object.each_signal
                    iter = iter.reverse_each unless self.object.type.direction == :big
                    tmpe = iter.map {|sig| sig.execute(mode) }
                    # Concatenate the result.
                    # return tmpe.reduce(:concat)
                    return Vprocess.concat(*tmpe)
                end
                ## Assigns +value+ the the reference.
                self.define_singleton_method(:assign) do |mode,value|
                    # puts "RefObject #{self} assign with object=#{self.object}"
                    # Flatten the value type.
                    value.type = [value.type.width].to_type
                    pos = 0
                    width = 0
                    # Recurse on the children.
                    iter = self.object.each_signal
                    iter = iter.reverse_each unless self.object.type.direction == :big
                    iter.each do |sig|
                        width = sig.type.width
                        sig.assign(mode,value[(pos+width-1).to_expr..pos.to_expr])
                        # Tell the signal changed.
                        if !(sig.c_value.eql?(sig.f_value)) then
                            @sim.add_sig_active(sig)
                        end
                        # Prepare for the next reference.
                        pos += width
                    end
                end
            end
        end

        ## Execute the expression.
        def execute(mode)
            return self.object.execute(mode)
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            self.object.assign(mode,value)
            # puts "name=#{self.object.name} value=#{value.to_vstr}"
            # puts "c_value=#{self.object.c_value.content}" if self.object.c_value
            # puts "f_value=#{self.object.f_value.content}" if self.object.f_value
            if !(self.object.c_value.eql?(self.object.f_value)) then
                @sim.add_sig_active(self.object)
            end
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # puts "name=#{self.object.name} value=#{value.to_vstr}"
            self.object.assign_at(mode,value,index)
            # puts "c_value=#{self.object.c_value.content}" if self.object.c_value
            # puts "f_value=#{self.object.f_value.content}" if self.object.f_value
            if !(self.object.c_value.eql?(self.object.f_value)) then
                @sim.add_sig_active(self.object)
            end
        end
    end


    ##
    # Describes a string.
    #
    # NOTE: This is not synthesizable!
    class StringE
    end
end
