require "HDLRuby/hruby_high"
# require "HDLRuby/hruby_low_resolve"
require "HDLRuby/hruby_bstr"
require "HDLRuby/hruby_values"




##
# Library for describing the Ruby simulator of HDLRuby
#
########################################################################
module HDLRuby::High

    ##
    # Enhance a system type with Ruby simulation.
    class SystemT

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

        ## Run the simulation from the current systemT and outputs the resuts
        #  on simout.
        def sim(simout)
            # Merge the included.
            self.merge_included!
            # Initializes the run mutex and the conditions.
            @mutex = Mutex.new
            @master = ConditionVariable.new
            @master_flag = 0
            @slave = ConditionVariable.new
            @slave_flags_not = 0
            @num_done = 0
            # @lock = 0
            # @runs = 0
            # Initializes the time.
            @time = 0
            # Initializes the time and signals execution buffers.
            @tim_exec = []
            @sig_exec = []
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
            # exit
            # First all the timed behaviors are to be executed.
            @timed_behaviors.each {|beh| @tim_exec << beh }
            # But starts locked.
            @slave_flags_not = 2**@timed_behaviors.size - 1
            # Starts the threads.
            @timed_behaviors.each {|beh| beh.make_thread }

            # Run the simulation.
            self.run_init do
                # # Wake the behaviors.
                # @timed_behaviors.each {|beh| beh.run }
                until @tim_exec.empty? do
                    # Display the time
                    self.show_time
                    # Execute the time behaviors that are ready.
                    self.run_ack
                    self.run_wait
                    shown_values = {}
                    # Get the behaviors waiting on activated signals.
                    until @sig_active.empty? do
                        # Update the signals.
                        @sig_active.each { |sig| sig.c_value = sig.f_value }
                        # puts "sig_active.size=#{@sig_active.size}"
                        # Look for the behavior sensitive to the signals.
                        @sig_active.each do |sig|
                            sig.each_anyedge { |beh| @sig_exec << beh }
                            if (!sig.c_value.zero?) then
                                # puts "sig.c_value=#{sig.c_value.content}"
                                sig.each_posedge { |beh| @sig_exec << beh }
                            else
                                sig.each_negedge { |beh| @sig_exec << beh }
                            end
                        end
                        # puts "first @sig_exec.size=#{@sig_exec.size}"
                        @sig_exec.uniq! {|beh| beh.object_id }
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
                    end
                    break if @timed_behaviors.empty?
                    # Advance time.
                    @time = (@timed_behaviors.min {|b0,b1|  b0.time <=> b1.time }).time
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

        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # puts "init_sim for #{self} (#{self.name})"
            # Recurse on the signals.
            self.each_signal { |sig| sig.init_sim(systemT) }
            # Recure on the scope.
            self.scope.init_sim(systemT)
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

        ## Display the value of signal +sig+.
        def show_signal(sig)
            @simout.puts("#{sig.fullname}: #{sig.f_value.to_vstr}")
        end


        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= (self.parent ? self.parent.fullname + ":" : "") + 
                self.name.to_s
            return @fullname
        end
    end


    ## 
    # Describes scopes of system types.
    class Scope
        
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            # Recurse on the inner signals.
            self.each_inner { |sig| sig.init_sim(systemT) }
            # Recurse on the behaviors.
            self.each_behavior { |beh| beh.init_sim(systemT) }
            # Recurse on the systemI.
            self.each_systemI { |sys| sys.init_sim(systemT) }
            # Recurse on the connections.
            self.each_connection { |cnx| cnx.init_sim(systemT) }
            # Recurse on the sub scopes.
            self.each_scope { |sco| sco.init_sim(systemT) }
        end

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
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
                # Remove the inner signals from the list.
                self.block.each_inner do |inner|
                    refs.delete_if {|r| r.name == inner.name }
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
                        self.block.execute(:par)
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
            @posedge_behaviors ||= []
            @posedge_behaviors << beh
        end

        ## Adds behavior +beh+ activated on a negative edge of the signal.
        def add_negedge(beh)
            @negedge_behaviors ||= []
            @negedge_behaviors << beh
        end

        ## Adds behavior +beh+ activated on a any edge of the signal.
        def add_anyedge(beh)
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
            # puts "Executing signal=#{self.fullname}"
            return mode == :par ? self.c_value : self.f_value
        end

        ## Assigns +value+ the the reference.
        def assign(mode,value)
            # @f_value = value
            # puts "assign #{value.content} (#{value.content.class}) with self.type.width=#{self.type.width} while value.type.width=#{value.type.width}" if self.name.to_s.include?("idx")
            @f_value = value.cast(self.type)
        end

        ## Assigns +value+ at +index+ (integer or range).
        def assign_at(mode,value,index)
            # @f_value = @f_value.assign_at(mode,value,index)
            if (@f_value.equal?(@c_value)) then
                # Need to duplicate @f_value to avoid side effect.
                @f_value = Value.new(@f_value.type,@f_value.content.clone)
            end
            @f_value[index] = value
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
        end

        ## Executes the statement.
        def execute(mode)
            self.left.assign(mode,self.right.execute(mode))
        end
    end


    ## 
    # Describes an if statement.
    class If
        ## Initialize the simulation for system +systemT+.
        def init_sim(systemT)
            self.yes.init_sim(systemT)
            self.each_noif { |cond,stmnt| stmnt.init_sim(systemT) } 
            self.no.init_sim(systemT) if self.no
        end

        ## Executes the statement.
        def execute(mode)
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
            self.default.init_sim(systemT)
        end

        ## Executes the statement.
        def execute(mode)
            unless self.each_when.find do |wh|
                if wh.match.eql?(self.value.execute(mode)) then
                    wh.statement.execute(mode)
                    return
                end
            end
                self.default.execute(mode)
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
            # Nothing to do.
        end

        ## Executes the statement.
        def execute(mode)
            puts self.each_args.join
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
            # puts "Stopping #{@behavior.object_id} (@behavior.time=#{@behavior.time})..."
            @sim.run_done(@behavior.id)
            # puts "Rerunning #{@behavior.object_id} (@behavior.time=#{@behavior.time})..."
            @sim.run_req(@behavior.id)
        end
    end


    ## 
    # Describes a timed loop statement: not synthesizable!
    class TimeRepeat
        ## Deprecated
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
            self.each_statement { |stmnt| stmnt.execute(self.mode) }
        end

        ## Returns the name of the signal with its hierarchy.
        def fullname
            @fullname ||= self.parent.fullname + ":" + self.name.to_s
            return @fullname
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
            # Recurse on the left.
            self.left.init_sim(systemT)
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
            # puts "connection = #{self}"
            self.left.assign(mode,self.right.execute(mode))
        end
    end



    ## 
    # Describes an expression.
    #
    # NOTE: this is an abstract class which is not to be used directly.
    class Expression
        ## Executes the expression in +mode+ (:blocking or :nonblocking)
        #  NOTE: to be overrided.
        def execute(mode)
            raise "execute must be implemented in class #{self.class}"
        end
    end

    
    ##
    # Describes a value.
    class Value
        # include Vprocess

        ## Executes the expression.
        def execute(mode)
            return self
        end
    end


    ##
    # Describes a cast.
    class Cast
        ## Executes the expression.
        def execute(mode)
            # Recurse on the child.
            res = self.child.execute(mode)
            # # Set the type.
            # res.type = self.type
            # Cast it.
            res = res.cast(self.type)
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
        ## Execute the expression.
        def execute(mode)
            # Recurse on the select.
            tmps = self.select.execute(mode)
            # Recurse on the selection result.
            return @choices[tmps.to_i].execute(mode)
        end
    end


    ## 
    # Describes a concatenation expression.
    class Concat
        ## Execute the expression.
        def execute(mode)
            # Recurse on the children.
            tmpe = self.each_expression.map { |expr| expr.execute(mode) }
            # Ensure the order of the elements matches the type.
            tmpe.reverse! if self.type.direction == :big
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
            # Recurse on the children.
            pos = 0
            width = 0
            @refs.reverse_each do |ref|
                width = type.width
                # Get the refered value.
                refv = ref.execute(mode,value)
                # Assign to it.
                refv = refv.assign_at(mode,value[pos+width-1..pos])
                # Update the reference.
                ref.assign(mode,refv)
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
            @sim = systemT
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
