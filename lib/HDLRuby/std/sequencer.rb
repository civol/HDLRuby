require 'std/fsm'

module HDLRuby::High::Std

    ##
    # Standard HDLRuby::High library: sequencer generator.
    # The idea is to be able to write sw-like sequential code.
    # 
    ########################################################################
    


    # Describes a sequencer block.
    class SequencerT 
        @@current = nil # The current sequencer.

        # Get the sequencer currently processing.
        def self.current
            @@current
        end

        # The start and end states values.
        attr_reader :start_state_value, :end_state_value

        # Create a new sequencer block synchronized on +ev+ and starting
        # on +start+
        def initialize(ev,start,&ruby_block)
            this = self
            # Process the arguments.
            ev = ev.posedge unless ev.is_a?(Event)
            if start.is_a?(Event) then
                start = start.type == :posedge ? start.ref : ~start.ref
            end
            # Create the fsm from the block.
            @fsm = fsm(ev,start,:seq)
            # On reset (start) tell to go to the first state.
            run = HDLRuby::High.cur_system.inner(HDLRuby.uniq_name(:run) => 0)
            @fsm.reset do
                # HDLRuby::High.top_user.instance_exec do
                #     next_state_sig <= this.start_state_value
                # end
                run <= 1
            end

            # The status stack of the sequencer.
            @status = [ {} ]
            # Creates the namespace to execute the sequencer deescription 
            # block in.
            @namespace = Namespace.new(self)

            # The end state is actually 0, allows to sequencer to be stable
            # by default.
            @fsm.default { run <= 0 }
            @end_state = @fsm.state { }
            @end_state.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(run) { next_state_sig <= this.start_state_value }
                    helse { next_state_sig <= this.end_state_value }
                end
            end
            # Record the start and end state values.
            # For now, the start state is the one just following the end state.
            @end_state_value = @end_state.value
            @start_state_value = @end_state_value + 1
            # puts "end_state_value=#{@end_state_value}"

            # Process the ruby_block.
            @@current = self
            HDLRuby::High.space_push(@namespace)
            blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            HDLRuby::High.space_pop

            # If the block is not empty, add it as last state.
            this = self
            if blk.each_statement.any? then
                st = @fsm.state do
                    this.fill_top_user(blk)
                end
            end

            # Build the fsm.
            @fsm.build
        end

        # Gets the number of states of the underlining fsm.
        def size
            return @fsm.size
        end

        # Gets the closest loop status in the status stack.
        # NOTE: raises an exception if there are not swhile state.
        def loop_status
            i = @status.size-1
            begin
               status = @status[i -= 1]
               raise "No loop for sbreak." unless status
            end while(!status[:loop])
            return status
        end



        # Mark a step.
        def step
            # Create a new block from all the statements in the previous block.
            blk = HDLRuby::High::Block.new(:seq) {}
            # Get all the statements of the builder block.
            stmnts = HDLRuby::High.cur_block.instance_variable_get(:@statements)
            # Add all the statements to blk.
            stmnts.each { |stmnt| stmnt.parent = nil; blk.add_statement(stmnt) }
            # Remove them from the builder block.
            stmnts.clear

            # Create a state for this block.
            this = self
            st = @fsm.state { this.fill_top_user(blk) }
            # # Set the previous step in sequence.
            # @status.last[:state] = st
            return st
        end

        # Mark several steps.
        def steps(num)
            # Create a counter. 
            count = nil
            zero = nil
            one = nil
            HDLRuby::High.cur_system.open do
                if num.respond_to?(:width) then
                    count = [num.width].inner(HDLRuby.uniq_name(:"steps_count"))
                else
                    count = num.to_expr.type.inner(HDLRuby.uniq_name(:"steps_count"))
                end
                zero = _b0
                one  = _b1
            end
            count <= num
            swhile(count > zero) { count <= count - one }
        end

        # Breaks current iteration.
        def sbreak
            # Mark a step.
            st = self.step
            # Tell there is a break to process.
            # Do that in the first loop status met.
            status = self.loop_status
            status[:sbreaks] ||= []
            status[:sbreaks] << st
            return st
        end

        # Continues current iteration.
        def scontinue
            # Mark a step.
            st = self.step
            # Go to the begining of the iteration, i.e., the first loop
            # status met.
            status = self.loop_status
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= status[:loop]
                end
            end
            return st
        end

        # Terminates the sequencer.
        def sterminate
            # Mark a step.
            st = self.step
            # Adds a goto the ending state.
            this = self
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= this.end_state_value
                end
            end
            return st
        end

        # Create a sequential if statement on +cond+.
        def sif(cond, &ruby_block)
            # Mark a step.
            st = self.step
            # Remember the condition.
            @status.last[:condition] = cond
            # Create a state to be executed if the condition is met.
            @status.push({})
            yes_name = HDLRuby.uniq_name("yes")
            yes_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop
            this = self
            yes = @fsm.state(yes_name) { this.fill_top_user(yes_blk) }
            # Add a goto to the previous state.
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    hif(cond) { next_state_sig <= st.value + 1 }
                    helse { next_state_sig <= yes.value + 1 }
                end
            end
            # Remeber the if yes state for being able to add else afterward.
            @status.last[:sif_yes] = yes
            return st
        end

        # Create a sequential else statement.
        def selse(&ruby_block)
            # Create a state to be executed if the previous condition is
            # not met.
            @status.push({})
            no_name = HDLRuby.uniq_name("no")
            no_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop
            this = self
            no = @fsm.state(no_name) { this.fill_top_user(no_blk) }
            # Adds a goto to the previous if yes state for jumping the no state.
            yes = @status.last[:sif_yes]
            raise "Cannot use selse here." unless yes
            cond = @status.last[:condition]
            yes.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    next_state_sig <= no.value + 1
                end
            end
            return no
        end

        # Wait a given condition.
        def swait(cond)
            return self.swhile(~cond)
        end

        # Create a sequential while statement on +cond+.
        def swhile(cond,&ruby_block)
            # Ensures there is a ruby block. This allows to use empty while
            # statement.
            ruby_block = proc { } unless ruby_block
            # Mark a step.
            st = self.step

            # Tell we are building a while and remember the state number.
            @status.last[:loop] = st.value + 1

            # Create a state to be executed if the condition is met.
            @status.push({})
            # Build the loop sub sequence.
            yes_name = HDLRuby.uniq_name("yes")
            yes_blk = HDLRuby::High::Block.new(:seq,&ruby_block)
            @status.pop

            this = self
            yes = @fsm.state(yes_name) { this.fill_top_user(yes_blk) }
            # Add a goto to the previous state.
            st.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    if cond then
                        # There is a condition, it is a real while loop.
                        hif(cond) { next_state_sig <= st.value + 1 }
                        helse { next_state_sig <= yes.value + 1 }
                        # puts("Here st: st.value+1=#{st.value+1} yes.value+1=#{yes.value+1}\n")
                    else
                        # There is no ending condition, this is an infinite loop.
                        next_state_sig <= st.value + 1
                        # puts("There st: st.value+1=#{st.value+1}\n")
                    end
                end
            end
            # And to the yes state.
            yes.gotos << proc do
                HDLRuby::High.top_user.instance_exec do
                    if cond then
                        # There is a condition, it is a real while loop
                        hif(cond) { next_state_sig <= st.value + 1 }
                        helse { next_state_sig <= yes.value + 1 }
                        # puts("Here yes: st.value+1=#{st.value+1} yes.value+1=#{yes.value+1}\n")
                    else
                        # There is no ending condition, this is an infinite loop.
                        next_state_sig <= st.value + 1
                        # puts("There yes: st.value+1=#{st.value+1}\n")
                    end
                end
            end
            # puts "st_value=#{st.value} yes_value=#{yes.value}"

            # Where there any break?
            if @status.last[:sbreaks] then
                # Yes, adds them the right goto since the end of loop state
                # is now defined.
                @status.last[:sbreaks].each do |st_brk|
                    st_brk.gotos << proc do
                        HDLRuby::High.top_user.instance_exec do
                            next_state_sig <= yes.value + 1
                        end
                    end
                end
                # And remove them from the status to avoid reprocessing them,
                @status.last.clear
            end

            return st
        end

        # Create a sequential infinite loop statement.
        def sloop(&ruby_block)
            self.swhile(nil,&ruby_block)
        end

        # Create a sequential for statement iterating over the elements
        # of +expr+.
        def sfor(expr,&ruby_block)
            # Ensures there is a ruby block to avoid returning an enumerator
            # (returning an enumerator would be confusing for a for statement).
            ruby_block = proc {} unless ruby_block
            expr.seach.with_index(&ruby_block)
        end

        # Tell if the sequencer ends it execution.
        def alive?
          return @fsm.cur_state_sig != self.end_state_value
        end


        # Fills the top user with the content of block +blk+.
        def fill_top_user(blk)
            # Fill the current block with blk content.
            blk.each_statement do |stmnt|
                stmnt.parent = nil
                HDLRuby::High.top_user.add_statement(stmnt)
            end
        end
    end


    ## Remplement make_inners of block to support declaration within sequencers.


    class HDLRuby::High::Block
        # Save module method (unbounded) for further call since going to
        # override make_inners.
        # alias_method does not seem to work in such a context, so use
        # this approach.
        @@old_make_inners_proc = self.instance_method(:make_inners)

        def make_inners(typ,*names)
            res = nil
            if SequencerT.current then
                unames = names.map {|name| HDLRuby.uniq_name(name) }
                res = HDLRuby::High.cur_scope.make_inners(typ, *unames)
                names.zip(unames).each do |name,uname|
                    HDLRuby::High.space_reg(name) { send(uname) }
                end
            else
                # self.old_make_inners(typ,*names)
                # Call the old make_inners.
                res = @@old_make_inners_proc.bind(self).call(typ,*names)
            end
            return res
        end
    end




    # Module adding functionalities to object including the +seach+ method.
    module SEnumerable

        # Iterator on each of the elements in range +rng+.
        # *NOTE*: 
        #   - Stop iteration when the end of the range is reached or when there
        #     are no elements left
        #   - This is not a method from Ruby but one specific for hardware where
        #     creating a array is very expensive.
        def seach_range(rng,&ruby_block)
            return self.seach.seach_range(rng,&ruby_block)
        end

        # Tell if all the elements respect a given criterion given either
        # as +arg+ or as block.
        def sall?(arg = nil,&ruby_block)
            # Declare the result signal.
            res = nil
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"all_cond"))
            end
            # Initialize the result.
            res <= 1
            # Performs the computation.
            if arg then
                # Compare elements to arg.
                self.seach do |elem|
                    res <= res & (elem == arg)
                end
            elsif ruby_block then
                # Use the ruby block.
                self.seach do |elem|
                    res <= res & ruby_block.call(elem)
                end
            else
                raise "Ruby nil does not have any meaning in HW."
            end
            res
        end

        # Tell if any of the elements respects a given criterion given either
        # as +arg+ or as block.
        def sany?(arg = nil,&ruby_block)
            # Declare the result signal.
            res = nil
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"any_cond"))
            end
            # Initialize the result.
            res <= 0
            # Performs the computation.
            if arg then
                # Compare elements to arg.
                self.seach do |elem|
                    res <= res | (elem == arg)
                end
            elsif ruby_block then
                # Use the ruby block.
                self.seach do |elem|
                    res <= res | ruby_block.call(elem)
                end
            else
                raise "Ruby nil does not have any meaning in HW."
            end
            res
        end

        # Returns an SEnumerator generated from current enumerable and +arg+
        def schain(arg)
            return self.seach + arg
        end

        # HW implementation of the Ruby chunk.
        # NOTE: to do, or may be not.
        def schunk(*args,&ruby_block)
            raise "schunk is not supported yet."
        end

        # HW implementation of the Ruby chunk_while.
        # NOTE: to do, or may be not.
        def schunk_while(*args,&ruby_block)
            raise "schunk_while is not supported yet."
        end

        # Returns a vector containing the execution result of the given block 
        # on each element. If no block is given, return an SEnumerator.
        # NOTE: be carful that the resulting vector can become huge if there
        # are many element.
        def smap(&ruby_block)
            # No block given? Generate a new wrapper enumerator for smap.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:smap)
            end
            # A block given? Fill the vector it with the computation result.
            # Generate the vector to put the result in.
            # The declares the resulting vector.
            res = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"map_vec"))
            end
            # And do the iteration.
            enum.with_index do |elem,idx|
                res[idx] <= ruby_block.call(elem)
            end
            # Return the resulting vector.
            return res
        end

        # HW implementation of the Ruby flat_map.
        # NOTE: actually due to the way HDLRuby handles vectors, should work
        #       like smap
        def sflat_map(&ruby_block)
            return smap(&ruby_block)
        end

        # HW implementation of the Ruby compact, but remove 0 values instead
        # on nil (since nil that does not have any meaning in HW).
        def scompact
            # Generate the vector to put the result in.
            # The declares the resulting vector and index.
            res = nil
            idx = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"compact_vec"))
                idx = [enum.size.width].inner(HDLRuby.uniq_name(:"compact_idx"))
            end
            # And do the iteration.
            idx <= 0
            enum.seach do |elem|
                HDLRuby::High.top_user.hif(elem != 0) do
                    res[idx] <= elem
                    idx <= idx + 1
                end
            end
            SequencerT.current.swhile(idx < enum.size) do
                res[idx] <= 0
                idx <= idx + 1
            end
            # Return the resulting vector.
            return res
        end


        # WH implementation of the Ruby count.
        def scount(obj = nil, &ruby_block)
            # Generate the counter result signal.
            cnt = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                cnt = [enum.size.width].inner(HDLRuby.uniq_name(:"count_idx"))
            end
            # Do the counting.
            cnt <= 0
            # Is obj present?
            if obj then
                # Yes, count the occurences of obj.
                enum.seach do |elem|
                    HDLRuby::High.top_user.hif(obj == elem) { cnt <= cnt + 1 }
                end
            elsif ruby_block
                # No, but there is a ruby block, use its result for counting.
                enum.seach do |elem|
                    HDLRuby::High.top_user.hif(ruby_block.call(elem)) do
                        cnt <= cnt + 1
                    end
                end
            else
                # No, the result is simply the number of elements.
                cnt <= enum.size
            end
            return cnt
        end

        # HW implementation of the Ruby cycle.
        def scycle(n = nil,&ruby_block)
            # No block given? Generate a new wrapper enumerator for scycle.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:scycle,n)
            end
            this = self
            # Is n nil?
            if n == nil then
                # Yes, infinite loop.
                SequencerT.current.sloop do
                    this.seach(&ruby_block)
                end
            else
                # Finite loop.
                (0..(n-1)).seach do
                    this.seach(&ruby_block)
                end
            end
        end

        # HW implementation of the Ruby find.
        # NOTE: contrary to Ruby, if_none_proc is mandatory since there is no
        #       nil in HW. Moreover, the argument can also be a value.
        def sfind(if_none_proc, &ruby_block)
            # No block given? Generate a new wrapper enumerator for sfind.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:sfind,if_none_proc)
            end
            # Generate the found result signal and flag signals.
            found = nil
            flag = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                found = enum.type.inner(HDLRuby.uniq_name(:"find_found"))
                flag = bit.inner(HDLRuby.uniq_name(:"find_flag"))
            end
            # Look for the element.
            flag <= 0
            enum.srewind
            SequencerT.current.swhile((flag == 0) & (enum.snext?)) do
                found <= enum.snext
                hif(ruby_block.call(found)) do
                    # Found, save the element and raise the flag.
                    flag <= 1
                end
            end
            HDLRuby::High.top_user.hif(~flag) do
                # Not found, execute the none block.
                if if_none_proc.respond_to?(:call) then
                    found <= f_none_proc.call
                else
                    found <= if_none_proc
                end
            end
            found
        end

        # HW implementation of the Ruby drop.
        def sdrop(n)
            # Generate the vector to put the result in.
            # The declares the resulting vector and index.
            res = nil
            idx = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                # res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"drop_vec"))
                res = enum.type[-enum.size+n].inner(HDLRuby.uniq_name(:"drop_vec"))
                # idx = [enum.size.width].inner(HDLRuby.uniq_name(:"drop_idx"))
            end
            # And do the iteration.
            # idx <= 0
            # enum.seach.with_index do |elem,i|
            #     HDLRuby::High.top_user.hif(i >= n) do
            #         res[idx] <= elem
            #         idx <= idx + 1
            #     end
            # end
            # SequencerT.current.swhile(idx < enum.size) do
            #     res[idx] <= 0
            #     idx <= idx + 1
            # end
            (enum.size-n).stimes do |i|
                res[i] <= enum.access(i+n)
            end
            # Return the resulting vector.
            return res
        end

        # HW implementation of the Ruby drop_while.
        def sdrop_while(&ruby_block)
            # No block given? Generate a new wrapper enumerator for sdrop_while.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:sdrop_while)
            end
            # A block is given.
            # Generate the vector to put the result in.
            # The declares the resulting vector, index and drop flag.
            res = nil
            idx = nil
            flg = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"drop_vec"))
                idx = [enum.size.width].inner(HDLRuby.uniq_name(:"drop_idx"))
                flg = bit.inner(HDLRuby.uniq_name(:"drop_flg"))
            end
            # And do the iteration.
            # First drop and fill from current enumerable elements.
            idx <= 0
            flg <= 1
            enum.seach.with_index do |elem,i|
                HDLRuby::High.top_user.hif(flg == 1) do
                    HDLRuby::High.top_user.hif(ruby_block.call(elem) == 0) do
                        flg <= 0
                    end
                end
                HDLRuby::High.top_user.hif(flg == 0) do
                    res[idx] <= elem
                    idx <= idx + 1
                end
            end
            # Finally, end with zeros.
            SequencerT.current.swhile(idx < enum.size) do
                res[idx] <= 0
                idx <= idx + 1
            end
            # Return the resulting vector.
            return res
        end
       
        # HW implementation of the Ruby each_cons
        def seach_cons(n,&ruby_block)
            # No block given? Generate a new wrapper enumerator for seach_cons.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:seach_cons)
            end
            # A block is given.
            # Declares the indexes and the buffer for cosecutive elements.
            enum = self.seach
            idx  = nil
            buf  = nil
            HDLRuby::High.cur_system.open do
                idx = [enum.size.width].inner(HDLRuby.uniq_name(:"each_cons_idx"))
                buf = n.times.map do |i|
                    [enum.type].inner(HDLRuby.uniq_name(:"each_cons_buf#{i}"))
                end
            end
            # And do the iteration.
            this = self
            # Initialize the buffer.
            n.times do |i|
                buf[i] <= enum.access(i)
                SequencerT.current.step
            end
            # Do the first iteration.
            ruby_block.call(*buf)
            # Do the remaining iteration.
            idx <= n
            SequencerT.current.swhile(idx < enum.size) do
                # Shifts the buffer (in parallel)
                buf.each_cons(2) { |a0,a1| a0 <= a1 }
                # Adds the new element.
                buf[-1] <= enum.access(idx)
                idx <= idx + 1
                # Executes the block.
                ruby_block.call(*buf)
            end
        end

        # HW implementation of the Ruby each_entry.
        # NOTE: to do, or may be not.
        def seach_entry(*args,&ruby_block)
            raise "seach_entry is not supported yet."
        end

        # HW implementation of the Ruby each_slice
        def seach_slice(n,&ruby_block)
            # No block given? Generate a new wrapper enumerator for seach_slice.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:seach_slice)
            end
            # A block is given.
            # Declares the indexes and the buffer for consecutive elements.
            enum = self.seach
            idx  = nil
            buf  = nil
            HDLRuby::High.cur_system.open do
                idx = [(enum.size+n).width].inner(HDLRuby.uniq_name(:"each_slice_idx"))
                buf = n.times.map do |i|
                    [enum.type].inner(HDLRuby.uniq_name(:"each_slice_buf#{i}"))
                end
            end
            # And do the iteration.
            this = self
            # Adjust n if too large.
            n = enum.size if n > enum.size
            # Initialize the buffer.
            n.times do |i|
                buf[i] <= enum.access(i)
                SequencerT.current.step
            end
            # Do the first iteration.
            ruby_block.call(*buf)
            # Do the remaining iteration.
            idx <= n
            SequencerT.current.swhile(idx < enum.size) do
                # Gets the new element.
                n.times do |i|
                    sif(idx+i < enum.size) do
                        buf[i] <= enum.access(idx+i)
                    end
                    selse do
                        buf[i] <= 0
                    end
                end
                idx <= idx + n
                # Executes the block.
                ruby_block.call(*buf)
            end
        end

        # HW implementation of the Ruby each_with_index.
        def seach_with_index(*args,&ruby_block)
            self.seach.with_index(*args,&ruby_block)
        end

        # HW implementation of the Ruby each_with_object.
        def seach_with_object(obj,&ruby_block)
            self.seach.with_object(obj,&ruby_block)
        end

        # HW implementation of the Ruby to_a.
        def sto_a
            # Declares the resulting vector.
            enum = self.seach
            res  = nil
            # size = enum.size.to_value
            HDLRuby::High.cur_system.open do
                # res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"to_a_res"))
                res = enum.type[-enum.size.to_i].inner(HDLRuby.uniq_name(:"to_a_res"))
            end
            # Fills it.
            self.seach_with_index do |elem,i|
                res[i] <= elem
            end
            return res
        end

        # HW implementation of the Ruby select.
        def sselect(&ruby_block)
            # No block given? Generate a new wrapper enumerator for sselect.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:sselect)
            end
            # A block is given.
            # Generate the vector to put the result in.
            # The declares the resulting vector and index.
            res = nil
            idx = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"select_vec"))
                idx = [enum.size.width].inner(HDLRuby.uniq_name(:"select_idx"))
            end
            # And do the iteration.
            # First select and fill from current enumerable elements.
            idx <= 0
            enum.seach do |elem|
                HDLRuby::High.top_user.hif(ruby_block.call(elem) == 1) do
                    res[idx] <= elem
                    idx <= idx + 1
                end
            end
            # Finally, end with zeros.
            SequencerT.current.swhile(idx < enum.size) do
                res[idx] <= 0
                idx <= idx + 1
            end
            # Return the resulting vector.
            return res
        end

        # HW implementation of the Ruby find_index.
        def sfind_index(obj = nil, &ruby_block)
            # No block given nor obj? Generate a new wrapper enumerator for
            # sfind.
            if !ruby_block && !obj then
                return SEnumeratorWrapper.new(self,:sfind,if_none_proc)
            end
            # Generate the index result signal and flag signals.
            idx  = nil
            flag = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                idx = signed[enum.size.width+1].inner(HDLRuby.uniq_name(:"find_idx"))
                flag = bit.inner(HDLRuby.uniq_name(:"find_flag"))
            end
            # Look for the element.
            flag <= 0
            idx <= 0
            enum.srewind
            SequencerT.current.swhile((flag == 0) & (enum.snext?)) do
                if (obj) then
                    # There is obj case.
                    HDLRuby::High.top_user.hif(enum.snext == obj) do
                        # Found, save the element and raise the flag.
                        flag <= 1
                    end
                else
                    # There is a block case.
                    HDLRuby::High.top_user.hif(ruby_block.call(enum.snext)) do
                        # Found, save the element and raise the flag.
                        flag <= 1
                    end
                end
                HDLRuby::High.top_user.helse do
                    idx <= idx + 1
                end
            end
            HDLRuby::High.top_user.hif(flag ==0) { idx <= -1 }
            return idx
        end

        # HW implementation of the Ruby first.
        def sfirst(n=1)
            # Generate the vector to put the result in.
            # The declares the resulting vector and index.
            res = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-n].inner(HDLRuby.uniq_name(:"first_vec"))
            end
            # And do the iteration.
            n.stimes do |i|
                res[i] <= enum.access(i)
            end
            # Return the resulting vector.
            return res
        end

        # HW implementation of the Ruby grep.
        # NOTE: to do, or may be not.
        def sgrep(*args,&ruby_block)
            raise "sgrep is not supported yet."
        end

        # HW implementation of the Ruby grep_v.
        # NOTE: to do, or may be not.
        def sgrep_v(*args,&ruby_block)
            raise "sgrep_v is not supported yet."
        end

        # HW implementation of the Ruby group_by.
        # NOTE: to do, or may be not.
        def sgroup_by(*args,&ruby_block)
            raise "sgroup_by is not supported yet."
        end

        # HW implementation of the Ruby include?
        def sinclude?(obj)
            # Generate the result signal.
            res  = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"include_res"))
            end
            # Look for the element.
            res <= 0
            enum.srewind
            SequencerT.current.swhile((res == 0) & (enum.snext?)) do
                # There is obj case.
                HDLRuby::High.top_user.hif(enum.snext == obj) do
                    # Found, save the element and raise the flag.
                    res <= 1
                end
            end
            return res
        end

        # HW implementation of the Ruby inject.
        def sinject(*args,&ruby_block)
            init = nil
            symbol = nil
            # Process the arguments.
            if args.size > 2 then
                raise ArgumentError.new("wrong number of arguments (given #{args.size} expected 0..2)")
            elsif args.size == 2 then
                # Initial value and symbol given case.
                init, symbol = args
            elsif args.size == 1 && ruby_block then
                # Initial value and block given case.
                init = args[0]
            elsif args.size == 1 then
                # Symbol given case.
                symbol = args[0]
            end
            enum = self.seach
            # Define the computation type: from the initial value if any,
            # otherwise from the enum.
            typ = init ? init.to_expr.type : enum.type
            # Generate the result signal.
            res  = nil
            HDLRuby::High.cur_system.open do
                res = typ.inner(HDLRuby.uniq_name(:"inject_res"))
            end
            # Start the initialization
            enum.srewind
            # Is there an initial value?
            if (init) then
                # Yes, start with it.
                res <= init
            else
                # No, start with the first element of the enumerator.
                res <= 0
                SequencerT.current.sif(!enum.snext?) { res <= enum.snext }
            end
            SequencerT.current.swhile(enum.snext?) do
                # Do the accumulation.
                if (symbol) then
                    res <= res.send(symbol,enum.snext)
                else
                    res <= ruby_block.call(res,enum.snext)
                end
            end
            return res
        end

        alias_method :sreduce, :sinject

        # HW implementation of the Ruby lazy.
        # NOTE: to do, or may be not.
        def slazy(*args,&ruby_block)
            raise "slazy is not supported yet."
        end

        # HW implementation of the Ruby max.
        def smax(n = nil, &ruby_block)
            # Process the arguments.
            n = 1 unless n
            enum = self.seach
            # Declare the result signal the flag and the result array size index
            # used for implementing the algorithm (shift-based sorting) in
            # case of multiple max.
            res  = nil
            flg = nil
            idx = nil
            HDLRuby::High.cur_system.open do
                if n == 1 then
                    res = enum.type.inner(HDLRuby.uniq_name(:"max_res"))
                    # No flg nor idx!
                else
                    res = enum.type[-n].inner(HDLRuby.uniq_name(:"max_res"))
                    flg = bit.inner(HDLRuby.uniq_name(:"max_flg"))
                    idx = bit[n.width].inner(HDLRuby.uniq_name(:"max_idx"))
                end
            end
            enum.srewind
            if n == 1 then
                # Single max case, initialize res with the first element(s)
                res <= enum.type.min
                SequencerT.current.sif(enum.snext?) { res <= enum.snext }
            else
                # Multiple max case, initialize the resulting array size index.
                idx <= 0
            end
            # Do the iteration.
            SequencerT.current.swhile(enum.snext?) do
                if n == 1 then
                    # Single max case.
                    elem = enum.snext
                    if ruby_block then
                        hif(ruby_block.call(res,elem) < 0) { res <= elem }
                    else
                        hif(res < elem) { res <= elem }
                    end
                else
                    # Multiple max case.
                    SequencerT.current.sif(enum.snext?) do
                        elem = enum.snext
                        flg <= 1
                        n.times do |i|
                            # Compute the comparison between the result element
                            # at i and the enum element.
                            if ruby_block then
                                cond = ruby_block.call(res[i],elem) < 0
                            else
                                cond = res[i] < elem
                            end
                            # If flg is 0, elem is already set as max, skip.
                            # If the result array size index is equal to i, then
                            # put the element whatever the comparison is since
                            # the place is still empty.
                            hif(flg & (cond | (idx == i))) do
                                # A new max is found, shift res from i.
                                ((i+1)..(n-1)).reverse_each { |j| res[j] <= res[j-1] }
                                # An set the new max in current position.
                                res[i] <= elem
                                # For now skip.
                                flg <= 0
                            end
                        end
                        # Note: when idx >= n, the resulting array is full
                        hif(idx < n) { idx <= idx + 1 }
                    end
                end
            end
            return res
        end

        # HW implementation of the Ruby max_by.
        def smax_by(n = nil, &ruby_block)
            # No block given? Generate a new wrapper enumerator for smax_by.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:smax_by,n)
            end
            # A block is given, use smax with a proc that applies ruby_block
            # before comparing.
            return smax(n) { |a,b| ruby_block.call(a) <=> ruby_block.call(b) }
        end

        # HW implementation of the Ruby min.
        def smin(n = nil, &ruby_block)
            # Process the arguments.
            n = 1 unless n
            enum = self.seach
            # Declare the result signal the flag and the result array size index
            # used for implementing the algorithm (shift-based sorting) in
            # case of multiple min.
            res  = nil
            flg = nil
            idx = nil
            HDLRuby::High.cur_system.open do
                if n == 1 then
                    res = enum.type.inner(HDLRuby.uniq_name(:"min_res"))
                    # No flg nor idx!
                else
                    res = enum.type[-n].inner(HDLRuby.uniq_name(:"min_res"))
                    flg = bit.inner(HDLRuby.uniq_name(:"min_flg"))
                    idx = bit[n.width].inner(HDLRuby.uniq_name(:"min_idx"))
                end
            end
            enum.srewind
            if n == 1 then
                # Single min case, initialize res with the first element(s)
                res <= enum.type.max
                SequencerT.current.sif(enum.snext?) { res <= enum.snext }
            else
                # Multiple min case, initialize the resulting array size index.
                idx <= 0
            end
            # Do the iteration.
            SequencerT.current.swhile(enum.snext?) do
                if n == 1 then
                    # Single min case.
                    elem = enum.snext
                    if ruby_block then
                        hif(ruby_block.call(res,elem) > 0) { res <= elem }
                    else
                        hif(res > elem) { res <= elem }
                    end
                else
                    # Multiple min case.
                    SequencerT.current.sif(enum.snext?) do
                        elem = enum.snext
                        flg <= 1
                        n.times do |i|
                            # Compute the comparison between the result element
                            # at i and the enum element.
                            if ruby_block then
                                cond = ruby_block.call(res[i],elem) > 0
                            else
                                cond = res[i] > elem
                            end
                            # If flg is 0, elem is already set as min, skip.
                            # If the result array size index is equal to i, then
                            # put the element whatever the comparison is since
                            # the place is still empty.
                            hif(flg & (cond | (idx == i))) do
                                # A new min is found, shift res from i.
                                ((i+1)..(n-1)).reverse_each { |j| res[j] <= res[j-1] }
                                # An set the new min in current position.
                                res[i] <= elem
                                # For now skip.
                                flg <= 0
                            end
                        end
                        # Note: when idx >= n, the resulting array is full
                        hif(idx < n) { idx <= idx + 1 }
                    end
                end
            end
            return res
        end

        # HW implementation of the Ruby min_by.
        def smin_by(n = nil, &ruby_block)
            # No block given? Generate a new wrapper enumerator for smin_by.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:smin_by,n)
            end
            # A block is given, use smin with a proc that applies ruby_block
            # before comparing.
            return smin(n) { |a,b| ruby_block.call(a) <=> ruby_block.call(b) }
        end

        # HW implementation of the Ruby minmax.
        def sminmax(&ruby_block)
            # Generate the result signal.
            res  = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[2].inner(HDLRuby.uniq_name(:"minmax_res"))
            end
            # Computes the min.
            res[0] <= enum.smin(&ruby_block)
            # Computes the max.
            res[1] <= enum.smax(&ruby_block)
            # Return the result.
            return res
        end

        # HW implementation of the Ruby minmax_by.
        def sminmax_by(&ruby_block)
            # Generate the result signal.
            res  = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[2].inner(HDLRuby.uniq_name(:"minmax_res"))
            end
            # Computes the min.
            res[0] <= enum.smin_by(&ruby_block)
            # Computes the max.
            res[1] <= enum.smax_by(&ruby_block)
            # Return the result.
            return res
        end

        # Tell if none of the elements respects a given criterion given either
        # as +arg+ or as block.
        def snone?(arg = nil,&ruby_block)
            # Declare the result signal.
            res = nil
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"none_cond"))
            end
            # Initialize the result.
            res <= 1
            # Performs the computation.
            if arg then
                # Compare elements to arg.
                self.seach do |elem|
                    res <= res & (elem != arg)
                end
            elsif ruby_block then
                # Use the ruby block.
                self.seach do |elem|
                    res <= res & ~ruby_block.call(elem)
                end
            else
                raise "Ruby nil does not have any meaning in HW."
            end
            res
        end

        # Tell if one and only one of the elements respects a given criterion
        # given either as +arg+ or as block.
        def sone?(arg = nil,&ruby_block)
            # Declare the result signal.
            res = nil
            HDLRuby::High.cur_system.open do
                res = bit.inner(HDLRuby.uniq_name(:"one_cond"))
            end
            # Initialize the result.
            res <= 0
            # Performs the computation.
            if arg then
                # Compare elements to arg.
                self.seach do |elem|
                    res <= res ^ (elem == arg)
                end
            elsif ruby_block then
                # Use the ruby block.
                self.seach do |elem|
                    res <= res ^ ruby_block.call(elem)
                end
            else
                raise "Ruby nil does not have any meaning in HW."
            end
            res
        end

        # HW implementation of the Ruby partition.
        # NOTE: to do, or may be not.
        def spartition(*args,&ruby_block)
            raise "spartition is not supported yet."
        end

        # HW implementatiob of the Ruby reject.
        def sreject(&ruby_block)
            return sselect {|elem| ~ruby_block.call(elem) }
        end

        # HW implementatiob of the Ruby reverse_each.
        def sreverse_each(*args,&ruby_block)
            # No block given? Generate a new wrapper enumerator for 
            # sreverse_each.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:sreverse_each,*args)
            end
            # A block is given.
            # Declares the index.
            enum = self.seach
            idx = nil
            HDLRuby::High.cur_system.open do
                idx = bit[enum.size.width].inner(HDLRuby.uniq_name(:"reverse_idx"))
            end
            # Do the iteration.
            idx <= enum.size
            SequencerT.current.swhile(idx > 0) do
                idx <= idx - 1
                ruby_block.call(*args,enum.access(idx))
            end
        end

        # HW implementation of the Ruby slice_after.
        # NOTE: to do, or may be not.
        def sslice_after(pattern = nil,&ruby_block)
            raise "sslice_after is not supported yet."
        end

        # HW implementation of the Ruby slice_before.
        # NOTE: to do, or may be not.
        def sslice_before(*args,&ruby_block)
            raise "sslice_before is not supported yet."
        end

        # HW implementation of the Ruby slice_when.
        # NOTE: to do, or may be not.
        def sslice_when(*args,&ruby_block)
            raise "sslice_before is not supported yet."
        end

        # # HW implementation of the Ruby sort.
        # def ssort(&ruby_block)
        #     enum = self.seach
        #     n = enum.size
        #     # Declare the result signal the flag and the result array size index
        #     # used for implementing the algorithm (shift-based sorting).
        #     res = nil
        #     flg = nil
        #     idx = nil
        #     HDLRuby::High.cur_system.open do
        #         res = enum.type[-n].inner(HDLRuby.uniq_name(:"sort_res"))
        #         flg = bit.inner(HDLRuby.uniq_name(:"sort_flg"))
        #         idx = bit[n.width].inner(HDLRuby.uniq_name(:"sort_idx"))
        #     end
        #     # Performs the sort using a shift-based algorithm (also used in 
        #     # smin).
        #     enum.srewind
        #     # Do the iteration.
        #     idx <= 0
        #     SequencerT.current.swhile(enum.snext?) do
        #         # Multiple min case.
        #         SequencerT.current.sif(enum.snext?) do
        #             elem = enum.snext
        #             flg <= 1
        #             n.times do |i|
        #                 # Compute the comparison between the result element at i
        #                 # and the enum element.
        #                 if ruby_block then
        #                     cond = ruby_block.call(res[i],elem) > 0
        #                 else
        #                     cond = res[i] > elem
        #                 end
        #                 # If flg is 0, elem is already set as min, skip.
        #                 # If the result array size index is equal to i, then
        #                 # put the element whatever the comparison is since the
        #                 # place is still empty.
        #                 hif(flg & (cond | (idx == i))) do
        #                     # A new min is found, shift res from i.
        #                     ((i+1)..(n-1)).reverse_each { |j| res[j] <= res[j-1] }
        #                     # An set the new min in current position.
        #                     res[i] <= elem
        #                     # For now skip.
        #                     flg <= 0
        #                 end
        #             end
        #             idx <= idx + 1
        #         end
        #     end
        #     return res
        # end
        
        # Merge two arrays in order, for ssort only.
        def ssort_merge(arI, arO, first, middle, last, &ruby_block)
            # puts "first=#{first} middle=#{middle} last=#{last}"
            # Declare and initialize the indexes and
            # the ending flag.
            idF = nil; idM = nil; idO = nil
            flg = nil
            HDLRuby::High.cur_system.open do
                typ = [(last+1).width]
                idF = typ.inner(HDLRuby.uniq_name(:"sort_idF"))
                idM = typ.inner(HDLRuby.uniq_name(:"sort_idM"))
                idO = typ.inner(HDLRuby.uniq_name(:"sort_idO"))
                flg = inner(HDLRuby.uniq_name(:"sort_flg"))
            end
            idF <= first; idM <= middle; idO <= first
            flg <= 0
            SequencerT.current.swhile((flg == 0) & (idO < middle*2)) do
                if ruby_block then
                    cond = ruby_block.call(arI[idF],arI[idM]) < 0
                else
                    cond = arI[idF] < arI[idM]
                end
                hif((idF >= middle) & (idM > last)) { flg <= 1 }
                helsif (idF >= middle) do
                    arO[idO] <= arI[idM]
                    idM <= idM + 1
                end
                helsif(idM > last) do
                    arO[idO] <= arI[idF]
                    idF <= idF + 1
                end
                helsif(cond) do
                    arO[idO] <= arI[idF]
                    idF <= idF + 1
                end
                helse do
                    arO[idO] <= arI[idM]
                    idM <= idM + 1
                end
                idO <= idO + 1
            end
        end

        # HW implementation of the Ruby sort.
        def ssort(&ruby_block)
            enum = self.seach
            n = enum.size
            # Declare the result signal.
            res = nil
            flg = nil
            siz = nil
            HDLRuby::High.cur_system.open do
                res = enum.type[-n].inner(HDLRuby.uniq_name(:"sort_res"))
            end
            # Only one element?
            if n == 1 then
                # Just copy to the result and end here.
                res[0] <= enum.snext
                return res
            end
            tmp = []
            idxF = nil; idxM = nil; idxO = nil
            HDLRuby::High.cur_system.open do
                # More elements, need to declare intermediate arrays.
                ((n-1).width).times do
                    tmp << enum.type[-n].inner(HDLRuby.uniq_name(:"sort_tmp"))
                end
                # The result will be the last of the intermediate arrays.
                tmp << res
            end
            # Fills the first temporary array.
            enum.seach_with_index { |e,i| tmp[0][i] <= e }
            # Is there only 2 elements?
            if n == 2 then
                if ruby_block then
                    cond = ruby_block.call(tmp[0][0],tmp[0][1]) < 0
                else
                    cond = tmp[0][0] < tmp[0][1]
                end
                # Just look for the min and the max.
                hif(cond) do
                    res[0] <= tmp[0][0]
                    res[1] <= tmp[0][1]
                end
                helse do
                    res[1] <= tmp[0][0]
                    res[0] <= tmp[0][1]
                end
                return res
            end
            # Performs the sort using a merge-based algorithm.
            breadth = 1; i = 0
            # while(breadth*2 < n)
            while(breadth < n)
                pos = 0; last = 0
                while(pos+breadth < n)
                    last = [n-1,pos+breadth*2-1].min
                    ssort_merge(tmp[i], tmp[i+1], pos, pos+breadth,last,&ruby_block)
                    pos = pos + breadth * 2
                end
                # Copy the remaining elements if any
                # puts "n=#{n} breadth=#{breadth} last=#{last} n-last-1=#{n-last-1}"
                if last < n-1 then
                    (n-last-1).stimes do |j|
                        tmp[i+1][last+1+j] <= tmp[i][last+1+j]
                    end
                end
                # Next step
                # SequencerT.current.step
                breadth = breadth * 2
                i += 1
            end
            # # Last merge if the array size was not a power of 2.
            # if (breadth*2 != n) then
            #     ssort_merge(tmp[-2],tmp[-1],0,breadth,n-1,&ruby_block)
            #     # SequencerT.current.step
            # end
            return res
        end

        # HW implementation of the Ruby sort.
        def ssort_by(&ruby_block)
            # No block given? Generate a new wrapper enumerator for smin_by.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:ssort_by,n)
            end
            # A block is given, use smin with a proc that applies ruby_block
            # before comparing.
            return ssort { |a,b| ruby_block.call(a) <=> ruby_block.call(b) }
        end

        # HW implementation of the Ruby sum.
        def ssum(initial_value = nil,&ruby_block)
            enum = self.seach
            # Define the computation type: from the initial value if any,
            # otherwise from the enum.
            typ = initial_value ? initial_value.to_expr.type : enum.type
            # Ensures there is an initial value.
            initial_value = 0.to_expr.as(typ) unless initial_value
            # Generate the result signal.
            res  = nil
            HDLRuby::High.cur_system.open do
                res = typ.inner(HDLRuby.uniq_name(:"sum_res"))
            end
            # Start the initialization
            enum.srewind
            # Yes, start with the initial value.
            res <= initial_value
            SequencerT.current.swhile(enum.snext?) do
                # Do the accumulation.
                if (ruby_block) then
                    # There is a ruby block, use it to process the element first.
                    res <= res + ruby_block.call(enum.snext)
                else
                    # No ruby block, just do the sum
                    res <= res + enum.snext
                end
            end
            return res
        end

        # The HW implementation of the Ruby take.
        def stake(n)
            enum = self.seach
            # Generate the result signal.
            res  = nil
            HDLRuby::High.cur_system.open do
                res = enum.type[-n].inner(HDLRuby.uniq_name(:"sum_res"))
            end
            # Take the n first elements.
            n.stimes do |i|
                res[i] <= enum.access(i)
            end
            return res
        end

        # The HW implementation of the Ruby take_while.
        def stake_while(&ruby_block)
            # No block given? Generate a new wrapper enumerator for sdrop_while.
            if !ruby_block then
                return SEnumeratorWrapper.new(self,:stake_while)
            end
            # A block is given.
            # Generate the vector to put the result in.
            # The declares the resulting vector and take flag.
            res = nil
            flg = nil
            enum = self.seach
            HDLRuby::High.cur_system.open do
                res = enum.type[-enum.size].inner(HDLRuby.uniq_name(:"take_vec"))
                flg = bit.inner(HDLRuby.uniq_name(:"take_flg"))
            end
            # And do the iteration.
            # First fill from current enumerable elements.
            flg <= 1
            enum.seach.with_index do |elem,i|
                HDLRuby::High.top_user.hif(flg == 1) do
                    HDLRuby::High.top_user.hif(ruby_block.call(elem) == 0) do
                        flg <= 0
                    end
                end
                HDLRuby::High.top_user.hif(flg == 1) do
                    res[i] <= elem
                end
                HDLRuby::High.top_user.helse do
                    res[i] <= 0
                end
            end
            # Return the resulting vector.
            return res
        end

        # HW implementation of the Ruby tally.
        # NOTE: to do, or may be not.
        def stally(h = nil)
            raise "stally is not supported yet."
        end

        # HW implementation of the Ruby to_h.
        # NOTE: to do, or may be not.
        def sto_h(h = nil)
            raise "sto_h is not supported yet."
        end

        # HW implementation of the Ruby uniq.
        def suniq(&ruby_block)
            enum = self.seach
            n = enum.size
            # Declare the result signal the flag and the result array size index
            # used for implementing the algorithm (shift-based sorting).
            res = nil
            flg = nil
            idx = nil
            HDLRuby::High.cur_system.open do
                res = enum.type[-n].inner(HDLRuby.uniq_name(:"suniq_res"))
                flg = bit.inner(HDLRuby.uniq_name(:"suniq_flg"))
                idx = bit[n.width].inner(HDLRuby.uniq_name(:"suniq_idx"))
            end
            enum.srewind
            # Do the iteration.
            idx <= 0
            SequencerT.current.swhile(enum.snext?) do
                # Multiple min case.
                SequencerT.current.sif(enum.snext?) do
                    elem = enum.snext
                    flg <= 1
                    n.times do |i|
                        # Compute the comparison between the result element at i
                        # and the enum element.
                        hif(i < idx) do
                            if ruby_block then
                                flg <= (flg & 
                                        (ruby_block.call(res[i]) != ruby_block.call(elem)))
                            else
                                flg <= (flg & (res[i] != elem))
                            end
                        end
                        # If flg is 1 the element is new, if it is the right
                        # position, add it to the result.
                        hif((idx == i) & flg) do
                            # An set the new min in current position.
                            res[i] <= elem
                            # For next position now.
                            idx <= idx + 1
                            # Stop here for current element.
                            flg <= 0
                        end
                    end
                end
            end
            # Fills the remaining location with 0.
            SequencerT.current.swhile(idx < enum.size) do
                res[idx] <= 0
                idx <= idx + 1
            end
            return res
        end

        # HW implementation of the Ruby zip.
        # NOTE: for now szip is deactivated untile tuples are properly
        #       handled by HDLRuby.
        def szip(obj,&ruby_block)
            res = nil
            l0,r0,l1,r1 = nil,nil,nil,nil
            idx = nil
            enum0 = self.seach
            enum1 = obj.seach
            # Compute the minimal and maximal iteration sizes of both
            # enumerables.
            size_min = [enum0.size,enum1.size].min
            size_max = [enum0.size,enum1.size].max
            HDLRuby::High.cur_system.open do
                # If there is no ruby_block, szip generates a resulting vector
                # and its access indexes.
                unless ruby_block then
                    res = bit[enum0.type.width+enum1.type.width][-size_max].inner(HDLRuby.uniq_name(:"zip_res"))
                    l0 = enum0.type.width+enum1.type.width - 1
                    r0 = enum1.type.width
                    l1 = r0-1
                    r1 = 0
                end
                # Generate the index.
                idx = [size_max.width].inner(HDLRuby.uniq_name(:"zip_idx"))
            end
            # Do the iteration.
            enum0.srewind
            enum1.srewind
            # As long as there is enough elements.
            idx <= 0
            SequencerT.current.swhile(idx < size_min) do
                # Generate the access to the elements.
                elem0 = enum0.snext
                elem1 = enum1.snext
                if ruby_block then
                    # A ruby block is given, applies it directly on the elements.
                    ruby_block.call(elem0,elem1)
                else
                    # No ruby block, put the access results into res.
                    # res[idx][l0..r0] <= elem0
                    # res[idx][l1..r1] <= elem1
                    res[idx] <= [elem0,elem1]
                end
                idx <= idx + 1
            end
            # For the remaining iteration use zeros for the smaller enumerable.
            SequencerT.current.swhile(idx < size_max) do
                # Generate the access to the elements.
                elem0 = enum0.size < size_max ? 0 : enum0.snext
                elem1 = enum1.size < size_max ? 0 : enum1.snext
                if ruby_block then
                    # A ruby block is given, applies it directly on the elements.
                    ruby_block.call(elem0,elem1)
                else
                    # No ruby block, put the access results into res.
                    # res[idx][l0..r0] <= elem0
                    # res[idx][l1..r1] <= elem1
                    res[idx] <= [elem0,elem1]
                end
                idx <= idx + 1
            end
            unless ruby_block then
                return res
            end
        end

        # Iterator on the +num+ next elements.
        # *NOTE*:
        #   - Stop iteration when the end of the range is reached or when there
        #     are no elements left
        #   - This is not a method from Ruby but one specific for hardware where
        #     creating a array is very expensive.
        def seach_nexts(num,&ruby_block)
            # # No block given, returns a new enumerator.
            # unless ruby_block then
            #     res = SEnumeratorWrapper.new(self,:seach_nexts,num)
            #     res.size = num
            #     return res
            # end
            # # A block is given, iterate.
            # enum = self.seach
            # # Create a counter. 
            # count = nil
            # zero = nil
            # one = nil
            # HDLRuby::High.cur_system.open do
            #     if num.respond_to?(:width) then
            #         count = [num.width].inner(HDLRuby.uniq_name(:"snexts_count"))
            #     else
            #         count = num.to_expr.type.inner(HDLRuby.uniq_name(:"snexts_count"))
            #     end
            #     zero = _b0
            #     one  = _b1
            # end
            # count <= num
            # SequencerT.current.swhile(count > zero) do
            #     ruby_block.call(enum.snext)
            #     count <= count - one
            # end
            zero = nil
            one = nil
            HDLRuby::High.cur_system.open do
                zero = _b0.as(num.to_expr.type)
                one = _b1.as(num.to_expr.type)
            end
            subE = SEnumeratorSub.new(self,zero..num-one)
            if ruby_block then
                # A block is given, iterate immediatly.
                subE.seach(&ruby_block)
            else
                # No block given, return the new sub iterator.
                return subE
            end
        end

    end


    # Describes a sequencer enumerator class that allows to generate HW iteration
    # over HW or SW objects within sequencers.
    # This is the abstract Enumerator class.
    class SEnumerator
        include SEnumerable

        # The methods that need to be defined.
        [:size, :type, :result, :index, 
         :clone, :speek, :snext, :srewind].each do |name|
            define_method(:name) do
                raise "Method '#{name}' must be defined for a valid sequencer enumerator."
            end
        end

        # Iterate on each element.
        def seach(&ruby_block)
            # No block given, returns self.
            return self unless ruby_block
            # A block is given, iterate.
            this = self
            # Reinitialize the iteration.
            this.srewind
            # Perform the iteration.
            SequencerT.current.swhile(self.index < self.size) do
                # ruby_block.call(this.snext)
                HDLRuby::High.top_user.instance_exec(this.snext,&ruby_block)
            end
        end

        # Iterator on each of the elements in range +rng+.
        # *NOTE*: 
        #   - Stop iteration when the end of the range is reached or when there
        #     are no elements left
        #   - This is not a method from Ruby but one specific for hardware where
        #     creating a array is very expensive.
        def seach_range(rng,&ruby_block)
            # No block given, returns a new enumerator.
            return SEnumeratorWrapper.new(self,:seach_range) unless ruby_block
            # A block is given, iterate.
            this = self
            # Perform the iteration.
            self.index <= rng.first
            SequencerT.current.swhile((self.index < self.size) & 
                                      (self.index <= rng.last) ) do
                ruby_block.call(this.snext)
            end
        end

        # Iterate on each element with index.
        def seach_with_index(&ruby_block)
            return self.with_index(&ruby_block)
        end

        # Iterate on each element with arbitrary object +obj+.
        def seach_with_object(val,&ruby_block)
            # self.seach do |elem|
            #     ruby_block(elem,val)
            # end
            return self.with_object(val,&ruby_block)
        end

        # Iterates with an index.
        def with_index(&ruby_block)
            # Is there a ruby block?
            if ruby_block then
                # Yes, iterate directly.
                idx = self.index
                return self.seach do |elem|
                    ruby_block.call(elem,idx-1)
                end
            end
            # No, create a new enumerator with +with_index+ as default
            # iteration.
            return SEnumeratorWrapper.new(self,:with_index)
        end

        # Return a new SEnumerator with an arbitrary arbitrary object +obj+.
        def with_object(obj)
            # Is there a ruby block?
            if ruby_block then
                # Yes, iterate directly.
                return self.seach do |elem|
                    ruby_block.call(elem,val)
                end
            end
            # No, create a new enumerator with +with_index+ as default
            # iteration.
            return SEnumeratorWrapper.new(self,:with_object,obj)
        end

        # Return a new SEnumerator going on iteration over enumerable +obj+
        def +(obj)
            enum = self.clone
            obj_enum = obj.seach
            res = nil
            this = self
            HDLRuby::High.cur_system.open do
                res = this.type.inner(HDLRuby.uniq_name("enum_plus"))
            end
            return SEnumeratorBase.new(this.type,this.size+obj_enum.size) do|idx|
                HDLRuby::High.top_user.hif(idx < this.size) { res <= enum.snext }
                HDLRuby::High.top_user.helse            { res <= obj_enum.snext }
                res
            end
        end
    end


    # Describes a sequencer enumerator class that allows to generate HW iterations
    # over HW or SW objects within sequencers.
    # This is the wrapper Enumerator over an other one for applying an other
    # interation method over the first one.
    class SEnumeratorWrapper < SEnumerator

        # Create a new SEnumerator wrapper over +enum+ with +iter+ iteration
        # method and +args+ argument.
        def initialize(enum,iter,*args)
            if enum.is_a?(SEnumerator) then
                @enumerator = enum.clone
            else
                @enumerator = enum.seach
            end
            @iterator  = iter.to_sym
            @arguments = args
        end

        # The directly delegate methods.
        def size
            return @enumertor.size
        end

        def type
            return @enumerator.type
        end

        def result
            return @enumerator.result
        end

        def index
            return @enumerator.index
        end

        def access(idx)
            return @enumerator.access(idx)
        end

        def speek
            return @enumerator.speek
        end

        def snext
            return @enumerator.snext
        end

        def snext?
            # if @size then
            #     return @enumerator.index < @size
            # else
            #     return @enumerator.snext?
            # end
            return @enumerator.snext?
        end

        def snext!(val)
            return @enumerator.snext!(val)
        end

        def srewind
            return @enumerator.srewind
        end

        # Iterator on each of the elements in range +rng+.
        # *NOTE*: 
        #   - Stop iteration when the end of the range is reached or when there
        #     are no elements left
        #   - This is not a method from Ruby but one specific for hardware where
        #     creating a array is very expensive.
        def seach_range(rng,&ruby_block)
            return @enumerator.seach_range(rng,&ruby_block)
        end

        # Clones the enumerator.
        def clone
            return SEnumeratorWrapper.new(@enumerator,@iterator,*@arguments)
        end

        # Iterate over each element.
        def seach(&ruby_block)
            # No block given, returns self.
            return self unless ruby_block
            # A block is given, iterate.
            return @enumerator.send(@iterator,*@arguments,&ruby_block)
        end
    end


    # Describes a sequencer enumerator class that allows to generate HW iterations
    # over HW or SW objects within sequencers.
    # This is the sub Enumerator over an other one for interating inside the
    # enumerator.
    # This is specific the HDLRuby for avoiding creation of array which are
    # expensive in HW. Used by seach_next for example.
    # Will change the index position of the initial iterator without reseting
    # it.
    class SEnumeratorSub < SEnumerator

        # Create a new SEnumerator wrapper over +enum+ among +rng+ indexes.
        def initialize(enum,rng,*args)
            @enumerator = enum.seach
            @range = rng.first..rng.last
            # Declare the sub index.
            idx = nil
            siz = @range.last-@range.first+1
            HDLRuby::High.cur_system.open do
                idx = [siz.width].inner({
                    HDLRuby.uniq_name("sub_idx") => 0 })
            end
            @index = idx
            @size = siz
        end

        # The directly delegate methods.
        def size
            return @size
        end

        def type
            return @enumerator.type
        end

        def result
            return @enumerator.result
        end

        def index
            return @index
        end

        def access(idx)
            return @enumerator.access(@index+@range.first)
        end

        def speek
            return @enumerator.speek
        end

        def snext
            @index <= @index + 1
            return @enumerator.snext
        end

        def snext?
            return @index < self.size
        end

        def snext!(val)
            return @enumerator.snext!(val)
        end

        def srewind
            @index <= 0
        end

        # Clones the enumerator.
        def clone
            return SEnumeratorSub.new(@enumerator,@range)
        end

        # Iterate over each element.
        def seach(&ruby_block)
            # No block given, returns self.
            return self unless ruby_block
            # A block is given, iterate.
            this = self
            SequencerT.current.swhile(this.snext?) do
                ruby_block.call(this.snext)
            end
        end
    end



    # Describes a sequencer enumerator class that allows to generate HW 
    # iterations over HW or SW objects within sequencers.
    # This is the base Enumerator that directly iterates.
    class SEnumeratorBase < SEnumerator

        attr_reader :size
        attr_reader :type
        attr_reader :result
        attr_reader :index

        # Create a new sequencer for +size+ elements as +typ+ with an HW
        # array-like accesser +access+.
        # def initialize(typ,size,&access)
        def initialize(typ,size = nil,&access)
            # Sets the size.
            @size = size
            # Sets the type.
            @type = typ
            # Sets the accesser.
            @access = access
            # Compute the index width (default: safe 32 bits).
            width = @size.respond_to?(:width) ? @size.width : 
                    @size.respond_to?(:type) ? size.type.width : 32
            # puts "width=#{width}"
            # # Create the index and the iteration result.
            # Create the index (if relevant) and the iteration result.
            idx = nil
            result = nil
            # HDLRuby::High.cur_system.open do
            #     idx = [width].inner({
            #         HDLRuby.uniq_name("enum_idx") => 0 })
            #     result = typ.inner(HDLRuby.uniq_name("enum_res"))
            # end
            idx_required = @size ? true : false
            HDLRuby::High.cur_system.open do
                idx = [width].inner({
                    HDLRuby.uniq_name("enum_idx") => 0 }) if idx_required
                result = typ.inner(HDLRuby.uniq_name("enum_res"))
            end
            @index = idx
            @result = result
        end

        # Clones the enumerator.
        def clone
            return SEnumeratorBase.new(@type,@size,&@access)
        end

        # Generates the access at +idx+
        def access(idx)
            @access.call(idx)
        end

        # View the next element without advancing the iteration.
        def speek
            @result <= @access.call(@index)
            return @result
        end

        # Get the next element.
        def snext
            @result <= @access.call(@index)
            # @index <= @index + 1
            @index <= @index + 1 if @index
            return @result
        end

        # Tell if there is a next element.
        def snext?
            # return @index < @size
            return @index ? @index < @size : true
        end

        # Set the next element, also return the access result so that
        # it can be used as bidirectional transaction.
        def snext!(val)
            # @access.call(@index,val)
            # @index <= @index + 1
            # return val
            res = @access.call(@index,val)
            @index <= @index + 1 if @index
            return res
        end

        # Restart the iteration.
        def srewind
            # @index <= 0
            @index <= 0 if @index
        end
    end




    module HDLRuby::High::HExpression
        # Enhance the HExpression module with sequencer iteration.

        # HW iteration on each element.
        def seach(&ruby_block)
            # Create the hardware iterator.
            this = self
            hw_enum = SEnumeratorBase.new(this.type.base,this.type.size) do |idx,val = nil|
                if val then
                    # Write access
                    this[idx] <= val
                else
                    # Read access
                    this[idx]
                end
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end

        # Also adds the methods of SEnumerable.
        SEnumerable.instance_methods.each do |meth|
            define_method(meth,SEnumerable.instance_method(meth))
        end
    end


    # class HDLRuby::High::Value
    module HDLRuby::High::HExpression
        # Enhance the Value class with sequencer iterations.

        # HW times iteration.
        def stimes(&ruby_block)
            # return (0..self-1).seach(&ruby_block)
            return AnyRange.new(0,self-1).seach(&ruby_block)
        end

        # HW upto iteration.
        def supto(val,&ruby_block)
            # return (self..val).seach(&ruby_block)
            return AnyRange.new(self,val).seach(&ruby_block)
        end

        # HW downto iteration.
        def sdownto(val,&ruby_block)
            # Create the hardware iterator.
            # range = val..(self.to_i)
            range = AnyRange.new(val,self)
            hw_enum = SEnumeratorBase.new(signed[32],range.size) do |idx|
                range.last - idx
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end


    module ::Enumerable
        # Enhance the Enumerable module with sequencer iteration.

        # HW iteration on each element.
        def seach(&ruby_block)
            # Convert the enumrable to an array for easier processing.
            ar = self.to_a
            return if ar.empty? # The array is empty, nothing to do.
            # Compute the type of the elements.
            typ = ar[0].respond_to?(:type) ? ar[0].type : signed[32]
            # Create the hardware iterator.
            hw_enum = SEnumeratorBase.new(typ,ar.size) do |idx|
                HDLRuby::High.top_user.mux(idx,*ar)
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end

        # Also adds the methods of SEnumerable.
        SEnumerable.instance_methods.each do |meth|
            define_method(meth,SEnumerable.instance_method(meth))
        end
    end


    class ::Range
        # Enhance the Range class with sequencer iteration.
        include SEnumerable

        # HW iteration on each element.
        def seach(&ruby_block)
            # Create the iteration type.
            # if self.first < 0 || self.last < 0 then
            #     fw = self.first.is_a?(Numeric) ? self.first.abs.width :
            #          self.first.width
            #     lw = self.last.is_a?(Numeric) ? self.last.abs.width :
            #          self.last.width
            #     typ = signed[[fw,lw].max]
            # else
            #     typ = bit[[self.first.width,self.last.width].max]
            # end
            # Create the iteration type: selection of the larger HDLRuby type
            # between first and last. If one of first and last is a Numeric,
            # priority to the non Numeric one.
            if (self.last.is_a?(Numeric)) then
                typ = self.first.to_expr.type
            elsif (self.first.is_a?(Numeric)) then
                typ = self.last.to_expr.type
            else
                typ = self.first.type.width > self.last.type.width ? 
                    self.first.type : self.last.type
            end
            # Create the hardware iterator.
            this = self
            size = this.size ? this.size : this.last - this.first + 1
            # size = size.to_expr
            # if size.respond_to?(:cast) then
            #     size = size.cast(typ)
            # else
            #     size = size.as(typ)
            # end
            size = size.to_expr.as(typ)
            # hw_enum = SEnumeratorBase.new(signed[32],size) do |idx|
            hw_enum = SEnumeratorBase.new(typ,size) do |idx|
                # idx.as(typ) + this.first
                idx.as(typ) + this.first.to_expr.as(typ)
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end


    # Range substitute class for sequencers that supports any kind of bounds.
    class AnyRange
        # Enhance the AnyRange class with sequencer iteration.
        include SEnumerable

        attr_reader :first, :last

        def initialize(first,last)
            @first = first
            @last = last
        end

        # HW iteration on each element.
        def seach(&ruby_block)
            # Create the iteration type: selection of the larger HDLRuby type
            # between first and last. If one of first and last is a Numeric,
            # priority to the non Numeric one.
            if (self.last.is_a?(Numeric)) then
                typ = self.first.to_expr.type
            elsif (self.first.is_a?(Numeric)) then
                typ = self.last.to_expr.type
            else
                typ = self.first.type.width > self.last.type.width ? 
                    self.first.type : self.last.type
            end
            # Create the hardware iterator.
            this = self
            # size = this.size ? this.size : this.last - this.first + 1
            size = this.last - this.first + 1
            size = size.to_expr.as(typ)
            hw_enum = SEnumeratorBase.new(typ,size) do |idx|
                idx.as(typ) + this.first.to_expr.as(typ)
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end


    class ::Integer
        # Enhance the Integer class with sequencer iterations.

        # HW times iteration.
        def stimes(&ruby_block)
            return (0..self-1).seach(&ruby_block)
        end

        # HW upto iteration.
        def supto(val,&ruby_block)
            return (self..val).seach(&ruby_block)
        end

        # HW downto iteration.
        def sdownto(val,&ruby_block)
            # Create the hardware iterator.
            range = val..self
            hw_enum = SEnumeratorBase.new(signed[32],range.size) do |idx|
                range.last - idx
            end
            # Is there a ruby block?
            if(ruby_block) then
                # Yes, apply it.
                return hw_enum.seach(&ruby_block)
            else
                # No, return the resulting enumerator.
                return hw_enum
            end
        end
    end



    # Creates a sequencer of code synchronised of +clk+ and starting on +start+.
    def sequencer(clk,start,&ruby_block)
        return SequencerT.new(clk,start,&ruby_block)
    end

    # Creates an sequencer enumerator using a specific block access.
    # - +typ+ is the data type of the elements.
    # - +size+ is the number of elements, nil if not relevant.
    # - +access+ is the block implementing the access method.
    # def senumerator(typ,size,&access)
    def senumerator(typ,size = nil,&access)
        return SEnumeratorBase.new(typ,size,&access)
    end


end
