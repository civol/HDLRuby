require 'HDLRuby'
require 'HDLRuby/hruby_tools'
require 'HDLRuby/hruby_low_mutable'
require 'HDLRuby/hruby_low_with_bool'


module HDLRuby::Low


##
# Split signals with determined bit and range accesses.
#
########################################################################
    

    class SystemT

      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = { })
        # Search in the scope.
        return self.scope.get_signal_splits(res)
      end

      # Split the signals of a system if they have determined bit or range 
      # accessed.
      def split_signals(signals_splits = nil)
        # puts "split_signals for systemT=#{self.name}"
        # Gather the signals to split and their splitting.
        signal_splits = self.get_signal_splits unless signals_splits

        # Do the splitting.
        signal_splits.each do |sig,splits|
          # Get the owner of the signal.
          owner = sig.parent
          dir = sig.direction
          # # Remove the signal from the owner since it is split.
          # case dir
          # when :input
          #   owner.delete_input!(sig)
          # when :output
          #   owner.delete_output!(sig)
          # when :inout
          #   owner.delete_inout!(sig)
          # when :inner
          #   owner.delete_inner!(sig)
          # end

          # Add instead the corresponding sub signals.
          splits.each do |idx,(sub,places)|
            # puts "owner.class=#{owner.class} sub.class=#{sub.class}"
            # In the owner.
            case dir
            when :input
              owner.add_input(sub)
            when :output
              owner.add_output(sub)
            when :inout
              owner.add_input(sub)
            when :inner
              owner.add_inner(sub)
            end

            # Replace the references of the signal by its subs.
            places.each do |place|
              place.parent.map_nodes! do |node|
                node == place ? HDLRuby::Low::RefName.new(Bit,RefThis.new,sub.name) : node
              end
            end
          end
        end
      end
    end


    class Scope
      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = {})
        # Search in the sub systems.
        self.each_systemT { |sysT| sysT.get_signal_splits(res) }
        # Search in the sub scopes.
        self.each_scope { |scop| scop.get_signal_splits(res) }
        # Search in the instances.
        self.each_systemI { |sysI| sysI.get_signal_splits(res) }
        # Search in the connections.
        self.each_connection { |cnx| cnx.get_signal_splits(res) }
        # Search in the behaviors.
        self.each_behavior { |beh| beh.get_signal_splits(res) }
        return res
      end
    end


    class Behavior
      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = {})
        # Recurse on the events.
        self.each_event { |ev| ev.get_signal_splits(res) }
        # Recurse on the block.
        self.block.get_signal_splits(res)
        return res
      end
    end


    class Event
      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = {})
        if self.ref.is_a?(RefIndex) and self.ref.ref.is_a?(RefName) and
           self.ref.index.is_a?(Value) then
          sigref = self.ref
          # A split is found. Get the signal upward.
          sig = self.parent.parent.get_signal_upward(self.ref.name)
          sig.split_to_index(self.ref.index,res)
        elsif self.ref.is_a?(RefRange) and self.ref.ref.is_a?(RefName) and
          self.ref.range.first.is_a?(Value) and 
          self.ref.range.last.is_a?(Value) then
          sigref = self.ref
          # A split is found. Get the signal upward.
          sig = self.parent.parent.get_signal_upward(self.ref.name)
          sig.split_to_range(self.ref.range,res)
        end
        return res
      end
    end


    class SystemI
      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = {})
        return self.systemT.get_signal_splits(res)
      end
    end


    class Statement
      # Get the signals than can be split, where they are used and their
      # resulting sub signals.
      # The result is to be put in the +res+ table.
      def get_signal_splits(res = {})
        # Recurse on the sub statements.
        self.each_statement_deep do |stmnt|
          stmnt.each_node_deep do |expr|
            if expr.is_a?(RefIndex) and expr.ref.is_a?(RefName) and
               expr.index.is_a?(Value) then
              # A split is found. Get the signal upward.
              blk = self.block
              sig = blk ? blk.get_signal_up(expr.ref.name) : 
                self.scope.get_signal_up(expr.ref.name)
              sig.split_to_index(expr,expr.index,res) if sig
            elsif expr.is_a?(RefRange) and expr.ref.is_a?(RefName) and
              expr.range.first.is_a?(Value) and
              expr.range.last.is_a?(Value) then
              # A split is found. Get the signal upward.
              blk = self.block
              sig = blk ? blk.get_signal_up(expr.ref.name) : 
                self.scope.get_signal_up(expr.ref.name)
              sig.split_to_range(expr,expr.range,res) if sig
            end
          end
        end
        return res
      end
    end


    class SignalI
      # Split the signal at place +place+ for +index+ and register it to
      # +res+ table.
      def split_to_index(place ,index, res)
        index = index.to_i
        entry = res[self]
        unless entry then
          entry = {}
          res[self] = entry
        end
        split = entry[index]
        unless split then
          split = [SignalI.new(self.name.to_s + "[#{index}]",Bit), []]
          entry[index] = split
        end
        split[1] << place
        return res
      end

      # Split the signal at place +place+ for +index+ and register it to
      # +res+ table.
      def split_to_range(place ,range, res)
        range = range.first.to_i..range.last.to_i
        entry = res[self]
        unless entry then
          entry = {}
          res[self] = entry
        end
        split = entry[range]
        unless split then
          split = [SignalI.new(self.name.to_s + "[#{range}]",Bit), []]
          entry[range] = split
        end
        split[1] << place
        return res
      end
    end
end
