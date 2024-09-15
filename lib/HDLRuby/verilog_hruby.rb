require "HDLRuby/verilog_parser"

# Generate HDLRuby code from a Verilog HDL AST (produced from 
# verilog_parser.rb)

module VerilogTools

  # The possible levels in HDLRuby generation.
  HDLRubyLevels  = [ :top, :system, :hdef, :<=, :seq, :par, :timed ]
  NoEventLevels  = [ :hdef, :<=, :seq, :par, :timed ]
  NoTimeLevels   = [ :hdef, :<=, :seq, :par ]

  # HDLRuby generation state.
  class HDLRubyState
    # String to add at new line for indent.
    attr_reader :indent

    # The current level in HDLRuby generation.
    attr_reader :level

    # Create a new state.
    def initialize
      @indent = ""  # String to add at new line for indent.
      @level = :top # Current level in HDLRuby generation.
    end

    # Set the indent string.
    def indent=(str)
      @intent = str.to_s
    end

    # Set the level in HDLRuby generation
    def level=(level)
      unless HDLRubyLevels.include?(level)
        raise "Internal error, unknown generation level #{level}"
      end
      @level = level
    end
  end


  class AST

    # Generate HDLRuby text from the current AST node.
    # +state+ is the HDLRuby generation state.
    def to_HDLRuby(state = HDLRubyState.new)
      # Execute the generation procedure corresponding to the type.
      return TO_HDLRuby[self.type].(self,state)
    end


    # Converts a Verilog HDL name to a HDLRuby one.
    def self.name_to_HDLRuby(name)
      if name[0] =~ /[_$A-Z]/ then
        # HDLRuby names cannot start with a $ or a capital letter.
        # To fix that add an "_", but then to avoid confusion, also
        # convert starting "_" to "__" if any.
        return "_" + name
      else
        return name
      end
    end



    # The types of ports declaration in module ports and items.
    PORT_DECLS = [ :input_declaration, :output_declaration,
                   :inout_declaration ]

    # The generation procedures.
    TO_HDLRuby = Hash.new( lambda do |ast,state|
      # By default, recurse on the children.
      return ast.map { |child| child.to_HDLRuby(state) }.join
    end)


    TO_HDLRuby[:module] = lambda do |ast,state|
      # Save and update the state.
      indent = state.indent
      level = state.level
      state.indent += "  "
      state.level = :system
      # Generate the name.
      name = ast[0].to_HDLRuby
      # Generate the generic parameters if any.
      parameters = ast[1]
      parameters = parameters ? parameters.to_HDLRuby : ""
      # Generate the ports.
      # From the port declaration.
      ports = ast[2]
      ports = ports ? ports.map {|p| p.TO_HDLRuby(state) } : ""
      # Remove the empty ports.
      ports.select! {|p| !p.empty? }
      # From the items, for that separate port declarations from others.
      pitems, items = ast[3].partition {|i| PORT_DECLS.include?(i.type) }
      ports += pitems.map {|p| p.to_HDLRuby(state) }
      # Generate the items.
      items = items.map{|i| i.to_HDLRuby(state) }
      # Generate the module text.
      res = indent + "system :" + name + " do " + parameters + "\n" + 
        state.indent + ports.join("\n" + state.indent) + "\n" + 
        state,indent + items.join("\n" + state.indent) + indent + "end\n"
      # Restores the state.
      state.indent = indent
      state.level  = level
      # Returns the resulting string.
      return res
    end


    TO_HDLRuby[:pre_parameter_declaration] = lambda do |ast,state|
      return "|" + ast.map { |p| p.to_HDLRuby(state) }.join(",") + "|"
    end


    TO_HDLRuby[:list_of_ports] = lambda do |ast,state|
      return ast.map { |p| p.to_HDLRuby(state) }.join("\n") 
    end


    TO_HDLRuby[:port] = lambda do |ast,state|
      p = ast[0]
      return "" unless p
      if p.type == :port_expression then
        return p.to_HDLRuby(state)
      else
        v = ast[1]
        return p.to_HDLRuby(state) + ": " + v ? v.to_HDLRuby(state) : ""
      end
    end


    TO_HDLRuby[:port_expression] = lambda do |ast,state|
      port = ast[0]
      if port.is_a?(Array) then
        return port.map {|p| p.to_HDLRuby(state) }.join("\n")
      else
        return port.to_HDLRuby(state)
      end
    end


    TO_HDLRuby[:input_port_declaration] = lambda do |ast,state|
      # Ignore the INPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".input :" + name
    end


    TO_HDLRuby[:output_port_declaration] = lambda do |ast,state|
      # Ignore the OUTPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".output :" + name
    end


    TO_HDLRuby[:inout_port_declaration] = lambda do |ast,state|
      # Ignore the INOUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".inout :" + name
    end


    TO_HDLRuby[:port_reference] = lambda do |ast,state|
      # Port reference are actually ignored since they are redeclared
      # afterward (or are they?).
      return ""
    end


    TO_HDLRuby[:task] = lambda do |ast,state|
      # Save and update the state.
      indent = state.indent
      level = state.level
      state.indent += "  "
      state.level = :hdef
      # Generate the task text (function defintion in HDLRuby).
      res = indent + "hdef :" + ast[0].to_HDLRuby + 
        " do |" + ast[1].to_HDLRuby + "|\n" +
        state.indent + ast[2].to_HDLRuby(state.indent) + indent + "end\n" 
      # Restores the state.
      state.indent = indent
      state.level  = level
      # Returns the resulting string.
      return res
    end


    TO_HDLRuby[:function] = lambda do |ast,state|
      # Save and update the state.
      indent = state.indent
      level = state.level
      state.indent += "  "
      state.level = :hdef
      # Generate the function text.
      # The return type is ignored for HDLRuby.
      res = indent + "hdef :" + ast[1].to_HDLRuby + 
        " do |" + ast[2].to_HDLRuby + "|\n" +
        state.indent + ast[3].to_HDLRuby(state.indent) + indent + "end\n" 
      # Restores the state.
      state.indent = indent
      state.level  = level
      # Returns the resulting string.
      return res
    end


    TO_HDLRuby[:input_declaration] = lambda do |ast,state|
      # Ignore the INPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      names = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".input " + names
    end


    TO_HDLRuby[:output_declaration] = lambda do |ast,state|
      # Ignore the OUTPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      names = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".output " + names
    end


    TO_HDLRuby[:inout_declaration] = lambda do |ast,state|
      # Ignore the INOUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2].to_HDLRuby(state)
      # Get the name.
      names = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return sign + range +".inout " + names
    end


    TO_HDLRuby[:list_of_variables] = lambda do |ast,state|
      return ast[0].map {|n| ":#{n}" }.join(",")
    end


    # Auth: Always is actually handled at the statement level.
    #
    # TO_HDLRuby[:always] = lambda do |ast,state|
    #   # Initialize the characteristics of the process.
    #   timed = false
    #   event = ""
    #   # Look ahead and check the statement to see what kind
    #   # of process it will be.
    #   statement = ast[0]
    #   delay_or_event_control = statement[0]
    #   if delay_or_event_control then
    #     # It is a time of event controled statement.
    #     delay_or_event_control = delay_or_event_control[0]
    #     if delay_or_event_control.type == :event_control then
    #       # Event controlled process.
    #       event = delay_or_event_control.to_HDLRuby(state)
    #     else
    #       # Timed process.
    #       timed = true
    #       # However, timed process are notr supported yet (only timed
    #       # initial blocks are supported).
    #       raise "Internal error: always with delay not supported yet."
    #     end
    #   end
    #   # Going the generate the content.
    #   # Save and update the state for that.
    #   indent = state.indent
    #   level = state.level
    #   state.indent += "  "
    #   # But before, look ahead to see if it is a seq or a par process.
    #   ptype = ast[1].blocking? ? :seq : :par
    #   state.level = ptype
    #   # The generate.
    #   content = ast[1].to_HDLRuby(state)
    #   # Restores the state and generate the process text.
    #   state.indent = indent
    #   state.level = level
    #   return state.indent + ptype.to_s + event + " do\n" +
    #     content + "\n" + state.indent + "end\n"
    # end


    TO_HDLRuby[:statement_or_null] = lambda do |ast,state|
      if ast[0] then
        return ast[0].to_HDLRuby(state)
      else
        return ""
      end
    end


    # TO_HDLRuby[:statement] = lambda do |ast,state|
    #   delay = ""
    #   delay_or_event_control = statement[0]
    #   # Save and update the state.
    #   indent = state.indent
    #   state.indent += "  "
    #   # Check if it is a supported statement.
    #   if delay_or_event_control then
    #     delay_or_event_control = delay_or_event_control[0]
    #     # For event (if supported just ignored since processed earlier.
    #     if delay_or_event_control.type == :event_control and
    #         NoEventLevels.include?(state.level) then
    #       ast.generate_error("there should not be an event here")
    #     end
    #     # For delay.
    #     if delay_or_event_control.type == :delay_control then
    #       if NoTimeLevels.include?(state.level) then
    #         ast.generate_error("there should not be a delay here")
    #       end
    #       # Supported, generate the delay.
    #       delay = delay_or_event_control.to_HDLRuby(state)
    #     end
    #   end
    #   # Generate the body of the statement.
    #   body = ast[1].to_HDLRuby(state)
    #   # Restore the state and return the resulting statement text.
    #   state.indent = indent
    #   return delay + body
    # end


    TO_HDLRuby[:statement] = lambda do |ast,state|
      event_txt = ""
      delay_txt = ""
      # Check if there is a delay or an event control,
      # and generate the corresponding text if possible in the
      # current generation state.
      delay_or_event_control = statement[0]
      if delay_or_event_control then
        delay_or_event_control = delay_or_event_control[0]
        # For event.
        if delay_or_event_control.type == :event_control then
          if NoEventLevels.include?(state.level) then
            ast.generate_error("there should not be an event here")
          end
          # Support, generate the event control text.
          event_txt = delay_or_event._control.to_HDLRuby(state)
        # For delay.
        elsif delay_or_event_control.type == :delay_control then
          if NoTimeLevels.include?(state.level) then
            ast.generate_error("there should not be a delay here")
          end
          # Supported, generate the delay control text.
          delay_txt = delay_or_event_control.to_HDLRuby(state)
        end
      end
      # For now going inside the statement, so save and update the state.
      indent = state.indent
      level  = state.level
      state.indent += "  "
      # Check is it a block, and generate the corresponding code.
      block_txt = ""
      if ast[1].type == :seq_block then
        seq_block = ast[1]
        # Get the name if any.
        name = seq_block[0]
        name_text = name ? name.to_HDLRuby(state) : ""
        # Generate the declarations if any.
        decls = seq_block[1]
        decls_text = decls ? decls.to_HDLRuby(state) : ""
        # Generate the content.
        seq_par_txt = [] # The list of seq and par block contents.
        content = seq_block[2]
        content_txt = ""
        content.each do |statement|
          # Get if the statement is blocking or non blocking.
          seq_par = statement.seq_par
          # Check if the blocking/non blocking mode changed.
          if seq_par_txt.empty? or seq_par !=  seq_par_txt[-1][0] then
            if !content_text.empty? then
              # There is a content, add it to the list.
              seq_par_txt[-1][1] = content_txt
              content_txt == ""
            end
            # Add a new block.
            seq_par << [:seq_par, nil ]
          end
          # Update the content.
          state.level = seq_par
          content_txt += statement.to_HDLRuby(state)
        end
        # Restores the state and generate the final text.
        state.indent = indent
        state.level = level
      end
      raise "Unsupported statement type: #{ast[1].type}"
    end


    # Blocking and non blocking assignments have the same resulting
    # code in HDLruby, however they are included in different kind of
    # blocks, but this is processed elsewhere.
    TO_HDLRuby[:blocking_assignment] = lambda do |ast,state|
      return state.indent + ast[0].to_HDLRuby(state)  + " <= " +
        ast[1].to_HDLRuby(state)
    end

    TO_HDLRuby[:non_blocking_assignment] = TO_HLDRuby[:blocking_assignment]


    TO_HDLRuby[:lvalue] = lambda do |ast, state|
      # Get the base of the primary: number or identifier.
      base = ast[0]
      base_txt = base.to_HDLRuby(state)
      expr1 = ast[1]
      expr2 = ast[2]
      if expr1 then
        # Array access type.
        if expr2 then
          # Range access.
          return base_txt + "[" +
            expr1.to_HDLRuby(state) + ".." + expr2.to_HDLRuby(state) + 
            "]"
        else
          # Index access.
          return base_txt + "[" + expr1.to_HDLRuby(state) + "]"
        end
      else
        # Default access.
        return base_txt
      end
    end


    TO_HDLRuby[:expression] = lambda do |ast,state|
      # Depending on the child.
      child = ast[0]
      # Is it a conditional expression?
      if child.is_a?(Array) then
        # Yes, generate the conditional.
        return child.map do |elem|
          elem.is_a?(String) ? elem : elem.to_HDLRuby(ast)
        end.join
      else
        # No, just return the generation result for the child
        return child.to_HDLRuby(ast)
      end
    end

    # All the expression AST have the same structure until the primary.

    TO_HDLRuby[:condition_term] = lambda do |ast,state|
      return ast[0].map do |elem|
          elem.is_a?(String) ? elem : elem.to_HDLRuby(ast)
        end.join
    end

    TO_HDLRuby[:logic_or_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:logic_and_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:bit_or_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:bit_xor_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:bit_and_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:equal_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:comparison_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:shift_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:add_term] = TO_HDLRuby[:condition_term]

    TO_HDLRuby[:mul_term] = TO_HDLRuby[:condition_term]


    TO_HDLRuby[:primary] = lambda do |ast,state|
      # Get the base of the primary: number or identifier.
      base = ast[0]
      base_txt = base.to_HDLRuby(state)
      # Depending on the base.
      if base.type == :mintypmax_expression then
        # Parenthesis case.
        return "(" + base_txt + ")"
      else
        expr1 = ast[1]
        expr2 = ast[2]
        if expr1 then
          # Array access type.
          if expr2 then
            # Range access.
            return base_txt + "[" +
              expr1.to_HDLRuby(state) + ".." + expr2.to_HDLRuby(state) + 
              "]"
          else
            # Index access.
            return base_txt + "[" + expr1.to_HDLRuby(state) + "]"
          end
        else
          # Default access.
          return base_txt
        end
      end
    end



    TO_HDLRuby[:event_expression] = lambda do |ast,state|
      return ast[0].map {|ev| ev.to_HDLRuby(state) }.join(",") 
    end


    TO_HDLRuby[:event_primary] = lambda do |ast,state|
      edge = ast[0]
      case edge
      when "posedge"
        return ast[1].to_HDLRuby + ".posedge"
      when "negedge"
        return ast[1].to_HDLRuby + ".negedge"
      when "*"
        # Activated on all.
        return ""
      else
        # Actually it is not an edge.
        return edge.to_HDLRuby(state)
      end
    end





    TO_HDLRuby[:_IDENTIFIER] = lambda do |ast,state|
      name_to_HDLRuby(ast[0])
    end

  end
end
