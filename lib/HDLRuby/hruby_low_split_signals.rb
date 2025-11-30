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
      def split_signals
        # Gather the signals to split and their splitting.
        signal_splits = self.get_signal_splits unless signals

        # Do the splitting.
        signal_split.each do |sig,splits|
          # Get the owner of the signal.
          owner = sig.parent
          # Remove the signal from the owner since it is split.
          case sig.direction
          when :input
            owner.delete_input!(sig)
          when :output
            owner.delete_output!(sig)
          when :inout
            owner.delete_inout!(sig)
          when :inner
            owner.delete_inner!(sig)
          end

          # Add instead the corresponding sub signals.
          splits.each do |sub,places|
            # In the owner.
            case sig.direction
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
                node == place ? HDLRuby::Low::RefName.new(sub.name) : node
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
        if self.ref.is_a?(RefIndex) and self.ref.ref.is_a?(RefName)
          and self.ref.index.is_a?(RefIndex) then
          sigref = self.ref
          # A split is found. Get the signal upward.
          sig = self.parent.parent.get_signal_upward(self.ref.name)
          sig.split_to(self.ref.index,res)
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
          stmnt.each_expression_deep do |expr|
            if expr.is_a?(RefIndex) and expr.ref.is_a?(RefName)
              and expr.index.is_a?(RefIndex) then
              # A split is found. Get the signal upward.
              sig = self.block.get_signal_up(self.ref.name)
              sig.split_to(expr,expr.index,res)
            end
          end
        end
        return res
      end
    end


    class SignalI
      # Split the signal at place +place+ for +index+ and register it to
      # +res+ table.
      def split_to(place ,index, res)
        index = index.to_i
        entry = res[sig]
        unless entry then
          entry = {}
          res[sig] = entry
        end
        split = entry[index]
        unless split then
          split = [new SginalI(self.name.to_s + "[#{index}]",Bit), []]
          entry[index] = split
        end
        split[1] << place
        return res
      end
    end
end
