require "HDLRuby/verilog_parser"

# Generate HDLRuby code from a Verilog HDL AST (produced from 
# verilog_parser.rb)

module VerilogTools

  # The possible levels in HDLRuby generation.
  HDLRubyLevels  = [ :top, :system, :hdef, :<=, :seq, :par, :timed, :expr ]
  NoEventLevels  = [ :hdef, :<=, :seq, :par, :timed ]
  NoTimeLevels   = [ :hdef, :<=, :seq, :par ]

  # HDLRuby generation state.
  class HDLRubyState
    # String to add at new line for indent.
    attr_reader :indent

    # The current level in HDLRuby generation.
    attr_reader :level

    # The names of the ports of the current module.
    attr_reader :port_names

    # The default state.
    DEFAULT = HDLRubyState.new

    # Create a new state.
    def initialize
      @indent = ""     # String to add at new line for indent.
      @level = :top    # Current level in HDLRuby generation.
      @port_names = [] # The names of the ports of the current module.
    end

    # Set the indent string.
    def indent=(str)
      @indent = str.to_s
    end

    # Set the level in HDLRuby generation
    def level=(level)
      unless HDLRubyLevels.include?(level)
        raise "Internal error, unknown generation level #{level}"
      end
      @level = level
    end

    # Sets the port names.
    def port_names=(port_names)
      @port_names = port_names.to_a
    end
  end


  # Tool for gathering the names of ports.
  def self.get_port_names(ports)
    return [] unless ports
    return [] if ports.is_a?(AST) and ports.type == :property
    if ports.respond_to?(:map) then
      return ports.map {|p| VerilogTools.get_port_names(p) }.flatten
    else
      if ports.is_a?(String) then
        return [ ports ]
      else
        return []
      end
    end
  end


  # Tool for checking if a statement is to be seq or par in HDLRuby
  def self.get_seq_par(statement)
    case statement.type
    when :blocking_asignment
      return :seq
    when :non_blocking_assignment
      return :par
    when :statement
      statement.each do |child|
        next unless child.is_a?(AST)
        seq_par = VerilogTools.get_seq_par(child)
        return seq_par if seq_par
      end
      return nil
    else
      return nil
    end
  end

  # Tool for getting the name of a statement if any. 
  def self.get_name(statement)
    case statement.type
    when :seq_block, :par_block
      name = statement[0]
      name_txt = name ? name.to_HDLRuby(HDLRubyState::DEFAULT) : ""
      return name_txt
    when :statement
      statement.each do |child|
        next unless child.is_a?(AST)
        seq_par = VerilogTools.get_name(child)
        return seq_par if seq_par
      end
    else
      return ""
    end
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

  # Converts a Verilog HDL system task to a HDLRuby one.
  def self.system_to_HDLRuby(name,args)
    case name
    when "$signed"
      return "(#{args}).as(signed[(#{args}).type.width])"
    when "$display"
      return "hprint(#{args})"
    when "$finish"
      return "terminate"
    else
      raise "Internal error: unsupported system task #{name} yet."
    end
  end


  # Converts a Verilog HDL operator to a HDLRuby one.
  def self.operator_to_HDLRuby(op)
    case op
    when "!"
      return "~"
    when "&&"
      return "&"
    when "||"
      return "|"
    when "~&"
      return ".send(:~) | ~"
    when "~|"
      return ".send(:~) & ~"
    when "~^"
      return "^~"
    when "^|"
      return "^"
    else
      return op
    end
  end


  # The class describing generation errors.
  class GenerateError < StandardError
    
    # Create a new parse error with message +msg+, faulty line number 
    # +lpos+, and possibly file name +filename+.
    def initialize(msg,lpos,filename)
      @msg  = msg.to_s
      @lpos = lpos.to_i
      @filename = filename.to_s if filename
      super(self.make_message)
    end

    # Generate the error message.
    # NOTE: if you want to translate the error message, please
    # redefine the function.
    def make_message
      if @filename then
        head = "Generation error for file '#{@filename}' "
      else
        head = "Generation error "
      end
      return head + "line #{@lpos}: " + @msg + "."
    end
  end


  class AST

    # Generate HDLRuby text from the current AST node.
    # +state+ is the HDLRuby generation state.
    def to_HDLRuby(state = HDLRubyState.new)
      # Execute the generation procedure corresponding to the type.
      return TO_HDLRuby[self.type].(self,state)
    end


    # Generate a generation error with message indicated by +msg+.
    def generate_error(msg)
      property = self[-1]
      lpos = property[:lpos]
      filename = property[:filename]
      # Raise an exception containing an error message made of msg,
      # the adjusted line number, its number, and the column where error
      # happended.
      raise GenerateError.new(msg,lpos,filename)
    end


    # The types of ports declaration in module ports and items.
    PORT_DECLS = [ :input_declaration, :output_declaration,
                   :inout_declaration ]

    # The generation procedures.
    TO_HDLRuby = Hash.new( lambda do |ast,state|
      # By default, recurse on the children.
      return ast.map do |child| 
        if child.is_a?(Array) then
          child.map do |sub| 
            sub.is_a?(AST) ? sub.to_HDLRuby(state) : sub.to_s
          end.join
        elsif child.is_a?(AST) then
          child.to_HDLRuby(state)
        else
          child
        end
      end.join
    end)


    # Properties should not produce anything.
    TO_HDLRuby[:property] = lambda { |ast, state| return "" }


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
      parameters = parameters ? parameters.to_HDLRuby(state) : ""
      # Generate the ports.
      # From the port declaration.
      ports = ast[2]
      ports = ports ? ports[0].map {|p| p.to_HDLRuby(state) } : []
      # Remove the empty ports.
      ports.select! {|p| !p.empty? }
      # From the items, for that separate port declarations from others.
      pitems, items = ast[3].partition {|i| PORT_DECLS.include?(i.type) }
      ports += pitems.map {|p| p.to_HDLRuby(state) }
      # Gather the port names to skip the redeclarations.
      state.port_names = VerilogTools.get_port_names(pitems)
      # Generate the items.
      items = items.map do  |i|
        res = i.to_HDLRuby(state)
        res
      end
      # Generate the module text.
      res = indent + "system :" + name + " do " + parameters + "\n" + 
        ports.join + items.join + indent + "end\n"
      # Restores the state.
      state.indent = indent
      state.level  = level
      state.port_names = []
      # Returns the resulting string.
      return res
    end


    TO_HDLRuby[:pre_parameter_declaration] = lambda do |ast,state|
      return "|" + ast[0].to_HDLRuby(state) + "|"
    end


    TO_HDLRuby[:list_of_param_assignments] = lambda do |ast,state|
      return ast[0].map {|p| p.to_HDLRuby(state) }.join(", ")
    end


    TO_HDLRuby[:param_assignment] = lambda do |ast,state|
      return ast[0].to_HDLRuby(state) + "=" + ast[1].to_HDLRuby(state)
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
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return state.indent + sign + range +"input :" + name + "\n"
    end


    TO_HDLRuby[:output_port_declaration] = lambda do |ast,state|
      # Ignore the OUTPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return state.indent + sign + range +"output :" + name + "\n"
    end


    TO_HDLRuby[:inout_port_declaration] = lambda do |ast,state|
      # Ignore the INOUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the name.
      name = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return state.indent + sign + range +"inout :" + name + "\n"
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
      res = indent + "hdef :" + ast[1].to_HDLRuby(state) + 
        " do |" + ast[2].map{|p| p.to_HDLRuby(state)}.join(",") + "|\n" +
        state.indent + ast[3].to_HDLRuby(state) + indent + "end\n" 
      # Restores the state.
      state.indent = indent
      state.level  = level
      # Returns the resulting string.
      return res
    end


    TO_HDLRuby[:list_of_param_assignments] = lambda do |ast,state|
      return ast[0].map {|p| p.to_HDLRuby(state) }.join
    end

    
    TO_HDLRuby[:param_assignment] = lambda do |ast,state|
      return state.indent + ast[0].to_HDLRuby(state) + " = " +
        ast[1].to_HDLRuby(state) + "\n"
    end


    TO_HDLRuby[:input_declaration] = lambda do |ast,state|
      # Ignore the INPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the names.
      names = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      if state.level == :hdef then
        # Specific case of function argument: ignore the types, and
        # do not add new line no indent.
        return names.gsub(":","")
      else
        # General case
        return state.indent + sign + range +"input " + names + "\n"
      end
    end


    TO_HDLRuby[:output_declaration] = lambda do |ast,state|
      # Ignore the OUTPUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the names.
      names = ast[3].to_HDLRuby(state)
      # Genereate the resulting declaration.
      return state.indent + sign + range +"output " + names + "\n"
    end


    TO_HDLRuby[:inout_declaration] = lambda do |ast,state|
      # Ignore the INOUTTYPE not used in HDLRuby
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the range.
      range = ast[2]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # Get the names.
      names = ast[3].to_HDLRuby(state)
      # Generate the resulting declaration.
      return state.indent + sign + range + "inout " + names + "\n"
    end


    TO_HDLRuby[:net_declaration] = lambda do |ast,state|
      # Ignore the NETTYPE which is not required in HDLRuby.
      # Get the sign if any.
      sign = ast[1]
      sign = "" unless sign
      # Get the expandrange if any.
      expandrange = ast[2]
      expandrange = expandrange ? expandrange.to_HDLRuby(state) + "." : ""
      # Get the delay.
      delay = delay ? ast[3].to_HDLRuby(state) : ""
      if delay[0] then
        raise "Internal error: delay in wire declaration not supported yet."
      end
      # Get the names.
      names = ast[4].to_HDLRuby(state)
      if names.empty? then
        # There is actually no new inner.
        return ""
      end
      # Generate the resulting declaration.
      return state.indent + sign + expandrange + "inner " + names + "\n"
    end


    TO_HDLRuby[:reg_declaration] = lambda do |ast,state|
      # Get the sign if any.
      sign = ast[0]
      sign = "" unless sign
      # Get the range.
      range = ast[1]
      range = range ? range.to_HDLRuby(state) + "." : ""
      # # Get the name.
      # names = ast[2].to_HDLRuby(state)
      # if names.empty? then
      #   # There is actually no new inner.
      #   return ""
      # end
      # Registers can also be memory, so treat each name independantly.
      # # Genereate the resulting declaration.
      # return state.indent + sign + range +"inner " + names + "\n"
      res_txt = ""
      ast[2][0].each do |reg|
        if reg[0].type == :name_of_memory then
          # It is a memory, it must be declared.
          res_txt += state.indent + sign + range[0..-2] + 
            "[" + reg[1].to_HDLRuby(state) + ".." + 
            reg[2].to_HDLRuby(state)  + "].inner :" +
            reg[0].to_HDLRuby(state) + "\n"
        else
          # It is a standard register, it may override a previous
          # declaration and in such case can be omitted in HDLRuby.
          n = reg[0].to_HDLRuby(state)
          unless state.port_names.include?(n) then
            res_txt += state.indent + sign + range + "inner :" + n + "\n"
          end
        end
      end
        return res_txt
    end


    TO_HDLRuby[:continuous_assignment] = lambda do |ast,state|
      if ast[0] != "assign" then
        raise "Internal error: unsupported continous assignment: #{ast[0]}"
      end
      if ast[1] then
        raise "Internal error: drive strength not support yet #{ast[1]}"
      end
      if ast[2] then
        raise "Internal error: expandrange in continous assignment not support yet #{ast[2]}"
      end
      if ast[3] then
        raise "Internal error: delay in continous assignment not support yet #{ast[3]}"
      end
      return ast[4].to_HDLRuby(state)
    end


    # TO_HDLRuby[:list_of_variables] = lambda do |ast,state|
    #   return ast[0].map {|n| ":#{n.to_HDLRuby(state)}" }.join(", ")
    # end


    TO_HDLRuby[:list_of_variables] = lambda do |ast,state|
      # Auth: variables that have already been declared are ignored
      # since in HDLRuby all variables are identical.
      return ast[0].map do |n|
        n = n.to_HDLRuby(state)
        if state.port_names.include?(n) then
          nil
        else
          ":#{n}"
        end
      end.compact.join(", ")
    end


    TO_HDLRuby[:list_of_register_variables] = TO_HDLRuby[:list_of_variables]


    TO_HDLRuby[:initial_statement] = lambda do |ast,state|
      # Translated to a timed block.
      head_txt = state.indent + "timed do\n"
      # Save and update the state.
      indent = state.indent
      level = state.level
      state.indent += "  "
      state.level = :timed
      # Generate the content.
      content_txt = ast[0].to_HDLRuby(state)
      # Restore the state and generate the final result.
      state.indent = indent
      state.level = level
      return head_txt + content_txt + state.indent + "end\n"
    end


    TO_HDLRuby[:always_statement] = lambda do |ast,state|
      # Get the head statement.
      head = ast[0]
      head = head[0] while head[0].is_a?(AST) and head[0].type == :statement
      # Get its synchronization if any.
      event_txt = ""
      delay_txt = ""
      # Check if there is a delay or an event control,
      # and generate the corresponding text if possible in the
      # current generation state.
      if head[0].type == :delay_or_event_control then
        delay_or_event_control = head[0] 
        # There is a delay or an event, process it, and 
        # update the current statement (i.e. ast) to its second child.
        delay_or_event_control = delay_or_event_control[0]
        # For event.
        if delay_or_event_control.type == :event_control then
          if NoEventLevels.include?(state.level) then
            ast.generate_error("there should not be an event here")
          end
          # Support, generate the event control text.
          event_txt = delay_or_event_control.to_HDLRuby(state)
        # For delay.
        elsif delay_or_event_control.type == :delay_control then
          # if NoTimeLevels.include?(state.level) then
          #   ast.generate_error("there should not be a delay here")
          # end
          # Supported, generate the delay control text.
          delay_txt = delay_or_event_control.to_HDLRuby(state)
        end
        # Update the head statement.
        head = head[1]
      end
      # Get the name if any.
      name_txt = VerilogTools.get_name(head)
      if delay_txt[0] then
        # It will become a timed process with an infinite loop.
        decl_txt = state.indent + "timed do\n" +
          state.indent + "  repeat(-1) do\n" +
          "    " + delay_txt
        end_txt = state.indent + "  end\n" + state.indent + "end\n"
        # Now going to generate the content of the process.
        # For that, save and update the state.
        indent = state.indent
        level = state.level
        state.indent += "    "
        state.level = :timed
        # Now generate the content.
        content_txt = head.to_HDLRuby(state)
        # Restore the state and generate the result.
        state.indent = indent
        state.level = level
        return decl_txt + content_txt + end_txt
      else
        # It is a normal process.
        # Generate the declaration of the process.
        decl_txt = ""
        unless delay_txt.empty? then
          raise "Process with delay is not supported yet."
        end
        unless event_txt.empty? and name_txt.empty? then
          # There are arguments to the process.
          decl_txt += "(" + event_txt
          decl_txt += ", " if event_txt[0] and name_txt[0]
          decl_txt += "name: #{name_txt}" if name_txt[0]
          decl_txt +=")"
        end
        decl_txt += " do\n"
        # Generate its content.
        # First check if it is a seq or par process at first.
        seq_par = VerilogTools.get_seq_par(head)
        seq_par = :par unless seq_par
        # Now going to generate the content of the process.
        # For that, save and update the state.
        indent = state.indent
        level = state.level
        state.indent += "  "
        state.level = seq_par
        # Now generate the content.
        content_txt = head.to_HDLRuby(state)
        # Restore the state and generate the result.
        state.indent = indent
        state.level = level
        res =  indent + seq_par.to_s + decl_txt
        res += content_txt + indent + "end\n"
        return res
      end
    end

    TO_HDLRuby[:expandrange] = lambda do |ast,state|
      # Auth: for now the type of expand range is ignored, maybe it
      # is not necessary in HDLRuby.
      return ast[1].to_HDLRuby(state)
    end
    

    TO_HDLRuby[:range] = lambda do |ast,state|
      return "[" + ast[0].to_HDLRuby(state) + ".." + 
                   ast[1].to_HDLRuby(state) + "]"
    end


    TO_HDLRuby[:module_instantiation] = lambda do |ast,state|
      # Generate each element.
      module_txt = ast[0].to_HDLRuby(state)
      parameters_txt = ast[1] ? "(" + ast[1].to_HDLRuby(state) + ")." : ""
      instance_txts = ast[2].map {|i| i.to_HDLRuby(state) }
      # Generate the final state.
      # Auth: in HDLRuby there is one such statement per module instance.
      return instance_txts.map do |i|
        state.indent + module_txt + parameters_txt + i + "\n"
      end.join
    end


    TO_HDLRuby[:parameter_value_assignment] = lambda do |ast,state|
      return ast[0].map {|p| p.to_HDLRuby(state) }.join(",")
    end


    TO_HDLRuby[:module_instance] = lambda do |ast,state|
      instance_txt = "(:" + ast[0].to_HDLRuby(state) + ")"
      if ast[1] then
        return instance_txt + ".(" + ast[1].to_HDLRuby(state) + ")"
      else
        return instance_txt
      end
    end


    TO_HDLRuby[:name_of_instance] = lambda do |ast,state|
      name_txt = ast[0].to_HDLRuby(state)
      range_txt = ast[1] ? ast[1].to_HDLRuby(state) : ""
      if range_txt[0] then
        # Auth: I do not know what to do with range here.
        raise "Internal error: range in module instance name not supported yet."
      end
      return name_txt
    end


    TO_HDLRuby[:list_of_module_connections] = lambda do |ast,state|
      return ast[0].map { |c| c.to_HDLRuby(state) }.join(",")
    end


    TO_HDLRuby[:module_port_connection] = lambda do |ast,state|
      return ast[0].to_HDLRuby(state)
    end


    TO_HDLRuby[:named_port_connection] = lambda do |ast,state|
      return ast[0].to_HDLRuby(state) + ":" + ast[1].to_HDLRuby(state)
    end


    TO_HDLRuby[:statement_or_null] = lambda do |ast,state|
      if ast[0] then
        return ast[0].to_HDLRuby(state)
      else
        return ""
      end
    end


    TO_HDLRuby[:statement] = lambda do |ast,state|
      # Check if it is a block, and generate the corresponding code.
      block_txt = ""
      type = ast[0].is_a?(AST) ? ast[0].type : ast[0].to_sym
      case type
      when :seq_block
        seq_block = ast[0]
        # Get the name if any.
        # Auth: in this case, what to do with the name?
        name_txt = VerilogTools.get_name(seq_block)
        # Generate the declarations if any.
        decls = seq_block[1]
        decls_txt = decls ? decls.map {|d| d.to_HDLRuby(state)}.join : ""
        # Saves the state.
        indent = state.indent
        level = state.level
        # Generate the content.
        seq_par_txt = [ [state.level, ""] ] # The list of seq and par block contents.
        content = seq_block[2]
        content_txt = ""
        content.each do |statement|
          seq_par = VerilogTools.get_seq_par(statement)
          # Check if the blocking/non blocking mode changed.
          if seq_par != seq_par_txt[-1][0] then
            if !content_txt.empty? then
              # There is a content, add it to the list.
              seq_par_txt[-1][1] = content_txt
              content_txt == ""
            end
            # Add a new block.
            seq_par_txt << [seq_par, ""]
          end
          # Update the content.
          state.level = seq_par if seq_par
          content_txt += statement.to_HDLRuby(state)
        end
        # Update the final seq_par_txt block.
        seq_par_txt[-1][1] = content_txt
        # Restores the state and generate the final text.
        state.indent = indent
        state.level = level
        # Get the base seq or par state of the process
        base = seq_par_txt[0][0]
        # Generate the body text.
        body_txt = decls_txt.empty? ? "" : decls_txt + "\n"
        seq_par_txt.each do |seq_par, txt|
          if seq_par and seq_par != base then
            body_txt += state.indent + "  " + seq_par.to_s + " do\n" +
              txt + state.indent + "  " + "end\n"
          else
            body_txt += txt
          end
        end
        # Return the result.
        return body_txt
      when :system_task_enable
        sys = ast[0]
        name_txt = sys[0].to_HDLRuby(state)
        arg_txt = sys[1] ? sys[1].map{|a|a.to_HDLRuby(state)}.join(",") : ""
        return state.indent + 
          VerilogTools.system_to_HDLRuby(name_txt,arg_txt) + "\n"
      when :if
        # Saves the state.
        indent = state.indent
        level  = state.level
        # Generate the hif.
        state.indent += "  "
        if_txt = indent + "hif(" + ast[1].to_HDLRuby(state) + ") do\n"
        if_txt += ast[2].to_HDLRuby(state) + indent + "end\n"
        if ast[3] then
          if_txt += indent + "helse do\n"
          if_txt += ast[3].to_HDLRuby(state) + indent + "end\n"
        end
        # Restore the state and return the result.
        state.indent = indent
        state.level  = level
        return if_txt
      when :case
        # Saves the state.
        indent = state.indent
        level = state.level
        # Generate the hcase.
        state.indent += "  "
        case_txt = indent + "hcase(" + ast[1].to_HDLRuby(state) + ")\n"
        # Generate the case items.
        case_txt += ast[2].map do |item|
          res_txt = ""
          if item[0] then
            # hwhen case.
            res_txt += indent + "hwhen(" 
            res_txt += item[0].map {|e| e.to_HDLRuby(state) }.join(",")
            res_txt += ") do\n"
            res_txt += item[1].to_HDLRuby(state)
            res_txt += indent + "end\n"
          else
            # helse case.
            res_txt += indent + "helse do\n"
            res_txt += item[1].to_HDLRuby(state) + indent + "end\n"
          end
          res_txt
        end.join
        # Restore the state and return the result.
        state.indent = indent
        state.level  = level
        return case_txt
      when :blocking_assignment, :non_blocking_assignment
        return ast[0].to_HDLRuby(state)
      when :statement
        # Simply recurse, but first restores the indent.
        state.indent = indent
        return ast[0].to_HDLRuby(state)
      when :delay_or_event_control
        delay = ast[0][0]
        if delay.type != :delay_control then
          raise "Event not supported within statements yet."
        end
        return delay.to_HDLRuby(state) + ast[1].to_HDLRuby(state)
      else
        raise "Unsupported statement type: #{type}"
      end
    end


    TO_HDLRuby[:assignment] = lambda do |ast,state|
      return state.indent + ast[0].to_HDLRuby(state) + " <= " +
        ast[1].to_HDLRuby(state) + "\n"
    end


    # Blocking and non blocking assignments have the same resulting
    # code in HDLruby, however they are included in different kind of
    # blocks, but this is processed elsewhere.
    TO_HDLRuby[:blocking_assignment] = lambda do |ast,state|
      if ast[1] then
        raise "Internal error: unsupported delay or event in assingment yet."
      end
      return state.indent + ast[0].to_HDLRuby(state)  + " <= " +
        ast[2].to_HDLRuby(state)  + "\n"
    end

    TO_HDLRuby[:non_blocking_assignment] = TO_HDLRuby[:blocking_assignment]


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
        # Go inside an expression so save and update the state.
        level = state.level
        state.level = :expr
        # Yes, generate the conditional.
        res_txt = ""
        depth = 0
        elems = child.reverse
        while elems.any? do
          expr_txt = elems.pop.to_HDLRuby(state)
          case(elems.pop)
          when "?"
            res_txt += "mux(~" + expr_txt + ","
            depth += 1
          when ":" then
            res_txt += expr_txt + ","
          when nil then
            res_txt += expr_txt + ")" * depth
            depth = 0
          end
        end
        # Restores the state and return the result.
        state.level = level
      else
        # No, just return the generation result for the child
        res_txt = child.to_HDLRuby(state)
      end
      return res_txt
    end

    # All the expression AST have the same structure until the primary.

    TO_HDLRuby[:condition_term] = lambda do |ast,state|
      # Save the state (may change after).
      level = state.level
      if ast[0].size > 1 then
        # Go inside the expression, so update the level.
        state.level = :expr
      end
      res_txt = ast[0].map do |elem|
        elem.is_a?(String) ? VerilogTools.operator_to_HDLRuby(elem) : 
          elem.to_HDLRuby(state)
      end.join 
      # Restores the state.
      state.level = level
      if state.level != :expr or ast[0].size < 3 then
        # Single node, unary or not within expression cases:
        # no parenthesis required.
        return res_txt
      else
        # Otherwise they are required to avoid priority problems.
        return "(" + res_txt + ")"
      end
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

    TO_HDLRuby[:mul_term] = lambda do |ast,state|
      primary_txt = ast[0][-1].to_HDLRuby(state)
      if ast[0].size == 1 then
        # There is no operator, just return the priary text.
        return primary_txt
      else
        # There is an operator, depending on it.
        op = ast[0][0]
        case(op)
        when "+", "-", "~", "!"
          return VerilogTools.operator_to_HDLRuby(op) + primary_txt
        when "&", "|", "^", "^|"
          return primary_txt + 
            ".each.reduce(:" + VerilogTools.operator_to_HDLRuby(op) + ")"
        when "~&", "~|", "~^"
          return "~" + primary_txt + 
            ".each.reduce(:" + VerilogTools.operator_to_HDLRuby(op[1]) +")"
        else
          raise "Internal error: unknown unary operator #{op}"
        end
      end
    end


    TO_HDLRuby[:primary] = lambda do |ast,state|
      # Get the base of the primary: number or identifier.
      base = ast[0]
      base_txt = base.to_HDLRuby(state)
      # Depending on the base.
      if base.type == :mintypmax_expression then
        # Parenthesis case.
        # Auth: but can be ommitted since automatically
        # set for ensuring order of operations.
        # return "(" + base_txt + ")"
        return base_txt
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


    TO_HDLRuby[:number] = lambda do |ast,state|
      # Get the first number if any.
      number0 = ast[0] ? ast[0].to_HDLRuby(state) : ""
      # Get the base if any.
      base = ast[1] ? ast[1].to_HDLRuby(state) : ""
      # Get the second number if any.
      number1 = ast[2] ? ast[2].to_HDLRuby(state) : ""
      # Depending on the base.
      case base
      when "'b"
        # Binary encoding.
        return "_#{number0}b#{number1}"
      when "'o"
        # Octal encoding.
        return "_#{number0}o#{number1}"
      when "'d"
        # Decimal encoding.
        return "_#{number0}d#{number1}"
      when "'h"
        # Hexadecimal encoding.
        return "_#{number0}h#{number1}"
      when ""
        # Simple number.
        return number0
      else
        ast.generate_error("Invalid number base: #{base}")
      end
    end


    TO_HDLRuby[:concatenation] = lambda do |ast,state|
      return "[ " + ast[0].map {|e| e.to_HDLRuby(state) }.join(", ") + " ]"
    end


    TO_HDLRuby[:multiple_concatenation] = lambda do |ast,state|
      return "[" + ast[1].map {|e| e.to_HDLRuby(state) }.join(", ") + 
        " ].to_expr.as(bit[" + ast[0].to_HDLRuby(state) + "])"
    end


    TO_HDLRuby[:function_call] = lambda do |ast,state|
      # Get the name of the function.
      name_txt = ast[0].to_HDLRuby
      # Get the arguments if any.
      args_txt = ast[1] ? ast[1].map {|a|a.to_HDLRuby(state)}.join(",") : ""
      # Is it a system function call?
      if (ast[0].type == :name_of_system_function) then
        # Yes, specific process.
        return VerilogTools.system_to_HDLRuby(name_txt,args_txt)
      else
        # No, standard function call.
        return name_txt + "(" + args_txt + ")"
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
      VerilogTools.name_to_HDLRuby(ast[0])
    end


    TO_HDLRuby[:delay_control] = lambda do |ast,state|
      # Generate the delay.
      head_txt = state.indent + "!"
      delay_txt = ast[0].to_HDLRuby(state)
      # Compute the time scale.
      timescale = ast[-1][0][:timescale]
      if timescale then
        mult = timescale[0]
        if mult != 1 then
          return head_txt + "(" + delay_txt + "*#{mult}).fs\n"
        else
          return head_txt + delay_txt + ".fs\n"
        end
      else
        # By default use nanoseconds
        return delay_txt + ".ns\n"
      end
    end

  end
end
