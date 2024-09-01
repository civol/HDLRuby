# A set of tools for parsing Verilog generati

module VerilogTools

  # A very basic AST representing the parsed Verilog code.
  # Can be replaced with any other structure by redefining the hook
  # methods.
  class AST

    # Create a new AST.
    def self.[](type,*children)
      return AST.new(type,*children)
    end

    # The type of AST node (should be the name of the syntax rule).
    attr_reader :type

    # Build a new AST +type+ node with +children+.
    def initialize(type, *children)
      @type = type.to_sym
      @children = children
    end

    # Access a child by index +idx+.
    def [](idx)
      return @children[idx]
    end

    # Iterate over the children.
    def each(&ruby_block)
      # No ruby block? Return an enumerator.
      return to_enum(:each) unless ruby_block
      # A ruby block? Apply it on each children.
      @children.each(&ruby_block)
    end

    # Convert to an array of children.
    def to_a
      return self.each.to_a
    end

    # Convert to an ast string.
    def to_s
      return AST.ast_to_s(0,self)
    end

    # Convert an AST object to a string (for debug purpose mainly).
    def self.ast_to_s(adjust, obj)
      if obj.is_a?(AST) then
        return (" " * adjust) + "#{obj.type}\n" + 
          (obj.each.compact.map do |c|
            self.ast_to_s(adjust+2, c)
          end).join("\n")
      elsif obj.is_a?(Array) then
        return (" " * adjust)  + "[\n" + (obj.each.map do |c|
          self.ast_to_s(adjust+2, c)
        end).join("\n") + "\n" + (" " * adjust) + "]"
      else
        return (" " * adjust) + "<" + obj.to_s + ">"
      end
    end
  end


  # The class describing parse errors.
  class ParseError < StandardError
    
    # Create a new parse error with message +msg+, faulty line +line+
    # with number +lpos+ and column +cpos+
    def initialize(msg,line,lpos,cpos)
      @msg  = msg.to_s
      @line = line.to_s.gsub(/\t/," ")
      @lpos = lpos.to_i
      @cpos = cpos.to_i
      super(self.make_message)
    end

    # Generate the error message.
    # NOTE: if you want to translate the error message, please
    # redefine the function.
    def make_message
      return "Parse error line #{@lpos}: " + @msg + ".\n" + "#{@line}\n" +
        ("-" * (@cpos)) + "^"
    end
  end



  # The class of the parser.
  class Parser

    # Create a new parser.
    def initialize
      # Create the parse state.
      @state = Struct.new(:text,
                          :index, :prev_index,
                          # :line,  :prev_line,
                          :lpos,  :prev_lpos,
                          :cpos,  :prev_cpos).new("",0,0)
    end

    # Get the current state.
    def state
      return @state.clone
    end

    # Sets the current state.
    def state=(state)
      @state.index = state.index
      @state.prev_index = state.prev_index
      # @state.line = state.index
      @state.lpos = state.lpos
      @state.cpos = state.cpos
    end

    # Parse Verilog from text.
    def parse(text)
      # Initialize the state.
      @state.text = text
      # @state.line = ""
      # @state.prev_line = ""
      @state.index = 0
      @state.prev_index = 0
      @state.lpos = 1
      @state.prev_lpos = 1
      @state.cpos = 1
      @state.prev_cpos = 1
      # Excute the parsing.
      return self.source_text_parse
    end

    # Get the token matching regexp +rex+ if any from current position.
    # NOTE: it is assumed that rex starts with \G so that the maching
    # really starts from current position of the parser and has a single
    # capture for the token. Also assumes spaces are taken into account
    # in the regexp.
    def get_token(rex)
      # puts "get_token at index=#{@state.index} and lpos=#{@state.lpos} with rex=#{rex}"
      # puts "text line is #{@state.text.match(/\G[^\n]*/,@state.index).to_s}"
      match = @state.text.match(rex,@state.index)
      if match then
        # There is a match, get the blanks and the token
        bls = match.captures[0]
        tok = match.captures[1]
        # puts "bls=#{bls}"
        # puts "tok=#{tok}"
        # puts "match=#{match.to_s}"
        # puts "match.end(0)=#{match.end(0)}"
        # Advance the position.
        @state.prev_index = @state.index
        # @state.prev_line = @state.line
        @state.prev_lpos = @state.lpos
        @state.prev_cpos = @state.cpos
        @state.index = match.end(0)
        @state.lpos += bls.scan(/\n/).size
        spcs = bls.match(/[ \t]*\z/)
        @state.cpos = spcs.end(0) - spcs.begin(0)+tok.length
        return tok
      else
        return nil
      end
    end

    # Check is the end of file is reached (ignores the spaces and
    # comments for this check)
    def eof?
      return @state.text.match(/\G#{S}$/,@state.index) != nil
    end

    # Undo getting the previous token.
    # NOTE: effective only once after calling +get_token+
    def unget_token
      @state.index = @state.prev_index
      @state.line  = @state.prev_line
      @state.lpos  = @state.prev_lpos
      @state.cpos  = @state.prev_cpos
    end


    # Generate a parse error with message indicated by +code+
    def parse_error(msg)
      # Get the line where the error was.
      # First locate the position of the begining and the end of the line.
      blpos = @state.index-@state.cpos
      elpos = @state.index + 
        @state.text.match(/[^\n]*/,@state.index).to_s.size
      # The get the line.
      line_txt = @state.text[blpos...elpos]
      # Raise an exception containing an error message made of msg,
      # the line number , its number, and the column where error happended.
      raise ParseError.new(msg,line_txt,@state.lpos,@state.cpos)
    end
    
    # Definition of the tokens

    COMMA_TOK      = ","
    SEMICOLON_TOK  = ";"
    COLON_TOK      = ":"
    OPEN_PAR_TOK   = "("
    CLOSE_PAR_TOK  = ")"
    OPEN_BRA_TOK   = "["
    CLOSE_BRA_TOK  = "]"
    OPEN_CUR_TOK   = "{"
    CLOSE_CUR_TOK  = "}"
    SHARP_TOK      = "#"
    AT_TOK         = "@"
    DOT_TOK        = "."
    EE_TOK         = "E"
    Ee_TOK         = "e"

    SLASH_SLASH_TOK    = "//"
    SLASH_ASTERISK_TOK = "/*"
    ASTERISK_SLASH_TOK = "*/"
    EOL_TOK            = "\n"

    MODULE_TOK     = "module"
    MACROMODULE_TOK= "macromodule"
    ENDMODULE_TOK  = "endmodule"
    PRIMITIVE_TOK  = "primitive"
    ENDPRIMITIVE_TOK= "endprimitive"
    TASK_TOK       = "task"
    ENDTASK_TOK    = "endtask"
    FUNCTION_TOK   = "function"
    ENDFUNCTION_TOK= "endfunction"
    TABLE_TOK      = "table"
    ENDTABLE_TOK   = "endtable"
    SPECIFY_TOK    = "specify"
    ENDSPECIFY_TOK = "endspecify"

    INPUT_TOK      = "input"
    OUTPUT_TOK     = "output"
    INOUT_TOK      = "inout"

    INITIAL_TOK    = "initial"
    SPECPARAM_TOK  = "specparam"

    IF_TOK         = "if"
    ELSE_TOK       = "else"
    CASE_TOK       = "case"
    CASEZ_TOK      = "casez"
    CASEX_TOK      = "casex"
    ENDCASE_TOK    = "endcase"
    FOREVER_TOK    = "forever"
    REPEAT_TOK     = "repeat"
    WHILE_TOK      = "while"
    FOR_TOK        = "for"
    WAIT_TOK       = "wait"
    RIGHT_ARROW_TOK= "->"
    DISABLE_TOK    = "disable"
    ASSIGN_TOK     = "assign"
    DEASSIGN_TOK   = "deassign"
    FORCE_TOK      = "force"
    RELEASE_TOK    = "release"
    ALWAYS_TOK     = "always"
    DEFAULT_TOK    = "default"
    BEGIN_TOK      = "begin"
    END_TOK        = "end"
    FORK_TOK       = "fork"
    JOIN_TOK       = "join"

    REG_TOK        = "reg"
    TIME_TOK       = "time"
    INTEGER_TOK    = "integer"
    REAL_TOK       = "real"
    EVENT_TOK      = "event"
    DEFPARAM_TOK   = "defparam"
    PARAMETER_TOK  = "parameter"
    SCALARED_TOK   = "scalared"
    VECTORED_TOK   = "vectored"

    SETUP_TOK      = "$setup"
    HOLD_TOK       = "$hold"
    PERIOD_TOK     = "$period"
    WIDTH_TOK      = "$width"
    SKEW_TOK       = "$skew"
    RECOVERY_TOK   = "$recovery"
    SETUPHOLD_TOK  = "$setuphold"

    ZERO_TOK       = "0"
    ONE_TOK        = "1"
    Xx_TOK         = "x"
    XX_TOK         = "X"
    Bb_TOK         = "b"
    BB_TOK         = "B"
    QUESTION_TOK   = "?"
    Rr_TOK         = "r"
    RR_TOK         = "R"
    Ff_TOK         = "f"
    FF_TOK         = "F"
    Pp_TOK         = "p"
    PP_TOK         = "P"
    Nn_TOK         = "n"
    NN_TOK         = "N"
    ASTERISK_TOK   = "*"

    Q_b_TOK        = "'b"
    Q_B_TOK        = "'B"
    Q_o_TOK        = "'o"
    Q_O_TOK        = "'O"
    Q_d_TOK        = "'d"
    Q_D_TOK        = "'D"
    Q_h_TOK        = "'h"
    Q_H_TOK        = "'H"

    ONE_b_ZERO_TOK = "1'b0"
    ONE_b_ONE_TOK  = "1'b1"
    ONE_b_x_TOK    = "1'bx"
    ONE_b_X_TOK    = "1'bX"
    ONE_B_ZERO_TOK = "1'B0"
    ONE_B_ONE_TOK  = "1'B1"
    ONE_B_x_TOK    = "1'Bx"
    ONE_B_X_TOK    = "1'BX"

    Q_b_ZERO_TOK = "'b0"
    Q_b_ONE_TOK  = "'b1"
    Q_B_ZERO_TOK = "'B0"
    Q_B_ONE_TOK  = "'B1"

    WIRE_TOK       = "wire"
    TRI_TOK        = "tri"
    TRI1_TOK       = "tri1"
    SUPPLY0_TOK    = "supply0"
    WAND_TOK       = "wand"
    TRIAND_TOK     = "triand"
    TRI0_TOK       = "tri0"
    SUPPLY1_TOK    = "supply1"
    WOR_TOK        = "wor"
    TRIOR_TOK      = "trior"
    TRIREG_TOK     = "trireg"

    SMALL_TOK      = "small"
    MEDIUM_TOK     = "medium"
    LARGE_TOK      = "large"

    STRONG0_TOK    = "strong0"
    PULL0_TOK      = "pull0"
    WEAK0_TOK      = "weak0"
    HIGHZ0_TOK     = "highz0"
    STRONG1_TOK    = "strong1"
    PULL1_TOK      = "pull1"
    WEAK1_TOK      = "weak1"
    HIGHZ1_TOK     = "highz1"

    GATE_AND_TOK        = "and"
    GATE_NAND_TOK       = "nand"
    GATE_OR_TOK         = "or"
    GATE_NOR_TOK        = "nor"
    GATE_XOR_TOK        = "xor"
    GATE_XNOR_TOK       = "xnor"
    GATE_BUF_TOK        = "buf"
    GATE_BUFIF0_TOK     = "bufif0"
    GATE_BUFIF1_TOK     = "bufif1"
    GATE_NOT_TOK        = "not"
    GATE_NOTIF0_TOK     = "notif0"
    GATE_NOTIF1_TOK     = "notif1"
    GATE_PULLDOWN_TOK   = "pulldown"
    GATE_PULLUP_TOK     = "pullup"
    GATE_NMOS_TOK       = "nmos"
    GATE_RNMOS_TOK      = "rnmos"
    GATE_PMOS_TOK       = "pmos"
    GATE_RPMOS_TOK      = "rpmos"
    GATE_CMOS_TOK       = "cmos"
    GATE_RCMOS_TOK      = "rcmos"
    GATE_TRAN_TOK       = "tran"
    GATE_RTRAN_TOK      = "rtran"
    GATE_TRANIF0_TOK    = "tranif0"
    GATE_RTRANIF0_TOK   = "rtranif0"
    GATE_TRANIF1_TOK    = "tranif1"
    GATE_RTRANIF1_TOK   = "rtranif1"

    ZERO_ONE_TOK   = "01"
    ONE_ZERO_TOK   = "10"
    ZERO_X_TOK     = "0x"
    X_ONE_TOK      = "x1"
    ONE_X_TOK      = "1x"
    X_ZERO_TOK     = "x0"

    POSEDGE_TOK    = "posedge"
    NEGEDGE_TOK    = "negedge"
    EVENT_OR_TOK   = "or"

    EQUAL_TOK             = "="
    ASSIGN_ARROW_TEX      = "<="

    EQUAL_EQUAL_TOK       = "=="
    EQUAL_EQUAL_EQUAL_TOK = "==="
    NOT_EQUAL_TOK         = "!="
    NOT_EQUAL_EQUAL_TOK   = "!=="
    INFERIOR_TOK          = "<"
    SUPERIOR_TOK          = ">"
    INFERIOR_EQUAL_TOK    = "<="
    SUPERIOR_EQUAL_TOK    = ">="

    AND_AND_TOK           = "&&"
    OR_OR_TOK             = "||"
    NOT_TOK               = "!"

    AND_AND_AND_TOK       = "&&&"

    ADD_TOK   = "+"
    SUB_TOK   = "-"
    MUL_TOK   = "*"
    DIV_TOK   = "/"
    MOD_TOK   = "%"
    POWER_TOK = "**"
    AND_TOK   = "&"
    OR_TOK    = "|"
    XOR_TOK   = "^"
    XOR_TILDE_TOK   = "^~"
    RIGHT_SHIFT_TOK = ">>"
    LEFT_SHIFT_TOK  = "<<"
    RIGHT_ASHIFT_TOK= ">>>"
    LEFT_ASHIFT_TOK = "<<<"

    TILDE_TOK     = "~"
    TILDE_AND_TOK = "~&"
    XOR_OR_TOK    = "^|"
    TILDE_XOR_TOK = "~^"
    TILDE_OR_TOK = "~|"

    # The corresponding regular expressions.
    

    SHORT_COMMENT_REX = /[^\n]*/
    LONG_COMMENT_REX  = /([^\*]\/|\*[^\/]|[^\/\*])*/

    # Comments and spaces with capture in one regular expression
    COMMENT_SPACE_REX = /((?:(?:\/\/[^\n]*)|(?:\/\*(?:[^\*]\/|\*[^\/]|[^\/\*])*\*\/)|\s)*)/
    # Shortcut for combining with other regex
    S = COMMENT_SPACE_REX.source
    
     
    COMMA_REX      = /\G#{S}(,)/
    SEMICOLON_REX  = /\G#{S}(;)/
    COLON_REX      = /\G#{S}(:)/
    OPEN_PAR_REX   = /\G#{S}(\()/
    CLOSE_PAR_REX  = /\G#{S}(\))/
    OPEN_BRA_REX   = /\G#{S}(\[)/
    CLOSE_BRA_REX  = /\G#{S}(\])/
    OPEN_CUR_REX   = /\G#{S}(\{)/
    CLOSE_CUR_REX  = /\G#{S}(\})/
    SHARP_REX      = /\G#{S}(#)/
    AT_REX         = /\G#{S}(@)/
    DOT_REX        = /\G#{S}(\.)/
    EE_REX         = /\G#{S}(E)/
    Ee_REX         = /\G#{S}(e)/

    SLASH_SLASH_REX    = /\G#{S}(\/\/)/
    SLASH_ASTERISK_REX = /\G#{S}(\/\*)/
    ASTERISK_SLASH_REX = /\G#{S}(\*\/)/
    EOL_REX            = /\G#{S}(\n)/

    MODULE_REX     = /\G#{S}(module)/
    MACROMODULE_REX= /\G#{S}(macromodule)/
    ENDMODULE_REX  = /\G#{S}(endmodule)/
    PRIMITIVE_REX  = /\G#{S}(primitive)/
    ENDPRIMITIVE_REX=/\G#{S}(endprimitive)/
    TASK_REX       = /\G#{S}(task)/
    ENDTASK_REX    = /\G#{S}(endtask)/
    FUNCTION_REX   = /\G#{S}(function)/
    ENDFUNCTION_REX= /\G#{S}(endfunction)/
    TABLE_REX       = /\G#{S}(table)/
    ENDTABLE_REX    = /\G#{S}(endtable)/
    SPECIFY_REX     = /\G#{S}(specify)/
    ENDSPECIFY_REX  =/\G#{S}(endspecify)/

    INPUT_REX      = /\G#{S}(input)/
    OUTPUT_REX     = /\G#{S}(output)/
    INOUT_REX      = /\G#{S}(inout)/

    INITIAL_REX    = /\G#{S}(initial)/
    SPECPARAM_REX  = /\G#{S}(specparam)/

    IF_REX         = /\G#{S}(if)/
    ELSE_REX       = /\G#{S}(else)/
    CASE_REX       = /\G#{S}(case)/
    CASEZ_REX      = /\G#{S}(casez)/
    CASEX_REX      = /\G#{S}(casex)/
    ENDCASE_REX    = /\G#{S}(endcase)/
    FOREVER_REX    = /\G#{S}(forever)/
    REPEAT_REX     = /\G#{S}(repeat)/
    WHILE_REX      = /\G#{S}(while)/
    FOR_REX        = /\G#{S}(for)/
    WAIT_REX       = /\G#{S}(wait)/
    RIGHT_ARROW_REX= /\G#{S}(->)/
    DISABLE_REX    = /\G#{S}(disable)/
    ASSIGN_REX     = /\G#{S}(assign)/
    DEASSIGN_REX   = /\G#{S}(deassign)/
    FORCE_REX      = /\G#{S}(force)/
    RELEASE_REX    = /\G#{S}(release)/
    ALWAYS_REX     = /\G#{S}(always)/
    DEFAULT_REX    = /\G#{S}(default)/
    BEGIN_REX      = /\G#{S}(begin)/
    END_REX        = /\G#{S}(end)/
    FORK_REX       = /\G#{S}(fork)/
    JOIN_REX       = /\G#{S}(join)/

    REG_REX        = /\G#{S}(reg)/
    TIME_REX       = /\G#{S}(time)/
    INTEGER_REX    = /\G#{S}(integer)/
    REAL_REX       = /\G#{S}(real)/
    EVENT_REX      = /\G#{S}(event)/
    DEFPARAM_REX   = /\G#{S}(defparam)/
    PARAMETER_REX  = /\G#{S}(parameter)/
    SCALARED_REX   = /\G#{S}(scalared)/
    VECTORED_REX   = /\G#{S}(vectored)/


    SETUP_REX      = /\G#{S}($setup)/
    HOLD_REX       = /\G#{S}($hold)/
    PERIOD_REX     = /\G#{S}($period)/
    WIDTH_REX      = /\G#{S}($width)/
    SKEW_REX       = /\G#{S}($skew)/
    RECOVERY_REX   = /\G#{S}($recovery)/
    SETUPHOLD_REX  = /\G#{S}($setuphold)/

    ZERO_REX       = /\G#{S}(0)/
    ONE_REX        = /\G#{S}(1)/
    Xx_REX         = /\G#{S}(x)/
    XX_REX         = /\G#{S}(X)/
    Bb_REX         = /\G#{S}(b)/
    BB_REX         = /\G#{S}(B)/
    QUESTION_REX   = /\G#{S}(\?)/
    Rr_REX         = /\G#{S}(r)/
    RR_REX         = /\G#{S}(R)/
    Ff_REX         = /\G#{S}(f)/
    FF_REX         = /\G#{S}(F)/
    Pp_REX         = /\G#{S}(p)/
    PP_REX         = /\G#{S}(P)/
    Nn_REX         = /\G#{S}(n)/
    NN_REX         = /\G#{S}(N)/
    ASTERISK_REX   = /\G#{S}(\*)/

    Q_b_REX        = /\G#{S}('b)/
    Q_B_REX        = /\G#{S}('B)/
    Q_o_REX        = /\G#{S}('o)/
    Q_O_REX        = /\G#{S}('O)/
    Q_d_REX        = /\G#{S}('d)/
    Q_D_REX        = /\G#{S}('D)/
    Q_h_REX        = /\G#{S}('h)/
    Q_H_REX        = /\G#{S}('H)/

    ONE_b_ZERO_REX = /\G#{S}(1'b0)/
    ONE_b_ONE_REX  = /\G#{S}(1'b1)/
    ONE_b_x_REX    = /\G#{S}(1'bx)/
    ONE_b_X_REX    = /\G#{S}(1'bX)/
    ONE_B_ZERO_REX = /\G#{S}(1'B0)/
    ONE_B_ONE_REX  = /\G#{S}(1'B1)/
    ONE_B_x_REX    = /\G#{S}(1'Bx)/
    ONE_B_X_REX    = /\G#{S}(1'BX)/

    Q_b_ZERO_REX = /\G#{S}('b0)/
    Q_b_ONE_REX  = /\G#{S}('b1)/
    Q_B_ZERO_REX = /\G#{S}('B0)/
    Q_B_ONE_REX  = /\G#{S}('B1)/

    WIRE_REX       = /\G#{S}(wire)/
    TRI_REX        = /\G#{S}(tri)/
    TRI1_REX       = /\G#{S}(tri1)/
    SUPPLY0_REX    = /\G#{S}(supply0)/
    WAND_REX       = /\G#{S}(wand)/
    TRIAND_REX     = /\G#{S}(triand)/
    TRI0_REX       = /\G#{S}(tri0)/
    SUPPLY1_REX    = /\G#{S}(supply1)/
    WOR_REX        = /\G#{S}(wor)/
    TRIOR_REX      = /\G#{S}(trior)/
    TRIREG_REX     = /\G#{S}(trireg)/

    SMALL_REX      = /\G#{S}(small)/
    MEDIUM_REX     = /\G#{S}(medium)/
    LARGE_REX      = /\G#{S}(large)/

    STRONG0_REX    = /\G#{S}(strong0)/
    PULL0_REX      = /\G#{S}(pull0)/
    WEAK0_REX      = /\G#{S}(weak0)/
    HIGHZ0_REX     = /\G#{S}(highz0)/
    STRONG1_REX    = /\G#{S}(strong1)/
    PULL1_REX      = /\G#{S}(pull1)/
    WEAK1_REX      = /\G#{S}(weak1)/
    HIGHZ1_REX     = /\G#{S}(highz1)/

    GATE_AND_REX        = /\G#{S}(and)/
    GATE_NAND_REX       = /\G#{S}(nand)/
    GATE_OR_REX         = /\G#{S}(or)/
    GATE_NOR_REX        = /\G#{S}(nor)/
    GATE_XOR_REX        = /\G#{S}(xor)/
    GATE_XNOR_REX       = /\G#{S}(xnor)/
    GATE_BUF_REX        = /\G#{S}(buf)/
    GATE_NBUF_REX       = /\G#{S}(nbuf)/
    GATE_NOT_REX        = /\G#{S}(not)/
    GATE_NOTIF0_REX     = /\G#{S}(notif0)/
    GATE_NOTIF1_REX     = /\G#{S}(notif1)/
    GATE_PULLDOWN_REX   = /\G#{S}(pulldown)/
    GATE_PULLUP_REX     = /\G#{S}(pullup)/
    GATE_NMOS_REX       = /\G#{S}(nmos)/
    GATE_RNMOS_REX      = /\G#{S}(rnmos)/
    GATE_PMOS_REX       = /\G#{S}(pmos)/
    GATE_RPMOS_REX      = /\G#{S}(rpmos)/
    GATE_CMOS_REX       = /\G#{S}(cmos)/
    GATE_RCMOS_REX      = /\G#{S}(rcmos)/
    GATE_TRAN_REX       = /\G#{S}(tran)/
    GATE_RTRAN_REX      = /\G#{S}(rtran)/
    GATE_TRANIF0_REX    = /\G#{S}(tranif0)/
    GATE_RTRANIF0_REX   = /\G#{S}(rtranif0)/
    GATE_TRANIF1_REX    = /\G#{S}(tranif1)/
    GATE_RTRANIF1_REX   = /\G#{S}(rtranif1)/

    ZERO_ONE_REX   = /\G#{S}(01)/
    ONE_ZERO_REX   = /\G#{S}(10)/
    ZERO_X_REX     = /\G#{S}(0x)/
    X_ONE_REX      = /\G#{S}(x1)/
    ONE_X_REX      = /\G#{S}(1x)/
    X_ZERO_REX     = /\G#{S}(x0)/

    POSEDGE_REX    = /\G#{S}(posedge)/
    NEGEDGE_REX    = /\G#{S}(negedge)/
    EVENT_OR_REX   = /\G#{S}(or)/

    EQUAL_REX             = /\G#{S}(=)/
    ASSIGN_ARROW_REX      = /\G#{S}(<=)/

    EQUAL_EQUAL_REX       = /\G#{S}(==)/
    EQUAL_EQUAL_EQUAL_REX = /\G#{S}(===)/
    NOT_EQUAL_REX         = /\G#{S}(!=)/
    NOT_EQUAL_EQUAL_REX   = /\G#{S}(!==)/
    INFERIOR_REX          = /\G#{S}(<)/
    SUPERIOR_REX          = /\G#{S}(>)/
    INFERIOR_EQUAL_REX    = /\G#{S}(<=)/
    SUPERIOR_EQUAL_REX    = /\G#{S}(>=)/

    AND_AND_REX           = /\G#{S}(&&)/
    OR_OR_REX             = /\G#{S}(\|\|)/
    NOT_REX               = /\G#{S}(!)/

    AND_AND_AND_REX       = /\G#{S}(&&&)/

    ADD_REX       = /\G#{S}(\+)/
    SUB_REX       = /\G#{S}(-)/
    MUL_REX       = /\G#{S}(\*)/
    DIV_REX       = /\G#{S}(\/)/
    MOD_REX       = /\G#{S}(%)/
    POWER_REX     = /\G#{S}(\*\*)/
    AND_REX       = /\G#{S}(&)/
    OR_REX        = /\G#{S}(\|)/
    XOR_REX       = /\G#{S}(\^)/
    XOR_TILDE_REX = /\G#{S}(\^~)/

    TILDE_REX     = /\G#{S}(~)/
    TILDE_AND_REX = /\G#{S}(~&)/
    XOR_OR_REX    = /\G#{S}(\^|)/
    TILDE_XOR_REX = /\G#{S}(~\^)/
    TILDE_OR_REX  = /\G#{S}(~\|)/

    IDENTIFIER_REX        = /\G#{S}([_a-zA-Z][_\$0-9a-zA-Z]*)/
    SYSTEM_IDENTIFIER_REX = /\G#{S}(\$[_a-zA-Z][_\$0-9a-zA-Z]*)/

    STRING_REX = /\G#{S}("[^"\n]*")/
    

    # Definition of the groups of tokens and corresponding regular
    # expressions.
    
    MODULE_MACROMODULE_TOKS = [ MODULE_TOK, MACROMODULE_TOK ]
    MODULE_MACROMODULE_REX  = /\G#{S}(#{MODULE_MACROMODULE_TOKS.join("|")})/
    

    INIT_VAL_TOKS = [ ONE_b_ZERO_TOK, ONE_b_ONE_TOK,
                      ONE_b_x_TOK, ONE_b_X_TOK,
                      ONE_B_ZERO_TOK, ONE_B_ONE_TOK, 
                      ONE_B_x_TOK, ONE_B_X_TOK,
                      ONE_TOK, ZERO_TOK ]
    INIT_VAL_REX = /\G#{S}(#{INIT_VAL_TOKS.join("|")})/

    OUTPUT_SYMBOL_TOKS = [ ZERO_TOK, ONE_TOK, Xx_TOK, XX_TOK ]
    OUTPUT_SYMBOL_REX = /\G#{S}(#{OUTPUT_SYMBOL_TOKS.join("|")})/

    LEVEL_SYMBOL_TOKS  = [ ZERO_TOK, ONE_TOK, Xx_TOK, XX_TOK, 
                           "\\" + QUESTION_TOK, Bb_TOK, BB_TOK ]
    LEVEL_SYMBOL_REX = /\G#{S}(#{LEVEL_SYMBOL_TOKS.join("|")})/

    EDGE_SYMBOL_TOKS   = [ Rr_TOK, RR_TOK, Ff_TOK, FF_TOK, 
                           Pp_TOK, PP_TOK, Nn_TOK, NN_TOK, 
                           "\\" + ASTERISK_TOK ]
    EDGE_SYMBOL_REX = /\G#{S}(#{EDGE_SYMBOL_TOKS.join("|")})/

    INTEGER_REAL_TOKS  = [ INTEGER_TOK, REAL_TOK ]
    INTEGER_REAL_REX   = /\G#{S}(#{INTEGER_REAL_TOKS.join("|")})/

    NETTYPE_TOKS = [ WIRE_TOK, TRI_TOK, TRI1_TOK, 
                     SUPPLY0_TOK, WAND_TOK, TRIAND_TOK, TRI0_TOK, 
                     SUPPLY1_TOK, WOR_TOK, TRIOR_TOK, TRIREG_TOK ]
    NETTYPE_REX = /\G#{S}(#{NETTYPE_TOKS.join("|")})/

    CHARGE_STRENGTH_TOKS = [ SMALL_TOK, MEDIUM_TOK, LARGE_TOK ]
    CHARGE_STRENGTH_REX = /\G#{S}(#{CHARGE_STRENGTH_TOKS.join("|")})/

    STRENGTH0_TOKS = [ SUPPLY0_TOK, STRONG0_TOK, PULL0_TOK, 
                       WEAK0_TOK, HIGHZ0_TOK ]
    STRENGTH0_REX = /\G#{S}(#{STRENGTH0_TOKS.join("|")})/

    STRENGTH1_TOKS = [ SUPPLY1_TOK, STRONG1_TOK, PULL1_TOK, 
                       WEAK1_TOK, HIGHZ1_TOK ]
    STRENGTH1_REX = /\G#{S}(#{STRENGTH1_TOKS.join("|")})/

    GATETYPE_TOKS  = [ GATE_AND_TOK, GATE_NAND_TOK, 
                       GATE_OR_TOK, GATE_NOR_TOK,
                       GATE_XOR_TOK, GATE_XNOR_TOK, 
                       GATE_BUF_TOK, GATE_BUFIF0_TOK, GATE_BUFIF1_TOK,
                       GATE_NOT_TOK, GATE_NOTIF0_TOK, GATE_NOTIF1_TOK,
                       GATE_PULLDOWN_TOK, GATE_PULLUP_TOK,
                       GATE_NMOS_TOK, GATE_RNMOS_TOK, 
                       GATE_PMOS_TOK, GATE_RPMOS_TOK,
                       GATE_CMOS_TOK, GATE_RCMOS_TOK,
                       GATE_TRAN_TOK, GATE_RTRAN_TOK, 
                       GATE_TRANIF0_TOK, GATE_RTRANIF0_TOK, 
                       GATE_TRANIF1_TOK, GATE_RTRANIF1_TOK ]
    GATETYPE_REX = /\G#{S}(#{GATETYPE_TOKS.join("|")})/

    COMMA_CLOSE_PAR_TOKS = [ COMMA_TOK, "\\" + CLOSE_PAR_TOK ]
    COMMA_CLOSE_PAR_REX = /\G#{S}(#{COMMA_CLOSE_PAR_TOKS.join("|")})/

    CLOSE_BRA_COLON_TOKS = [ "\\" + CLOSE_BRA_TOK, COLON_TOK ]
    CLOSE_BRA_COLON_REX  = /\G#{S}(#{CLOSE_BRA_COLON_TOKS.join("|")})/

    STATEMENT_TOKS = [ IF_TOK, CASE_TOK, CASEZ_TOK, CASEX_TOK, 
                       FOREVER_TOK, REPEAT_TOK, WHILE_TOK, FOR_TOK,
                       WAIT_TOK, RIGHT_ARROW_TOK, DISABLE_TOK,
                       ASSIGN_TOK, FORCE_TOK, DEASSIGN_TOK, RELEASE_TOK ]
    STATEMENT_REX = /\G#{S}(#{STATEMENT_TOKS.join("|")})/

    SYSTEM_TIMING_TOKS = [ SETUP_TOK, HOLD_TOK, PERIOD_TOK, WIDTH_TOK,
                           SKEW_TOK, RECOVERY_TOK, SETUPHOLD_TOK ]
    SYSTEM_TIMING_REX = /\G#{S}(#{SYSTEM_TIMING_TOKS.join("|")})/

    POSEDGE_NEGEDGE_TOKS = [ POSEDGE_TOK, NEGEDGE_TOK ]
    POSEDGE_NEGEDGE_REX = /\G#{S}(#{POSEDGE_NEGEDGE_TOKS.join("|")})/


    EDGE_DESCRIPTOR_TOKS = [ ZERO_ONE_TOK, ONE_ZERO_TOK,
                             ZERO_X_TOK,   X_ONE_TOK,
                             ONE_X_TOK,    X_ZERO_TOK ]
    EDGE_DESCRIPTOR_REX = /\G#{S}(#{EDGE_DESCRIPTOR_TOKS.join("|")})/

    SCALAR_TIMING_CHECK_CONDITION_TOKS = [ EQUAL_EQUAL_TOK,
                                           EQUAL_EQUAL_EQUAL_TOK,
                                           NOT_EQUAL_TOK,
                                           NOT_EQUAL_EQUAL_TOK ]
    SCALAR_TIMING_REX = /\G#{S}(#{SCALAR_TIMING_CHECK_CONDITION_TOKS.join("|")})/

    SCALAR_CONSTANT_TOKS = [ ONE_b_ZERO_TOK, ONE_b_ONE_TOK,
                             ONE_B_ZERO_TOK, ONE_B_ONE_TOK,
                             Q_b_ZERO_TOK,   Q_b_ONE_TOK,
                             Q_B_ZERO_TOK,   Q_B_ONE_TOK,
                             ONE_TOK,        ZERO_TOK ]
    SCALAR_CONSTANT_REX = /\G#{S}(#{SCALAR_CONSTANT_TOKS.join("|")})/

    POLARITY_OPERATOR_TOKS = [ "\\" + ADD_TOK, SUB_TOK ]
    POLARITY_OPERATOR_REX = /\G#{S}(#{POLARITY_OPERATOR_TOKS.join("|")})/

    EDGE_IDENTIFIER_TOKS = [ POSEDGE_TOK, NEGEDGE_TOK ]
    EDGE_IDENTIFIER_REX = /\G#{S}(#{EDGE_IDENTIFIER_TOKS.join("|")})/

    OR_OPERATOR_TOKS = [ "\\" + OR_TOK, TILDE_TOK + "\\" + OR_TOK ]
    OR_OPERATOR_REX = /\G#{S}(#{OR_OPERATOR_TOKS.join("|")})/

    XOR_OPERATOR_TOKS = [ "\\" + XOR_TOK, TILDE_TOK + "\\" + XOR_TOK ]
    XOR_OPERATOR_REX = /\G#{S}(#{XOR_OPERATOR_TOKS.join("|")})/

    AND_OPERATOR_TOKS = [ AND_TOK, TILDE_AND_TOK ]
    AND_OPERATOR_REX = /\G#{S}(#{AND_OPERATOR_TOKS.join("|")})/

    EQUAL_OPERATOR_TOKS = [ EQUAL_EQUAL_TOK, NOT_EQUAL_TOK,
                          EQUAL_EQUAL_EQUAL_TOK, NOT_EQUAL_EQUAL_TOK ]
    EQUAL_OPERATOR_REX = /\G#{S}(#{EQUAL_OPERATOR_TOKS.join("|")})/

    COMPARISON_OPERATOR_TOKS = [ INFERIOR_TOK, SUPERIOR_TOK,
                                 INFERIOR_EQUAL_TOK, SUPERIOR_EQUAL_TOK ]
    COMPARISON_OPERATOR_REX = /\G#{S}(#{COMPARISON_OPERATOR_TOKS.join("|")})/

    SHIFT_OPERATOR_TOKS = [ LEFT_SHIFT_TOK,  RIGHT_SHIFT_TOK, 
                            LEFT_ASHIFT_TOK, RIGHT_ASHIFT_TOK ]
    SHIFT_OPERATOR_REX = /\G#{S}(#{SHIFT_OPERATOR_TOKS.join("|")})/

    ADD_OPERATOR_TOKS = [ "\\" + ADD_TOK, SUB_TOK ]
    ADD_OPERATOR_REX = /\G#{S}(#{ADD_OPERATOR_TOKS.join("|")})/

    MUL_OPERATOR_TOKS = [ "\\" + MUL_TOK, DIV_TOK, MOD_TOK, 
                          "\\" + MUL_TOK + "\\" + MUL_TOK ]
    MUL_OPERATOR_REX = /\G#{S}(#{MUL_OPERATOR_TOKS.join("|")})/

    UNARY_OPERATOR_TOKS =  [ "\\" + ADD_TOK, SUB_TOK, NOT_TOK, TILDE_TOK,
                             AND_TOK, TILDE_AND_TOK, "\\" + OR_TOK, 
                             "\\" + XOR_TOK  + "\\" + OR_TOK,
                             "\\" + XOR_TOK, TILDE_TOK + "\\" + XOR_TOK ]
    UNARY_OPERATOR_REX = /\G#{S}(#{UNARY_OPERATOR_TOKS.join("|")})/

    BINARY_OPERATOR_TOKS = [ "\\" + ADD_TOK, SUB_TOK, "\\" + MUL_TOK, 
                             "\\" + DIV_TOK, MOD_TOK,
                             EQUAL_EQUAL_TOK, NOT_EQUAL_TOK,
                             EQUAL_EQUAL_EQUAL_TOK, NOT_EQUAL_EQUAL_TOK,
                             AND_AND_TOK, "\\" + OR_TOK + "\\" + OR_TOK,
                             INFERIOR_TOK, INFERIOR_EQUAL_TOK,
                             SUPERIOR_TOK, SUPERIOR_EQUAL_TOK,
                             AND_TOK, "\\" + OR_TOK, "\\" + XOR_TOK, 
                             "\\" + XOR_TILDE_TOK,
                             RIGHT_SHIFT_TOK, LEFT_SHIFT_TOK ]
    BINARY_OPERATOR_REX = /\G#{S}(#{BINARY_OPERATOR_TOKS.join("|")})/

    E_TOKS    = [ EE_TOK, Ee_TOK ]
    E_REX     = /\G#{S}(#{E_TOKS.join("|")})/

    DECIMAL_NUMBER_REX  = /\G#{S}([+-]?[0-9][_0-9]*)/
    UNSIGNED_NUMBER_REX = /\G#{S}([_0-9][0-9]*)/
    NUMBER_REX = /\G#{S}([0-9a-fA-FzZxX\?][_0-9a-fA-FzZxX\?]*)/

    BASE_TOKS = [ Q_b_TOK, Q_B_TOK, Q_o_TOK, Q_O_TOK,
                  Q_d_TOK, Q_D_TOK, Q_h_TOK, Q_H_TOK ]
    BASE_REX  = /\G#{S}(#{BASE_TOKS.join("|")})/

    # The parsing rules: obtained directly from the BNF description of
    # Verilog
    # Each rule is paired with a hook (that returns an AST node by default)
    # that can be redefined.

    RULES = {}

    # 1. Source text

    RULES[:source_text] = <<-___
<source_text>
	::= <description>*
___

    def source_text_parse
      elems = []
      cur_elem = nil
      loop do
        cur_elem = self.description_parse
        break unless cur_elem
        elems << cur_elem
      end
      return self.source_text_hook(elems)
    end

    def source_text_hook(elems)
      return AST[:source_text, elems]
    end


    RULES[:description] = <<-___
<description>
	::= <module>
	||= <UDP>
___

    def description_parse
      elem = self.module_parse
      if !elem then
        elem = self.udp_parse
      end
      if !elem then
        return nil if self.eof?
        self.parse_error("this is probably not a Verilog HDL file")
      end
      return self.description_hook(elem)
    end

    def description_hook(elem)
      return AST[:description, elem]
    end


    RULES[:module] = <<-___
<module>
	::= module <name_of_module> <list_of_ports>? ;
		<module_item>*
		endmodule
	||= macromodule <name_of_module> <list_of_ports>? ;
		<module_item>*
		endmodule
___

    def module_parse
      if self.get_token(MODULE_MACROMODULE_REX) then
        name = self.name_of_module_parse
        ports = self.list_of_ports_parse
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        elems = []
        cur_elem = nil
        loop do
          cur_elem = self.module_item_parse
          break unless cur_elem
          elems << cur_elem
        end
        self.parse_error("'endmodule' expected") unless self.get_token(ENDMODULE_REX)
        return module_hook(name,ports,elems)
      else
        return nil
      end
    end

    def module_hook(name,ports,elems)
      return AST[:module, name,ports,elems]
    end



    RULES[:name_of_module] = <<-___
<name_of_module>
	::= <IDENTIFIER>
___

    def name_of_module_parse
      name = self._IDENTIFIER_parse
      self.parse_error("module name identifier expected") if !name
      return self.name_of_module_hook(name)
    end

    def name_of_module_hook(name)
      return AST[:name_of_module, name]
    end


    RULES[:list_of_ports] = <<-___
<list_of_ports>
	::= ( <port> <,<port>>* )
___

    def list_of_ports_parse
      if self.get_token(OPEN_PAR_REX) then
        cur_port = self.port_parse
        ports = [ cur_port ]
        loop do
          if self.get_token(COMMA_REX) then
            cur_port = self.port_parse
          else
            if self.get_token(CLOSE_PAR_REX) then
              cur_port = nil
            else
              self.parse_error("comma of closing parenthesis expected")
            end
          end
          break unless cur_port
          ports << cur_port
        end
        return list_of_ports_hook(ports)
      else
        return nil
      end
    end

    def list_of_ports_hook(ports)
      return AST[:list_of_ports, ports]
    end


    RULES[:port] = <<-___
<port>
	::= <port_expression>?
	||= . <name_of_port> ( <port_expression>? )
___

    def port_parse
      port_expression = self.port_expression_parse
      if port_expression then
        return self.port_hook(port_expression,nil)
      end
      unless self.get_token(DOT_REX) then
        return nil
      end
      name_of_port = self.name_of_port_parse
      self.parse_error("name of port expected") unless name_of_port
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      port_expression = self.port_expression_parse
      self.parse_error("port expression expected") unless port_expression
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return self.port_hook(name_of_port,port_expression)
    end

    def port_hook(port_expression__name_of_port, port_expression)
      return AST[:port, port_expression__name_of_port,port_expression ]
    end


    RULES[:port_expression] = <<-___
<port_expression>
	::= <port_reference>
	||= { <port_reference> <,<port_reference>>* }
___

    def port_expression_parse
      parse_state = self.state
      port_refs = [ ]
      cur_port_ref = self.port_reference_parse
      if cur_port_ref then
        port_refs << cur_port_ref
      else
        unless self.get_token(OPEN_CUR_REX) then
          self.state = parse_state
          return nil
        end
        port_refs << cur_port_ref
        cur_port_ref = self.port_reference_parse
        if !cur_port_ref then
          self.state = parse_state
          return nil
        end
        loop do
          if self.get_token(COMMMA_REX) then
            cur_port_ref = self.port_reference_parse
          end
          if self.get_token(CLOSE_CUR_REX) then
            cur_port_ref = nil
          else
            self.parse_error("comma or closing parenthesis expected")
          end
          break unless cur_port_ref
          port_refs << cur_port_ref
        end
      end
      return self.port_expression_hook(port_refs)
    end

    def port_expression_hook(port_refs)
      return AST[:port_expression, port_refs]
    end


    RULES[:port_reference] = <<-___
<port_reference>
	::= <name_of_variable>
	||= <name_of_variable> [ <constant_expression> ]
	||= <name_of_variable> [ <constant_expression> :<constant_expression> ]
___

    def port_reference_parse
      name = self.name_of_variable_parse
      const0, const1 = nil, nil
      if self.get_token(OPEN_BRA_REX) then
        const0 = self.constant_expression_prase
        self.parse_error("constant expression expected") unless const0
        if self.get_token(COLON_REX) then
          const1 = self.constant_expression_parse
          self.parse_error("constant expression expected") unless const1
        end
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
      end
      return self.port_reference_hook(name,const0,const1)
    end

    def port_reference_hook(name,const0,const1)
      return AST[:port_reference, name,const0,const1 ]
    end


    RULES[:name_of_port] = <<-___
<name_of_port>
	::= <IDENTIFIER>
___

    def name_of_port_parse
      name = self._IDENTIFIER_parse
      self.parse_error("port name identifier expected") if !name
      return self.name_of_port_hook(name)
    end

    def name_of_port_hook(name)
      return AST[:name_of_port, name]
    end


    RULES[:name_of_variable] = <<-___
<name_of_variable>
	::= <IDENTIFIER>
___

    def name_of_variable_parse
      name = self._IDENTIFIER_parse
      self.parse_error("variable name identifier expected") if !name
      return self.name_of_variable_hook(name)
    end

    def name_of_variable_hook(name)
      return AST[:name_of_variable, name]
    end


    RULES[:module_item] = <<-___
<module_item>
	::= <parameter_declaration>
	||= <input_declaration>
	||= <output_declaration>
	||= <inout_declaration>
	||= <net_declaration>
	||= <reg_declaration>
	||= <time_declaration>
	||= <integer_declaration>
	||= <real_declaration>
	||= <event_declaration>
	||= <gate_declaration>
	||= <UDP_instantiation>
	||= <module_instantiation>
	||= <parameter_override>
	||= <continuous_assign>
	||= <specify_block>
	||= <initial_statement>
	||= <always_statement>
	||= <task>
	||= <function>
___

    def module_item_parse
      item = self.parameter_declaration_parse
      return self.module_item_hook(item) if item
      item = self.input_declaration_parse
      return self.module_item_hook(item) if item
      item = self.output_declaration_parse
      return self.module_item_hook(item) if item
      item = self.inout_declaration_parse
      return self.module_item_hook(item) if item
      item = self.net_declaration_parse
      return self.module_item_hook(item) if item
      item = self.reg_declaration_parse
      return self.module_item_hook(item) if item
      item = self.time_declaration_parse
      return self.module_item_hook(item) if item
      item = self.integer_declaration_parse
      return self.module_item_hook(item) if item
      item = self.real_declaration_parse
      return self.module_item_hook(item) if item
      item = self.event_declaration_parse
      return self.module_item_hook(item) if item
      item = self.gate_declaration_parse
      return self.module_item_hook(item) if item
      item = self.udp_instantiation_parse
      return self.module_item_hook(item) if item
      item = self.module_instantiation_parse
      return self.module_item_hook(item) if item
      item = self.parameter_override_parse
      return self.module_item_hook(item) if item
      item = self.continuous_assignment_parse
      return self.module_item_hook(item) if item
      item = self.specify_block_parse
      return self.module_item_hook(item) if item
      item = self.initial_statement_parse
      return self.module_item_hook(item) if item
      item = self.always_statement_parse
      return self.module_item_hook(item) if item
      item = self.task_parse
      return self.module_item_hook(item) if item
      item = self.function_parse
      return self.module_item_hook(item) if item
      return nil
    end

    def module_item_hook(item)
      return AST[:module_item, item]
    end


    RULES[:UDP] = <<-___
<UDP>
	::= primitive <name_of_UDP> ( <name_of_variable>
		<,<name_of_variable>>* ) ;
		<UDP_declaration>+
		<UDP_initial_statement>?
		<table_definition>
		endprimitive
___

    def udp_parse
      unless self.get_token(PRIMITIVE_REX) then
        return nil
      end
      name = self.name_of_udp_parse
      self.parse_error("name of UDP expected") unless name
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      cur_var_name = self.variable_name_parse
      self.parse_error("variable name expected") unless cur_var_name
      var_names = [ cur_var_name ]
      loop do
        if self.get_token(COMMMA_REX) then
          cur_var_name = self.variable_name_parse
        end
        if self.get_token(CLOSE_PAR_REX) then
          cur_var_name = nil
        else
          self.parse_error("comma or closing parenthesis expected")
        end
        break unless cur_var_name
        var_names << cur_var_name
      end
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      udp_declarations = []
      cur_udp_declaration = nil
      loop do
        cur_udp_declaration = self.udp_declaration_parse
        break unless cur_udp_declaration
        udp_declarations << cur_udp_declaration
      end
      self.parse_error("empty UDP declaration") if udp_declarations.empty? # udp_declaration+ rule
      udp_initial_statement = self.udp_initial_statement_parse
      table_definition = self.table_definition_parse
      self.parse_error("'endprimitive' expected") unless self.get_token(ENDPRIMITIVE_REX)

      return self.udp_hook(name_of_variables,udp_declarations,
                           udp_initial_statement, table_definition)
    end

    def udp_hook(name_of_variables, udp_declarations,
                 udp_initial_statement, table_definition)
      return AST[:UDP, 
                 name_of_variables,udp_declarations,
                 udp_initial_statement,table_definition ]
    end


    RULES[:name_of_UDP] = <<-___
<name_of_UDP>
	::= <IDENTIFIER>
___

    def name_of_udp_parse
      name = self._IDENTIFIER_parse
      self.parse_error("name of UDP identifier expected") if !name
      return name_of_udp_hook(name)
    end

    def name_of_udp_hook(name)
      return AST[:name_of_UDP, name]
    end


    RULES[:UDP_declaration] = <<-___
<UDP_declaration>
	::= <output_declaration>
	||= <reg_declaration>
	||= <input_declaration>
___

    def udp_declaration_parse
      declaration = self.output_declaration_parse
      return self.udp_declaration_hook(declaration) if declaration
      declaration = self.reg_declaration_parse
      return self.udp_declaration_hook(declaration) if declaration
      declaration = self.input_declaration_parse
      return self.udp_declaration_hook(declaration) if declaration
      return nil
    end

    def udp_declaration_hook(declaration)
      return AST[:UDP_declaration, declaration]
    end


    RULES[:UDP_initial_statement] = <<-___
<UDP_initial_statement>
	::= initial <output_terminal_name> = <init_val> ;
___

    def udp_initial_statement_parse
      return nil unless self.get_token(INITIAL_REX)
      output_terminal_name = self.output_terminal_name_parse
      self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
      init_val = self.init_val_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.udp_initial_statement_hook(output_terminal_name,init_val)
    end

    def udp_initial_statement_hook(output_terminal_name,init_val)
      return AST[:UDP_initial_statement, output_terminal_name,init_val ]
    end


    RULES[:init_val] = <<-___
<init_val>
	::= 1'b0
	||= 1'b1
	||= 1'bx
	||= 1'bX
	||= 1'B0
	||= 1'B1
	||= 1'Bx
	||= 1'BX
	||= 1
	||= 0
___

    def init_val_parse
      val = self.get_token(INIT_VAL_REX)
      self.parse_error("One of [#{INIT_VAL_TOKS.join(",")}] expected") unless val
      return self.init_val_hook(val)
    end

    def init_val_hook(val)
      return AST[:init_val, val]
    end


    RULES[:output_terminal_name] = <<-___
<output_terminal_name>
	::= <name_of_variable>
___

    def output_terminal_name_parse
      name_of_variable = self.name_of_variable
      return nil unless name_of_variable
      return self.output_terminal_name_hook(name_of_variable)
    end

    def output_terminal_name_hook(name_of_variable)
      return AST[:output_terminal_name, name_of_variable]
    end


    RULES[:table_definition] = <<-___
<table_definition>
	::= table <table_entries> endtable
___

    def table_definition_parse
      unless self.get_token(TABLE_REX) then
        return nil
      end
      table_entries = self.table_entries_parse
      self.parse_error("'endtable' expected") unless self.get_token(ENDTABLE_REX)
      return self.table_definition_hook(table_entries)
    end

    def table_definition_hook(table_entries)
      return AST[:table_definition, table_entries]
    end


    RULES[:table_entries] = <<-___
<table_entries>
	::= <combinational_entry>+
	||= <sequential_entry>+
___

    def table_entries_parse
      cur_combinational_entry = self.combinational_entry_parse
      if cur_combinational_entry then
        combinational_entries = [ cur_combinational_entry ]
        loop do
          cur_combinational_entry = self.combinational_entry_parse
          break unless cur_combinational_entry
          combinational_entries << cur_combinational_entry
        end
        return table_entries_hook(combinational_entries)
      else
        cur_sequential_entry = self.sequential_entry_parse
        self.parse_error("sequential entry expected") unless cur_sequential_entry
        sequential_entries = [ cur_sequential_entry ]
        loop do
          cur_sequential_entry = self.sequential_entry_parse
          break unless cur_sequential_entry
          sequential_entries << cur_sequential_entry
        end
        return self.table_entries_hook(sequential_entries)
      end
    end

    def table_entries_hook(entries)
      return AST[:table_entries, entries]
    end


    RULES[:combinational_entry] = <<-___
<combinational_entry>
	::= <level_input_list> : <OUTPUT_SYMBOL> ;
___

    def combinational_entry_parse
      parse_parse_state = self.state
      level_input_list = self.level_input_parse
      if !level_input_list or !self.get_token(COLON_REX) then
        self.state = parse_state
        return nil
      end
      output_symbol = self._OUTPUT_SYMBOL_parse
      if !output_symbol or !self.get_token(SEMICOLON_REX) then
        self.state = parse_state
        return nil
      end
      return self.combinational_entry_hook(level_input_list,output_symbol)
    end

    def combinational_entry_hook(level_input_list, output_symbol)
      return AST[:combinational_entry, level_input_list,output_symbol ]
    end


    RULES[:sequential_entry] = <<-___
<sequential_entry>
	::= <input_list> : <state> : <next_state> ;
___

    def sequential_entry_parse
      parse_parse_state = self.state
      input_list = self.input_list_parse
      if !input_list or !self.get_token(COLON_REX) then
        self.state = parse_state
        return nil
      end
      parse_state = self.state_parse
      if !state or !self.get_token(COLON_REX) then
        self.state = parse_state
        return nil
      end
      next_state = self.next_state_parse
      if !next_state or !self.get_token(SEMICOLON_REX) then
        self.state = parse_state
        return nil
      end
      return self.sequential_entry_hook(input_list,state,next_state)
    end

    def sequential_entry_hook(input_list, state, next_state)
      return AST[:sequential_entry, input_list,state,next_state ]
    end


    RULES[:input_list] = <<-___
<input_list>
	::= <level_input_list>
	||= <edge_input_list>
___

    def input_list_parse
      input_list = self.edge_input_list_parse
      if !input_list then
        input_list = self.level_input_list_parse
        return nil unless input_list
      end
      return self.input_list_hook(input_list)
    end

    def input_list_hook(input_list)
      return AST[:input_list, input_list]
    end


    RULES[:level_input_list] = <<-___
<level_input_list>
	::= <LEVEL_SYMBOL>+
___

    def level_input_list_parse
      cur_level_symbol = self._LEVEL_SYMBOL_parse
      return nil unless cur_level_symbol
      level_symbols = [ cur_level_symbol ]
      loop do
        cur_level_symbol = self.level_symbol_parse
        rbeak unless cur_level_symbol
        level_symbols << cur_level_symbol
      end
      return self.level_input_list_hook(level_symbols)
    end

    def level_input_list_hook(level_symbols)
      return AST[:level_input_list, level_symbols]
    end


    RULES[:edge_input_list] = <<-___
<edge_input_list>
	::= <LEVEL_SYMBOL>* <edge> <LEVEL_SYMBOL>*
___

    def edge_input_list_parse
      parse_parse_state = self.state
      level_symbols0 = []
      cur_level_symbol = nil
      loop do
        cur_level_symbol = self._LEVEL_SYMBOL_parse
        break unless cur_level_symbol
        level_symbols0 << cur_level_symbol
      end
      edge = self.edge_parse
      if !edge then
        self.state = parse_state
        return nil
      end
      level_symbols1 = []
      loop do
        cur_level_symbol = self._LEVEL_SYMBOL_parse
        break unless cur_level_symbol
        level_symbols1 << cur_level_symbol
      end
      return self.edge_input_list_hook(level_symbols0,edge,level_symbols1)
    end

    def edge_input_list_hook(level_symbols0, edge, level_symbols1)
      return AST[:edge_input_list, level_symbols0,edge,level_symbols1 ]
    end


    RULES[:edge] = <<-___
<edge>
	::= ( <LEVEL_SYMBOL> <LEVEL_SYMBOL> )
	||= <EDGE_SYMBOL>
___

    def edge_parse
      if self.get_token(OPEN_PAR_REX) then
        level_symbol0 = self._LEVEL_SYMBOL_parse
        level_symbol1 = self._LEVEL_SYMBOL_parse
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        edge = [ level_symbol0,level_symbol1 ]
      else
        edge = self._EDGE_SYMBOL_parse
      end
      return self.edge_hook(edge)
    end

    def edge_hook(edge)
      return AST[:edge, edge]
    end


    RULES[:state] = <<-___
<state>
	::= <LEVEL_SYMBOL>
___

    def state_parse
      level_symbol = self._LEVEL_SYMBOL_parse
      return nil unless level_symbol
      return self.state_hook(level_symbol)
    end

    def state_hook(level_symbol)
      return AST[:state, level_symbol]
    end


    RULES[:next_state] = <<-___
<next_state>
	::= <OUTPUT_SYMBOL>
	||= - (This is a literal hyphen, see Chapter 5 for details).
___

    def next_state_parse
      if self.get_token(HYPHEN_REX) then
        return next_state_hook(HYPHEN_TOK)
      else
        output_symbol = self._OUTPUT_SYMBOL_parse
        return self.next_state_hook(output_symbol)
      end
    end

    def next_state_hook(symbol)
      return AST[:next_state, symbol]
    end


    RULES[:OUTPUT_SYMBOL] = <<-___
<OUTPUT_SYMBOL> is one of the following characters:
	0   1   x   X
___

    def _OUTPUT_SYMBOL_parse
      symbol = self.get_token(OUTPUT_SYMBOL_REX)
      return nil unless symbol
      return self._OUTPUT_SYMBOL_hook(symbol)
    end

    def _OUTPUT_SYMBOL_hook(symbol)
      return AST[:OUTPUT_SYMBOL, symbol]
    end


    RULES[:LEVEL_SYMBOL] = <<-___
<LEVEL_SYMBOL> is one of the following characters:
	0   1   x   X   ?   b   B
___

    def _LEVEL_SYMBOL_parse
      symbol = self.get_token(LEVEL_SYMBOL_REX)
      return nil unless symbol
      return self._LEVEL_SYMBOL_hook(symbol)
    end

    def _LEVEL_SYMBOL_hook(symbol)
      return AST[:LEVEL_SYMBOL, symbol]
    end


    RULES[:EDGE_SYMBOL] = <<-___
<EDGE_SYMBOL> is one of the following characters:
	r   R   f   F   p   P   n   N   *
___

    def _EDGE_SYMBOL_parse
      symbol = self.get_token(EDGE_SYMBOL_REX)
      return nil unless symbol
      return self._EDGE_SYMBOL_hook(symbol)
    end

    def _EDGE_SYMBOL_hook(symbol)
      return AST[:EDGE_SYMBOL, symbol]
    end


    RULES[:task] = <<-___
<task>
	::= task <name_of_task> ;
		<tf_declaration>*
		<statement_or_null>
		endtask
___

    def task_parse
      unless self.get_token(TASK_REX) then
        return nil
      else
        name_of_task = self.name_of_task_parse
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        tf_declarations = []
        cur_tf_declaration = nil
        loop do
          cur_tf_declaration = self.tf_declaration_parse
          break unless cur_tf_declaration
          tf_declarations << cur_tf_declaration
        end
        statement_or_null = self.statement_or_null_parse
        self.parse_error("statement or nothing expected") unless statement_or_null
        self.parse_error("'endtask' expected") unless self.get_token(ENDTASK_REX)
        return self.task_hook(name_of_task,tf_declarations,statement_or_null)
      end
    end

    def task_hook(name_of_task, tf_declaration, statement_or_null)
      return AST[:task, name_of_task,tf_declaration,statement_or_null ]
    end


    RULES[:name_of_task] = <<-___
<name_of_task>
	::= <IDENTIFIER>
___

    def name_of_task_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return self.name_of_task_hook(identifier)
    end

    def name_of_task_hook(name_of_task)
      return AST[:name_of_task, name_of_task]
    end


    RULES[:function] = <<-___
<function>
	::= function <range_or_type>? <name_of_function> ;
		<tf_declaration>+
		<statement>
		endfunction
___

    def function_parse
      unless self.get_token(FUNCTION_REX) then
        return nil
      else
        range_or_type = self.range_or_type_parse
        name_of_function = self.name_of_function_parse
        self.parse_error("name of function expected") unless self.get_token(SEMICOLON_REX)
        cur_tf_declaration = self.tf_declaration_parse
        self.parse_error("tf declaration expected") unless cur_tf_declaration
        tf_declarations = [ cur_tf_declaration ]
        loop do
          cur_tf_declaration = self.tf_declaration_parse
          break unless cur_tf_declaration
          tf_declaration << cur_tf_declaration
        end
        statement = self.statement_parse
        self.parse_error("'endfunction' expected") unless self.get_token(ENDFUNCTION_REX)
        return self.function_hook(range_or_type,name_of_function,
                                  tf_declarations,statement)
      end
    end

    def function_hook(range_or_type, name_of_function,
                      tf_declarations, statement)
      return AST[:function, 
                 range_or_type,name_of_functiom,tf_declaration,statement ]
    end


    RULES[:range_or_type] = <<-___
<range_or_type>
	::= <range>
	||= integer
	||= real
___

    def range_or_type_parse
      tok = self.get_token(INTEGER_REAL_REX)
      if tok then
        return self.range_or_type_hook(tok)
      else
        range = self.range_parse
        return nil unless range
        return self.range_or_type_hook(range)
      end
    end

    def range_or_type_hook(range_or_type)
      return AST[:range_or_type, range_or_type]
    end


    RULES[:name_of_function] = <<-___
<name_of_function>
	::= <IDENTIFIER>
___

    def name_of_function_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return self.name_of_function_hook(identifier)
    end

    def name_of_function_hook(name_of_function)
      return AST[:name_of_function, name_of_function]
    end


    RULES[:tf_declaration] = <<-___
<tf_declaration>
	::= <parameter_declaration>
	||= <input_declaration>
	||= <output_declaration>
	||= <inout_declaration>
	||= <reg_declaration>
	||= <time_declaration>
	||= <integer_declaration>
	||= <real_declaration>
___

    def tf_declaration_parse
      declaration = self.parameter_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.input_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.output_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.inout_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.reg_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.time_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.integer_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      declaration = self.real_declaration_parse
      return self.tf_declaration_hook(declaration) if declaration
      return nil
    end

    def tf_declaration_hook(declaration)
      return AST[:tf_declaration, declaration]
    end


    ## 2. Declarations


    RULES[:parameter_declaration] = <<-___
<parameter_declaration>
	::= parameter <list_of_param_assignments> ;
___

    def parameter_declaration_parse
      unless self.get_token(PARAMETER_REX) then
        return nil
      end
      list_of_param_assignments = self.list_of_param_assignments_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.parameter_declaration_hook(list_of_param_assignments)
    end

    def parameter_declaration_hook(list_of_param_assignments)
      return AST[:parameter_declaration, list_of_param_assignments]
    end


    RULES[:list_of_param_assignments] = <<-___
<list_of_param_assignments>
	::=<param_assignment><,<param_assignment>*
___

    def list_of_param_assignments_parse
      cur_param_assignment = self.param_assignment_parse
      param_assignments = [ cur_param_assignment ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_param_assignment = self.param_assignment_parse
        param_assignments << cur_param_assignment
      end
      return self.list_of_param_assignments_hook(param_assignments)
    end

    def list_of_param_assignments_hook(param_assignments)
      return AST[:list_of_param_assignments, param_assignments]
    end


    RULES[:param_assignment] = <<-___
<param_assignment>
	::=<identifier> = <constant_expression>
___

    def param_assignment_parse
      identifier = self.identifier_parse
      self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
      constant_expression = self.constant_expression_parse
      return self.param_assignment_hook(identifier,constant_expression)
    end

    def param_assignment_hook(identifier, constant_expression)
      return AST[:param_assignment, identifier,constant_expression ]
    end


    RULES[:input_declaration] = <<-___
<input_declaration>
	::= input <range>? <list_of_variables> ;
___

    def input_declaration_parse
      unless self.get_token(INPUT_REX) then
        return nil
      end
      range = self.range_parse
      list_of_variables = self.list_of_variables_parse
      self.parse_error("identifier expected") unless list_of_variables
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.input_declaration_hook(range,list_of_variables)
    end

    def input_declaration_hook(range, list_of_variables)
      return AST[:input_declaration, range,list_of_variables ]
    end


    # Auth: I think there is an error in the BNF for the output,
    # it should use its own list_of_variables rule.
    # Changed it to: list_of_output_variables.
    RULES[:output_declaration] = <<-___
<output_declaration>
	::= output <range>? <list_of_variables> ;
___

    def output_declaration_parse
      unless self.get_token(OUTPUT_REX) then
        return nil
      end
      range = self.range_parse
      # list_of_variables = self.list_of_variables_parse
      list_of_variables = self.list_of_output_variables_parse
      # Auth: semicolon included in list_of_output_variables!
      # self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.output_declaration_hook(range,list_of_variables)
    end

    def output_declaration_hook(range, list_of_variables)
      return AST[:output_declaration, range,list_of_variables ]
    end

    # Auth: rule for the variables declared in output
    # list_of_output_variables_parse
    # ::= net_declaration
    # ||= reg_declaration
    # ||= list_of_variables
    def list_of_output_variables_parse
      net_declaration = self.net_declaration_parse
      if net_declaration then
        return list_of_output_variables_hook(net_declaration)
      end
      reg_declaration = self.reg_declaration_parse
      if reg_declaration then
        return list_of_output_variables_hook(reg_declaration)
      end
      list_of_variables = self.list_of_variables_parse
      return nil unless list_of_variables
      return list_of_output_variables_hook(list_of_variables)
    end

    def list_of_output_variables_hook(list)
      return list
    end


    RULES[:inout_declaration] = <<-___
<inout_declaration>
	::= inout <range>? <list_of_variables> ;
___

    def inout_declaration_parse
      unless self.get_token(INOUT_REX) then
        return nil
      end
      range = self.range_parse
      list_of_variables = self.list_of_variables_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.inout_declaration_hook(range,list_of_variables)
    end

    def inout_declaration_hook(range, list_of_variables)
      return AST[:inout_declaration, range,list_of_variables ]
    end


    RULES[:net_declaration] = <<-___
<net_declaration>
	::= <NETTYPE> <expandrange>? <delay>? <list_of_variables> ;
	||= trireg <charge_strength>? <expandrange>? <delay>?
___

    def net_declaration_parse
      nettype = self._NETTYPE_parse
      if nettype then
        drive_strength = self.drive_strength_parse
        if !drive_strength then
          expandrange = self.expandrange_parse
          delay = self.delay_parse
          list_of_variables = self.list_of_variables_parse
          self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
          return net_declaration_hook(nettype,expandrange,delay,
                                      list_of_variables)
        else
          expandrange = self.expandrange_parse
          delay = self.delay_parse
          list_of_assignments = self.list_of_assignments_parse
          self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
          return net_declaration_hook(nettype,expandrange,delay,
                                      list_of_assignments)
        end
      else
        unless self.get_token(TRIREG_REX) then
          return nil
        end
        charge_strength = self.charge_strength_parse
        expandrange = self.expandrange_parse
        delay = self.delay_parse
        list_of_variables = self.list_of_variables_parse
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return net_declaration_hook(charge_strength,expandrange,delay,
                                    list_of_variables)
      end
    end

    def net_declaration_hook(nettype_or_charge_strength, 
                             expandrange, delay,
                             list_of_variables_or_list_of_assignments)
      return AST[:net_declaration, 
                 nettype_or_charge_strength,expandrange,delay,
                 list_of_variables_or_list_of_assignments ]
    end


    # Auth: this rule overides the list_of_variables, and is
    # not refered anywhere in the BNF, maybe it is a mistake.
    
    # RULES[:list_of_variables] = <<-___
    # list_of_variables> ;
    # ||= <NETTYPE> <drive_strength>? <expandrange>? <delay>? <list_of_assignments> ;
    # ___

    # def list_of_variables_parse
    #   return nil if self.get_token(SEMICOLON_REX)
    #   nettype = self._NETTYPE_parse
    #   drive_strength = self.drive_strength_parse
    #   expandrange = self.expandrange_parse
    #   delay = self.delay_parse
    #   list_of_assignments = self.list_of_assignments_parse
    #   self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
    #   return self.list_of_output_variables_hook(nettype,drive_strength,
    #                                             expandrange,
    #                                             delay,list_of_assignments)
    # end

    # def list_of_variables_hook(nettype, drive_strength, expandrange,
    #                            delay, list_of_assignments)
    #   return AST[:list_of_output_variables,
    #              nettype,drive_strength,expandrange,delay,
    #              list_of_assignments ]
    # end


    # Auth: I think NETTYPE should also include 'reg', so added
    # (see NETTYPE_TOKS)
    RULES[:NETTYPE] = <<-___
<NETTYPE> is one of the following keywords:
	wire  tri  tri1  supply0  wand  triand  tri0  supply1  wor  trior  trireg
___

    def _NETTYPE_parse
      type = self.get_token(NETTYPE_REX)
      return nil unless type
      # self.parse_error("one of [#{NETTYPE_TOKS.join(",")}] expected") unless type
      return self._NETTYPE_hook(type)
    end

    def _NETTYPE_hook(type)
      return AST[:NETTYPE, type]
    end


    RULES[:expandrange] = <<-___
<expandrange>
	::= <range>
	||= scalared <range>
	||= vectored <range>
___

    def expandrange_parse
      if self.get_token(SCALARED_REX) then
        range = self.range_parse
        self.parse_error("range expected") unless range
        return expandrange_hook(SCALARED_TOK.to_sym, range)
      end
      if self.get_token(VECTORED_REX) then
        range = self.range_parse
        self.parse_error("range expected") unless range
        return expandrange_hook(VECTORED_TOK.to_sym, range)
      end
      range = self.range_parse
      self.parse_error("range expected") unless range
      return expandrange_hook(:"", range)
    end

    def expandrange_hook(type, range)
      return AST[:expandrange, type,range ]
    end


    RULES[:reg_declaration] = <<-___
<reg_declaration>
	::= reg <range>? <list_of_register_variables> ;
___

    def reg_declaration_parse
      unless self.get_token(REG_REX) then
        return nil
      end
      range = self.range_parse
      list_of_register_variables = self.list_of_register_variables_parse
      self.parse_error("semicolon exptected") unless self.get_token(SEMICOLON_REX)
      return reg_declaration_hook(range,list_of_register_variables)
    end

    def reg_declaration_hook(range, list_of_register_variables)
      return AST[:reg_declaration, range,list_of_register_variables ]
    end


    RULES[:time_declaration] = <<-___
<time_declaration>
	::= time <list_of_register_variables> ;
___

    def time_declaration_parse
      unless self.get_token(TIME_REX) then
        return nil
      end
      list_of_register_variables = self.list_of_register_variables_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return time_declaration_hook(list_of_register_variables)
    end

    def time_declaration_hook(list_of_register_variables)
      return AST[:time_declaration, list_of_register_variables]
    end


    RULES[:integer_declaration] = <<-___
<integer_declaration>
	::= integer <list_of_register_variables> ;
___

    def integer_declaration_parse
      unless self.get_token(INTEGER_REX) then
        return nil
      end
      list_of_register_variables = self.list_of_register_variables_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return integer_declaration_hook(list_of_register_variables)
    end

    def integer_declaration_hook(list_of_register_variables)
      return AST[:integer_declaration, list_of_register_variables]
    end
   

    RULES[:real_declaration] = <<-___
<real_declaration>
	::= real <list_of_variables> ;
___

    def real_declaration_parse
      unless self.get_token(REAL_REX) then
        return nil
      end
      list_of_register_variables = self.list_of_register_variables_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return real_declaration_hook(list_of_register_variables)
    end

    def real_declaration_hook(list_of_register_variables)
      return AST[:real_declaration, list_of_register_variables]
    end


    RULES[:event_declaration] = <<-___
<event_declaration>
	::= event <name_of_event> <,<name_of_event>>* ;
___

    def event_declaration_parse
      unless self.get_token(EVENT_REX) then
        return nil
      end
      cur_name_of_event = self.name_of_event_parse
      name_of_events = [ cur_name_of_event ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_name_of_event = self.name_of_event_parse
        name_of_events << cur_name_of_event
      end
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return event_declaration_hook(name_of_events)
    end

    def event_declaration_hook(name_of_events)
      return AST[:event_declaration, name_of_events]
    end


    RULES[:continuous_assignment] = <<-___
<continuous_assign>
	::= assign <drive_strength>? <delay>? <list_of_assignments> ;
	||= <NETTYPE> <drive_strength>? <expandrange>? <delay>? <list_of_assignments> ;
___

    def continuous_assignment_parse
      if self.get_token(ASSIGN_REX) then
        drive_strength = self.drive_strength_parse
        delay = self.delay_parse
        list_of_assignments = self.list_of_assignments_parse
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return continuous_assignment_hook(ASSIGN_TOK,
                                          drive_strength,nil,
                                          delay,list_of_assignments)
      else
        nettype = self._NETTYPE_parse
        return nil unless nettype
        drive_strength = self.drive_strength_parse
        expandrange = self.expandrange_parse
        delay = self.delay_parse
        list_of_assignments = self.list_of_assignments_parse
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return continuous_assignment_hook(nettype,
                                          drive_strength,expandrange,
                                          delay,list_of_assignments)
      end
    end

    def continuous_assignment_hook(nettype, drive_strength, expandrange,
                                   delay, list_of_assignments)
      return AST[:continuous_assignment, 
                 nettype,drive_strength,expandrange,delay,
                 list_of_assignments ]
    end


    RULES[:parameter_override] = <<-___
<parameter_override>
	::= defparam <list_of_param_assignments> ;
___

    def parameter_override_parse
      unless self.get_token(DEFPARAM_REX) then
        return nil
      end
      list_of_param_assignments = self.list_of_param_assignments_parse
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return parameter_override_hook(list_of_param_assignments)
    end

    def parameter_override_hook(list_of_param_assignments)
      return AST[:parameter_override, list_of_param_assignments]
    end


    RULES[:list_of_variables] = <<-___
<list_of_variables>
	::= <name_of_variable> <,<name_of_variable>>*
___

    def list_of_variables_parse
      cur_name_of_variable = self.name_of_variable_parse
      name_of_variables = [ cur_name_of_variable ]
      loop do
        unless self.get_token(COMMA_REX)
          break
        end
        cur_name_of_variable = self.name_of_variable_parse
        name_of_variables << cur_name_of_variable
      end
      return list_of_variables_hook(name_of_variables)
    end

    def list_of_variables_hook(name_of_variables)
      return AST[:list_of_variables, name_of_variables]
    end


    RULES[:name_of_variable] = <<-___
<name_of_variable>
	::= <IDENTIFIER>
___

    def name_of_variable_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return name_of_variable_hook(identifier)
    end

    def name_of_variable_hook(identifier)
      return AST[:name_of_variable, identifier]
    end


    RULES[:list_of_register_variables] = <<-___
<list_of_register_variables>
	::= <register_variable> <,<register_variable>>*
___

    def list_of_register_variables_parse
      cur_register_variable = self.register_variable_parse
      register_variables = [ cur_register_variable ]
      loop do
        unless self.get_token(COMMA_REX)
          break
        end
        cur_register_variable = self.register_variable_parse
        register_variables << cur_register_variable
      end
      return list_of_variables_hook(register_variables)
    end

    def list_of_register_variables_hook(register_variables)
      return AST[:list_of_register_variables, register_variables]
    end


    RULES[:register_variable] = <<-___
<register_variable>
	::= <name_of_register>
	||= <name_of_memory> [ <constant_expression> : <constant_expression> ]
___

    def register_variable_parse
      parse_state = self.state
      name_of_memory = self.name_of_memory_parse
      if self.get_token(OPEN_BRA_REX) then
        constant_expression1 = self.constant_expression_parse
        self.parse_error("constant expression expected") unless constant_expression1
        self.parse_error("colon expected") unless self.get_token(COLON_REX)
        constant_expression2  = self.constant_expression_parse
        self.parse_error("constant expression expected") unless constant_expression2
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
        return register_variable_hook(name_of_memory,
                                      constant_expression1, 
                                      constant_expression2)
      else
        self.state = parse_state
        name_of_register = self.name_of_register_parse
        return register_variable_hook(name_of_register,nil,nil)
      end
    end

    def register_variable_hook(name, 
                               constant_expression1,
                               constant_expression2)
      return AST[:register_variable, 
                 name, constant_expression1, constant_expression2 ]
    end


    RULES[:name_of_register] = <<-___
<name_of_register>
	::= <IDENTIFIER>
___

    def name_of_register_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return name_of_register_hook(identifier)
    end

    def name_of_register_hook(identifier)
      return AST[:name_of_register, identifier]
    end


    RULES[:name_of_memory] = <<-___
<name_of_memory>
	::= <IDENTIFIER>
___

    def name_of_memory_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return name_of_memory_hook(identifier)
    end

    def name_of_memory_hook(identifier)
      return AST[:name_of_memory, identifier]
    end


    RULES[:name_of_event] = <<-___
<name_of_event>
	::= <IDENTIFIER>
___

    def name_of_event_parse
      identifier = self._IDENTIFIER_parse
      return nill unless identifier
      return name_of_event_hook(identifier)
    end

    def name_of_event_hook(identifier)
      return AST[:name_of_event, identifier]
    end


    RULES[:charge_strength] = <<-___
<charge_strength>
	::= ( small )
	||= ( medium )
	||= ( large )
___

    def charge_strength_parse
      parse_state = self.state
      tok0 = self.get_token(OPEN_PAR_REX)
      tok1 = self.get_token(CHAR_STRENGH_REX)
      tok2 = self.get_token(CLOSE_PAR_REX)
      if !tok0 or !tok2 then
        self.state = parse_state
        return nil
      end
      unless tok1 
        self.state = parse_state
        return nil
      end
      return charget_strength_hook(tok1)
    end

    def charge_strength_hook(type)
      return AST[:char_strength, type]
    end


    RULES[:drive_strength] = <<-___
<drive_strength>
	::= ( <STRENGTH0> , <STRENGTH1> )
	||= ( <STRENGTH1> , <STRENGTH0> )
___

    def drive_strength_parse
      parse_state = self.state
      unless self.get_token(OPEN_PAR_REX) then
        return nil
      end
      strength0 = self._STRENGTH0_parse
      if !strength0 then
        strength1 = self._STRENGTH1_parse
        unless strength1 then
          self.state = parse_state
          return nil
        end
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        strength0 = self._STRENGTH0_parse
        self.parse_error("one of [#{STRENGTH0_TOKS.join(",")}] expected") unless strength0
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return drive_strength_hook(strength1, strength0)
      else
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        strength1 = self._STRENGTH1_parse
        self.parse_error("one of [#{STRENGTH1_TOKS.join(",")}] expected") unless strength1
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return drive_strength_hook(strength0, strength1)
      end
    end

    def drive_strength_hook(strengthL, strengthR)
      return AST[:drive_strength, strengthL,strengthR ]
    end


    RULES[:STRENGTH0] = <<-___
<STRENGTH0> is one of the following keywords:
	supply0  strong0  pull0  weak0  highz0
___

    def _STRENGTH0_parse
      strength0 = self.get_token(STRENGTH0_REX)
      unless strength0
        return nil
      end
      return _STRENGTH0_hook(strength0)
    end

    def _STRENGTH0_hook(strength0)
      return AST[:STRENGTH0, strength0]
    end


    RULES[:STRENGTH1] = <<-___
<STRENGTH1> is one of the following keywords:
	supply1  strong1  pull1  weak1  highz1
___

    def _STRENGTH1_parse
      strength1 = self.get_token(STRENGTH1_REX)
      unless strength1
        return nil
      end
      return _STRENGTH1_hook(strength1)
    end

    def _STRENGTH1_hook(strength1)
      return AST[:STRENGTH1, strength1]
    end


    RULES[:range_parse] = <<-___
<range>
	::= [ <constant_expression> : <constant_expression> ]
___

    def range_parse
      parse_state = self.state
      return nil unless self.get_token(OPEN_BRA_REX)
      constant_expression0 = self.constant_expression_parse
      if !constant_expression0 or !self.get_token(COLON_REX) then
        self.state = parse_state
        return nil
      end
      constant_expression1 = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression1
      self.parse_error unless self.get_token(CLOSE_BRA_REX)
      return range_hook(constant_expression0,constant_expression1)
    end

    def range_hook(constant_expression0, constant_expression1)
      return AST[:range, constant_expression0,constant_expression1 ]
    end


    RULES[:list_of_assignments] = <<-___
<list_of_assignments>
	::= <assignment> <,<assignment>>*
___

    def list_of_assignments_parse
      cur_assignment = self.assignment_parse
      self.parse_error("assignment expected") unless cur_assignment
      assignments = [ cur_assignment ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_assignment = self.assignment_parse
        self.parse_error("assignment expected") unless cur_assignment
        assignments << cur_assignment
      end
      return list_of_assignments_hook(assignments)
    end

    def list_of_assignments_hook(assignments)
      return AST[:list_of_assigments, assignments]
    end


    # 3. Primitive Instances
   

    RULES[:gate_declaration] = <<-___
<gate_declaration>
	::= <GATETYPE> <drive_strength>? <delay>?  <gate_instance> <,<gate_instance>>* ;
___

    def gate_declaration_parse
      gatetype = self._GATETYPE_parse
      return nil unless gatetype
      drive_strength = self.drive_strength_parse
      delay = self.delay_parse
      cur_gate_instance = self.get_instance_parse
      self.parse_error("gate instance expected") unless cur_gate_instance
      gate_instances = [ cur_gate_instance ]
      loop do
      unless self.get_token(COMMA_REX) then
          break
        end
        cur_gate_instance = self.get_instance_parse
        self.parse_error("gate instance expected") unless cur_gate_instance
        gate_instances << cur_gate_instance
      end
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return gate_declaration_hook(gatetype,drive_strength,delay,
                                   gate_instances)
    end

    def gate_declaration_hook(gatetype, drive_strength, delay,
                              gate_instances)
      return AST[:gate_declaration,
                 gatetype,drive_strength,delay,gate_instances ]
    end


    RULES[:GATETYPE] = <<-___
<GATETYPE> is one of the following keywords:
	and  nand  or  nor xor  xnor buf  bufif0 bufif1  not  notif0 notif1  pulldown pullup
	nmos  rnmos pmos rpmos cmos rcmos   tran rtran  tranif0  rtranif0  tranif1 rtranif1
___

    def _GATETYPE_parse
      type = self.get_token(GATETYPE_REX)
      unless type
        return nil
      end
      return _GATETYPE_hook(type)
    end

    def _GATETYPE_hook(type)
      return AST[:GATETYPE, type]
    end


    RULES[:delay] = <<-___
<delay>
	::= # <number>
	||= # <identifier>
	||= # (<mintypmax_expression> <,<mintypmax_expression>>? <,<mintypmax_expression>>?)
___

    def delay_parse
      unless self.get_token(SHARP_REX) then
        return nil
      end
      if self.get_token(OPEN_PAR_REX) then
        mintypmax_expression0 = self.mintypmax_expression_parse
        self.parse_error("min:typical:max delay expression expected") unless mintypmax_expression0
        tok = self.get_token(COMMA_CLOSE_PAR_REX)
        if tok == COMMA_TOK then
          mintypmax_expression1 = self.mintypmax_expression_parse
          self.parse_error("min:typical:max delay expression expected") unless mintypmax_expression1
          tok = self.get_token(COMMA_CLOSE_PAR_REX)
          if tok == COMMA_TOK then
            mintypmax_expression2 = self.mintypmax_expression_parse
            self.parse_error("min:typical:max delay expression expected") unless mintypmax_expression2
            self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
            return self.delay_hook(mintypmax_expression0,
                                   mintypmax_expression1,
                                   mintypmax_expression2)
          elsif tok == CLOSE_PAR_TOK then
            return self.delay_hook(mintypmax_expression0,
                                   mintypmax_expression1,nil)
          else
            self.parse_error("comma or closing parenthesis expected")
          end
        elsif tok == CLOSE_PAR_TOK then
          return self.delay_hook(mintypmax_expression0,nil,nil)
        else
          self.parse_error("closing parenthesis expected")
        end
      end
      number = self.parse_number
      if number then
        return self.delay_hook(number,nil,nil)
      end
      identifier = self.parse_identifier
      if identifier then
        return self.delay_hook(identifier)
      end
      self.parse_error("identifier expected")
    end

    def delay_hook(mintypmax_expression__number,
                   mintypmax_expression1, mintypexpression2)
      return AST[:delay, mintypmax_expression__number,
                 mintypmax_expression1,mintypexpression2 ]
    end


    RULES[:gate_instance] = <<-___
<gate_instance>
	::= <name_of_gate_instance>? ( <terminal> <,<terminal>>* ):w
___

    def gate_instance_parse
      parse_state = self.state
      name_of_gate_instance = self.name_of_gate_instance_parse
      unless self.get_token(OPEN_PAR_REX) then
        self.state = parse_state
        return nil
      end
      cur_terminal = self.terminal_parse
      unless cur_terminal then
        self.parse_error("terminal expected")
      end
      terminals = [ cur_terminal ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_terminal = self.terminal_parse
        self.parse_error("terminal expected") unless cur_terminal
        terminals << cur_terminal
      end
      return gate_instance_hook(name_of_gate_instance,terminals)
    end

    def gate_instance_hook(name_of_gate_instance, terminals)
      return AST[:gate_instance, name_of_gate_instance,terminals ]
    end


    RULES[:name_of_gate_instance] = <<-___
<name_of_gate_instance>
	::= <IDENTIFIER><range>?
___

    def name_of_gate_instance_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      range = self.range_parse
      return name_of_gate_instance_hook(identifier,range)
    end

    def name_of_gate_instance_hook(identifier, range)
      return AST[:name_of_gate_instance, identifier,range ]
    end


    RULES[:UDP_instantiation] = <<-___
<UDP_instantiation>
	::= <name_of_UDP> <drive_strength>? <delay>?
	<UDP_instance> <,<UDP_instance>>* ;
___

    def udp_instantiation_parse
      parse_state = self.state
      name_of_udp = self.name_of_udp_parse
      return nil unless name_of_udp
      drive_strength = self.drive_strength_parse
      delay = self.delay_parse
      cur_udp_instance = self.udp_instance_parse
      unless cur_udp_instance then
        self.state = parse_state
        return nil
      end
      udp_instances = [ cur_udp_instance ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_udp_instance = self.udp_instance_parse
        self.parse_error("UDP instantce expected") unless cur_udp_instance
        udp_instances << cur_udp_instance
      end
      return udp_instantiation_hook(name_of_udp,drive_strength,delay,
                                    udp_instances)
    end

    def udp_instantiation_hook(name_of_udp, drive_strength, delay,
                               udp_instances)
      return AST[:udp_instantiation,
                 name_of_udp,drive_strength,delya,udp_instances ]
    end


    RULES[:name_of_UDP] = <<-___
<name_of_UDP>
	::= <IDENTIFIER>
___

    def name_of_udp_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return name_of_udp_hook(identifier)
    end
    
    def name_of_udp_hook(identifier)
      return AST[:name_of_UDP, identifier]
    end


    RULES[:UDP_instance] = <<-___
<UDP_instance>
	::= <name_of_UDP_instance>? ( <terminal> <,<terminal>>* )
___

    def udp_instance_parse
      parse_state = self.state
      name_of_udp_instance = self.name_of_udp_instance_parse
      unless self.get_token(OPEN_PAR_REX) then
        self.state = parse_state
        return nil
      end
      cur_terminal = self.terminal_parse
      unless cur_terminal then
        self.state = parse_state
        return nil
      end
      terminals = [ cur_terminal ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_terminal = self.terminal_parse
        self.parse_error("terminal expected") unless cur_terminal
        terminals << cur_terminal
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return udp_instance_hook(name_of_udp_instance,terminals)
    end

    def udp_instance_hook(name_of_udp_instance, terminals)
      return AST[:UDP_instance, name_of_udp_instance,terminals]
    end


    RULES[:name_of_UDP_instance] = <<-___
<name_of_UDP_instance>
	::= <IDENTIFIER><range>?
___

    def name_of_udp_instance_parse
      identifier = self.identifier_parse
      return nil unless identifier
      range = self.range_parse
      return name_of_udp_instance_hook(identifier,range)
    end

    def name_of_udp_instance_hook(identifier,range)
      return AST[:name_of_UDP_instance, identifier,range ]
    end


    RULES[:terminal] = <<-___
<terminal>
	::= <expression>
	||= <IDENTIFIER>
___
    
    def terminal_parse
      expression = self.expression_parse
      if expression then
        return self.terminal_hook(expression)
      end
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return self.terminal_hook(identifier)
    end

    def terminal_hook(terminal)
      return AST[:terminal, terminal]
    end


    # 4. Module Instantiations


    RULES[:module_instantiation] = <<-___
<module_instantiation>
	::= <name_of_module> <parameter_value_assignment>?
		<module_instance> <,<module_instance>>* ;
___

    def module_instantiation_parse
      parse_state = self.state
      name_of_module = self.name_of_module_parse
      return nil unless name_of_module
      parameter_value_assignment = self.parameter_value_assignment_parse
      cur_module_instance = self.module_instance_parse
      unless cur_module_instance then
        self.state = parse_state
        return nil
      end
      module_instances = [ cur_module_instance ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_module_instance = self.module_instance_parse
        self.parse_error("module instance expected") unless cur_module_instance
        module_instances << cur_module_instance
      end
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return module_instantiation_hook(name_of_module,
                                       parameter_value_assignment,
                                       module_instances)
    end

    def module_instantiation_hook(name_of_module,
                                  parameter_value_assignment,
                                  module_instances)
      return AST[:module_instantiation, 
                 name_of_module,parameter_value_assignment,
                 module_instances ]
    end


    RULES[:name_of_module] = <<-___
<name_of_module>
	::= <IDENTIFIER>
___

    def name_of_module_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return name_of_module_hook(identifier)
    end

    def name_of_module_hook(identifier)
      return AST[:name_of_module, identifier]
    end


    RULES[:parameter_value_assignment] = <<-___
<parameter_value_assignment>
	::= # ( <expression> <,<expression>>* )
___

    def parameter_value_assignment_parse
      unless self.get_token(SHARP_REX) then
        return nil
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      cur_expression = self.expression_parse
      self.parse_error("expression expected") unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << cur_expression
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return parameter_value_assignment_hook(expressions)
    end

    def parameter_value_assignment_hook(expressions)
      return AST[:parameter_value_assignment, expressions]
    end


    RULES[:module_instance] = <<-___
<module_instance>
	::= <name_of_instance> ( <list_of_module_connections>? )
___

    def module_instance_parse
      parse_state = self.state
      name_of_instance = self.name_of_instance_parse
      return nil unless name_of_instance
      unless self.get_token(OPEN_PAR_REX) then
        self.state = parse_state
        return nil
      end
      list_of_module_connections = self.list_of_module_connections_parse
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return module_instance_hook(name_of_instance,
                                  list_of_module_connections)
    end

    def module_instance_hook(name_of_instance, list_of_module_connections)
      return AST[:module_instance, 
                 name_of_instance,list_of_module_connections ]
    end


    RULES[:name_of_instance] = <<-___
<name_of_instance>
	::= <IDENTIFIER><range>?
___

    def name_of_instance_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      range = self.range_parse
      return name_of_instance_hook(identifier,range)
    end

    def name_of_instance_hook(identifier, range)
      return AST[:name_of_instance, identifier,range ]
    end


    RULES[:list_of_module_connections] = <<-___
<list_of_module_connections>
	::= <module_port_connection> <,<module_port_connection>>*
	||= <named_port_connection> <,<named_port_connection>>*
___

    def list_of_module_connections_parse
      cur_named_port_connection = self.named_port_connection
      if cur_named_port_connection then
        named_port_connections = [ cur_named_port_connection ]
        loop do
          unless self.get_token(COMMA_REX) then
            break
          end
          cur_named_port_connection = self.cur_named_port_connection
          self.parse_error("named port connection expected") unless cur_named_port_connection
          named_port_connections << cur_named_port_connection
        end
        return list_of_module_connections_hook(named_port_connections)
      else
        cur_module_port_connection = self.module_port_connection_parse
        return nil unless cur_module_port_connection
        module_port_connections = [ cur_module_port_connection ]
        loop do
          unless self.get_token(COMMA_REX) then
            break
          end
          cur_module_port_connection = self.module_port_connection_parse
          self.parse_error("module port connection expected") unless cur_module_port_connection
          module_port_connections << cur_module_port_connection
        end
        return list_of_module_connections_hook(module_port_connections)
      end
    end

    def list_of_module_connections_hook(connections)
      return AST[:list_of_module_connections, connections]
    end


    RULES[:module_port_connection] = <<-___
<module_port_connection>
	::= <expression>
	||= <NULL>
___

    def module_port_connection_parse
      expression = self.expression_parse
      if expression then
        return module_port_connection_hook(expression)
      else
        return module_port_connection_hook(_NULL_hook)
      end
    end

    def module_port_connection_hook(expression)
      return AST[:module_port_connection, expression]
    end


    RULES[:NULL] = <<-___
<NULL>
	::= nothing - this form covers the case of an empty item in a list - for example:
	      (a, b, , d)
___

    # *Auth*: No parse of NULL, since it is literally nothing.
    def _NULL_hook
      return AST[:NULL]
    end


    RULES[:named_port_connection] = <<-___
<named_port_connection>
	::= .< IDENTIFIER> ( <expression> )
___

    def named_port_connection_parse
      unless self.get_token(DOT_REX) then
        return nil
      end
      identifier = self._IDENTIFIER_parse
      self.parse_error("identifier expected") unless identifier
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      expression = self.expression_parse
      self.parse_error("expression expected") unless expression
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return named_port_connection_hook(identifier,expression)
    end

    def named_port_connection_hook(identifier, expression)
      return AST[:named_port_connection, identifier,expression ]
    end


    # 5. Behavioral Statements
   

    RULES[:initial_statement] = <<-___
<initial_statement>
	::= initial <statement>
___

    def initial_statement_parse
      unless self.get_token(INITIAL_REX) then
        return nil
      end
      statement = self.statement_parse
      self.parse_error("statement expected") unless statement
      return self.initial_statement_hook(statement)
    end

    def initial_statement_hook(statement)
      return AST[:initial_statement, statement]
    end


    RULES[:always_statement] = <<-___
<always_statement>
	::= always <statement>
___

    def always_statement_parse
      unless self.get_token(ALWAYS_REX) then
        return nil
      end
      statement = self.statement_parse
      self.parse_error("statement expected") unless statement
      return self.always_statement_hook(statement)
    end

    def always_statement_hook(statement)
      return AST[:always_statement, statement]
    end


    RULES[:statement_or_null] = <<-___
<statement_or_null>
	::= <statement>
	||= ;
___

    def statement_or_null_parse
      if self.get_token(SEMICOLON_REX) then
        return statement_or_null_parse(self.null_hook)
      end
      statement = self.statement_parse
      return nil unless statement
      return statement_or_null_hook(statement)
    end

    def statement_or_null_hook(statement)
      return AST[:statement_or_null, statement]
    end


    RULES[:statement] = <<-___
<statement>
	::=<blocking_assignment> ;
	||= <non_blocking_assignment> ;
	||= if ( <expression> ) <statement_or_null>
	||= if ( <expression> ) <statement_or_null> else <statement_or_null>
	||= case ( <expression> ) <case_item>+ endcase
	||= casez ( <expression> ) <case_item>+ endcase
	||= casex ( <expression> ) <case_item>+ endcase
	||= forever <statement>
	||= repeat ( <expression> ) <statement>
	||= while ( <expression> ) <statement>
	||= for ( <assignment> ; <expression> ; <assignment> ) <statement>
	||= <delay_or_event_control> <statement_or_null>
	||= wait ( <expression> ) <statement_or_null>
	||= -> <name_of_event> ;
	||= <seq_block>
	||= <par_block>
	||= <task_enable>
	||= <system_task_enable>
	||= disable <name_of_task> ;
	||= disable <name_of_block> ;
	||= assign <assignment> ;
	||= deassign <lvalue> ;
	||= force <assignment> ;
	||= release <lvalue> ;
___

    def statement_parse
      tok = self.get_token(STATEMENT_REX)
      case(tok)
      when IF_TOK
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        statement_or_null = self.statement_or_null_parse
        self.parse_error("statement or nothing expected") unless statement_or_null
        if self.get_token(ELSE_REX) then
          statement_or_null2 = self.statement_or_null_parse
          self.parse_error("statement or nothing expected") unless statemeent_or_null2
          return statement_hook(IF_TOK,expression,statement_or_null,
                                statement_or_null2,nil)
        else
          return statement_hook(tok,expression,statement_or_null,nil,nil)
        end
      when CASE_TOK, CASEZ_TOK, CASEX_TOK
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        cur_case_item = self.case_item_parse
        self.parse_error("closing parenthesis expected") unless cur_case_item
        case_items = [ cur_case_item ]
        loop do
          cur_case_item = self.case_item_parse
          break unless cur_case_item
          case_items << cur_case_item
        end
        self.parse_error("'endcase' expected") unless self.get_token(ENDCASE_REX)
        return self.statement_hook(tok,expression,case_items,nil,nil)
      when FOREVER_TOK
        statement = self.statement_parse
        self.parse_error("statement expected") unless statement
        return self.statement_hook(tok,statement,nil,nil,nil)
      when REPEAT_TOK, WHILE_TOK
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        statement = self.statement_parse
        self.parse_error("statement expression expected") unless statement
        return self.statement_hook(tok,expression,statement,nil,nil)
      when FOR_TOK
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        assignment = self.assignment_parse
        self.parse_error("assignment expected") unless assignment
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        assignment2 = self.assignment_parse
        self.parse_error("assignment expected") unless assignment2
        self.parse_error("closing parenthesis expected") unless set.get_token(CLOSE_PAR_REX)
        statement = self.parse_statement
        self.parse_error("statement expected") unless statement
        return self.statement_hook(tok,assignment,expression,assignment2,
                                  statement)
      when WAIT_TOK
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        statement_or_null = self.statement_or_null_parse
        self.parse_error("statement or nothing expected") unless statement_or_null
        return self.statement_hook(tok,expression,statement_or_null,
                                   nil,nil)
      when RIGHT_ARROW_TOK
        name_of_event = self.parse_name_of_event
        self.parse_error("event name expected") unless name_of_event
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.statement_hook(tok,name_of_event,nil,nil,nil)
      when DISABLE_TOK
        name_of_task = self.name_of_task_parse
        if name_of_task then
          self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
          return self.statement_hook(tok,name_of_task,nil,nil,nil)
        end
        name_of_block = self.name_of_block_parse
        if name_of_block then
          self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
          return self.statement_hook(tok,name_of_block,nil,nil,nil)
        end
        self.parse_error("invalid disable")
      when ASSIGN_TOK, FORCE_TOK
        assignment = self.assignment_parse
        self.parse_error("assignment expected") unless assignment
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.statement_hook(tok,assignment,nil,nil,nil)
      when DEASSIGN_TOK, RELEASE_TOK
        lvalue = self.lvalue_parse
        self.parse_error("left value expected") unless lvalue
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.statement_hook(tok,lvalue,nil,nil,nil)
      end
      delay_or_event_control = self.delay_or_event_control_parse
      if delay_or_event_control then
        statement_or_null = self.statement_or_null_parse
        self.parse_error("statement or nothing expected") unless statement_or_null
        return self.statement_hook(delay_or_event_control,
                                   statement_or_null,nil,nil,nil)
      end
      seq_block = self.seq_block_parse
      if seq_block then
        return self.statement_hook(seq_block,nil,nil,nil,nil)
      end
      par_block = self.par_block_parse
      if par_block then
        return self.statement_hook(par_block,nil,nil,nil,nil)
      end
      task_enable = self.task_enable_parse
      if task_enable then
        return self.statement_hook(task_enable,nil,nil,nil,nil)
      end
      system_task_enable = self.system_task_enable_parse
      if system_task_enable then
        return self.statement_hook(system_task_enable,nil,nil,nil,nil)
      end
      blocking_assignment = self.blocking_assignment_parse
      if blocking_assignment then
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.statement_hook(blocking_assignment,nil,nil,nil,nil)
      end
      non_blocking_assignment = self.non_blocking_assignment_parse
      if non_blocking_assignment then
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.statement_hook(non_blocking_assignment,nil,nil,nil,nil)
      end
      return nil
    end

    def statement_hook(base,arg0,arg1,arg2,arg3)
      return AST[:statement, base,arg0,arg1,arg2,arg3 ]
    end


    RULES[:assignment] = <<-___
<assignment>
	::= <lvalue> = <expression>
___

    def assignment_parse
      parse_state = self.state
      lvalue = self.lvalue_parse
      unless lvalue then
        self.state = parse_state
        return nil
      end
      unless self.get_token(EQUAL_REX) then
        self.state = parse_state
        return nil
      end
      expression = self.expression_parse
      # puts "expression=#{expression}"
      self.parse_error("expression expected") unless expression
      return self.assignment_hook(lvalue,expression)
    end

    def assignment_hook(lvalue,expression)
      return AST[:assignment, lvalue,expression ]
    end


    RULES[:blocking_assignment] = <<-___
<blocking_assignment>
	::= <lvalue> = <expression>
	||= <lvalue> = <delay_or_event_control> <expression> ;
___

    def blocking_assignment_parse
      parse_state = self.state
      lvalue = self.lvalue_parse
      return nil unless lvalue
      unless self.get_token(EQUAL_REX) then
        self.state = parse_state
        return nil
      end
      delay_or_event_control = self.delay_or_event_control_parse
      expression = self.expression_parse
      unless expression then
        self.state = parse_state
        return nil
      end
      return self.blocking_assignment_hook(lvalue,delay_or_event_control,
                                          expression)
    end

    def blocking_assignment_hook(lvalue, delay_or_event_control,
                                 expression)
      return AST[:blocking_assignment,
                 lvalue,delay_or_event_control,expression ]
    end


    RULES[:non_blocking_assignment] = <<-___
<non_blocking_assignment>
	::= <lvalue> <= <expression>
	||= <lvalue> = <delay_or_event_control> <expression> ;
___

    def non_blocking_assignment_parse
      parse_state = self.state
      lvalue = self.lvalue_parse
      return nil unless lvalue
      unless self.get_token(ASSIGN_ARROW_REX) then
        self.state = parse_state
        return nil
      end
      delay_or_event_control = self.delay_or_event_control_parse
      expression = self.expression_parse
      unless expression then
        self.state = parse_state
        return nil
      end
      return self.non_blocking_assignment_hook(lvalue,
                                               delay_or_event_control,
                                               expression)
    end

    def non_blocking_assignment_hook(lvalue, delay_or_event_control,
                                 expression)
      return AST[:non_blocking_assignment,
                 lvalue,delay_or_event_control,expression ]
    end


    RULES[:delay_or_event_control] = <<-___
<delay_or_event_control>
	::= <delay_control>
	||= <event_control>
	||= repeat ( <expression> ) <event_control>
___

    def delay_or_event_control_parse
      if self.get_token(REPEAT_REX) then
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        event_control = self.event_control_parse
        self.parse_error("event control expected") unless event_control
        return self.delay_or_event_control_hook(REPEAT_TOK,
                                           expression,event_control)
      end
      delay_control = self.delay_control_parse
      if delay_control then
        return self.delay_or_event_control_hook(delay_control,nil,nil)
      end
      event_control = self.event_control_parse
      if event_control then
        return self.delay_or_event_control_hook(event_control,nil,nil)
      end
      return nil
    end

    def delay_or_event_control_hook(base,arg0,arg1)
      return AST[:delay_or_event_control, base,arg0,arg1 ]
    end


    RULES[:case_item] = <<-___
<case_item>
	::= <expression> <,<expression>>* : <statement_or_null>
	||= default : <statement_or_null>
	||= default <statement_or_null>
___

    def case_item_parse
      parse_state = self.state
      if self.get_token(DEFAULT_REX) then
        unless self.get_token(COLON_REX) then
        end
        statement_or_null = self.statement_or_null_parse
        self.parse_error("statement or nothing expected") unless statement_or_null
        return self.case_item_hook(DEFAULT_TOK,statement_or_null)
      end
      cur_expression = self.expression_parse
      self.syntax_error unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << cur_expression
      end
      unless self.get_token(COLON_REX) then
        # It was not an item
        self.state = parse_state
        return nil
      end
      statement_or_null = self.statement_or_null_parse
      self.parse_error("statement or nothing expected") unless statement_or_null
      return self.case_item_hook(expressions,statement_or_null)
    end

    def case_item_hook(cas, statement_or_null)
      return AST[:case_item, cas,statement_or_null ]
    end


    RULES[:seq_block] = <<-___
<seq_block>
	::= begin <statement>* end
	||= begin : <name_of_block> <block_declaration>* <statement>* end
___

    def seq_block_parse
      unless self.get_token(BEGIN_REX) then
        return nil
      end
      if self.get_token(COLON_REX) then
        name_of_block = self.name_of_block_parse
        self.parse_error("block name expected") unless name_of_block
        block_declarations = [ ]
        cur_block_declaration = nil
        loop do
          cur_block_declaration = self.block_declaration_parse
          break unless cur_block_declaration
          block_declarations << cur_block_declaration
        end
        statements = []
        cur_statement = nil
        loop do
          cur_statement = self.statement_parse
          break unless cur_statement
          statements << cur_statement
        end
        self.parse_error("'end' expected") unless self.get_token(END_REX)
        return self.seq_block_hook(name_of_block,block_declarations,
                                   statements)
      else
        statements = []
        cur_statement = nil
        loop do
          cur_statement = self.statement_parse
          break unless cur_statement
          statements << cur_statement
        end
        self.parse_error("'end' expected") unless self.get_token(END_REX)
        return self.seq_block_hook(statements,nil,nil)
      end
    end

    def seq_block_hook(statements__name_of_block,
                       block_declarations, statements)
      return AST[:seq_block, statements__name_of_block,
                 block_declarations,statements ]
    end


    RULES[:par_block] = <<-___
<par_block>
	::= fork <statement>* join
	||= fork : <name_of_block> <block_declaration>* <statement>* join
___

    def par_block_parse
      unless self.get_token(FORK_REX) then
        return nil
      end
      if self.get_token(COLON_REX) then
        name_of_block = self.name_of_block_parse
        self.parse_error("block name expected") unless name_of_block
        block_declarations = [ ]
        cur_block_declaration = nil
        loop do
          cur_block_declaration = self.block_declaration_parse
          break unless cur_block_declaration
          block_declarations << cur_block_declaration
        end
        statements = []
        cur_statement = nil
        loop do
          cur_statement = self.statement_parse
          break unless cur_statement
          statements << cur_statement
        end
        self.parse_error("'join' expected") unless self.get_token(JOIN_REX)
        return self.par_block_hook(name_of_block,block_declarations,
                                   statements)
      else
        statements = []
        cur_statement = nil
        loop do
          cur_statement = self.statement_parse
          break unless cur_statement
          statements << cur_statement
        end
        self.parse_error("'join' expected") unless self.get_token(JOIN_REX)
        return self.par_block_hook(statements,nil,nil)
      end
    end

    def par_block_hook(statements__name_of_block,
                       block_declarations, statements)
      return AST[:name_of_block, statements__name_of_block,
                 block_declarations,statements ]
    end


    RULES[:name_of_block] = <<-___
<name_of_block>
	::= <IDENTIFIER>
___

    def name_of_block_parse
      identifier = self._IDENTIFIER_parse
      return nil unless identifier
      return self.name_of_block_hook(identifier)
    end

    def name_of_block_hook(identifier)
      return AST[:name_of_block, identifier]
    end


    RULES[:block_declaration] = <<-___
<block_declaration>
	::= <parameter_declaration>
	||= <reg_declaration>
	||= <integer_declaration>
	||= <real_declaration>
	||= <time_declaration>
	||= <event_declaration>
___

    def block_declaration_parse
      parameter_declaration = self.parameter_declaration_parse
      if parameter_declaration then
        return self.block_declaration_hook(parameter_declaration)
      end
      reg_declaration = self.reg_declaration_parse
      if reg_declaration then
        return self.block_declaration_hook(reg_declaration)
      end
      integer_declaration = self.integer_declaration_parse
      if integer_declaration then
        return self.block_declaration_hook(integer_declaration)
      end
      real_declaration = self.real_declaration_parse
      if real_declaration then
        return self.block_declaration_hook(real_declaration)
      end
      time_declaration = self.time_declaration_parse
      if time_declaration then
        return self.block_declaration_hook(time_declaration)
      end
      event_declaration = self.event_declaration_parse
      if event_declaration then
        return self.block_declaration_hook(event_declaration)
      end
      return nil
    end

    def block_declaration_hook(declaration)
      return AST[:block_declaration, declaration]
    end


    RULES[:task_enable] = <<-___
<task_enable>
	::= <name_of_task>
	||= <name_of_task> ( <expression> <,<expression>>* ) ;
___

    # Auth: there seems ot be a mistake in this rule:
    # there should be a semi colon and after name_of_task.
    # So use the following rule:
    # <task_enable>
    # ::= <name_of_task> ;
    # ||= <name_of_task ( <expression, <,<expression>>* ) ;
    def task_enable_parse
      parse_state = self.state
      name_of_task = self.name_of_task_parse
      return nil unless name_of_task
      unless self.get_token(OPEN_PAR_REX) then
        if self.get_token(SEMICOLON_REX) then
          return self.task_enable_hook(name_of_task,nil)
        else
          self.state = parse_state
          return nil
        end
      end
      cur_expression = self.expression_parse
      self.parse_error("expression expected") unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << cur_expression
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.task_enable_hook(name_of_task,expressions)
    end

    def task_enable_hook(name_of_task,expressions)
      return AST[:task_enable, name_of_task,expressions ]
    end


    RULES[:system_task_enable] = <<-___
<system_task_enable>
	::= <name_of_system_task> ;
	||= <name_of_system_task> ( <expression> <,<expression>>* ) ;
___

    def system_task_enable_parse
      parse_state = self.state
      name_of_system_task = self.name_of_system_task_parse
      return nil unless name_of_system_task
      unless self.get_token(OPEN_PAR_REX) then
        if self.get_token(SEMICOLON_REX) then
          return self.system_task_enable_hook(name_of_system_task,nil)
        else
          self.state = parse_state
          return nil
        end
      end
      cur_expression = self.expression_parse
      self.parse_error("expression expected") unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << cur_expression
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.system_task_enable_hook(name_of_system_task,expressions)
    end

    def system_task_enable_hook(name_of_system_task,expressions)
      return AST[:system_task_enable, name_of_system_task,expressions ]
    end


    RULES[:name_of_system_task] = <<-___
<name_of_system_task>
	::= $<system_identifier> (Note: the $ may not be followed by a space.)
___

    def name_of_system_task_parse
      # *Auth*: the $ is integrated into the system_identifier!!
      identifier = self.system_identifier_parse
      return nil unless identifier
      return self.name_of_system_task_hook(identifier)
    end

    def name_of_system_task_hook(identifier)
      return AST[:name_of_system_task, identifier]
    end


    RULES[:system_identifier] = <<-___
<SYSTEM_IDENTIFIER>
	An <IDENTIFIER> assigned to an existing system task or function
___

    def system_identifier_parse
      tok = self.get_token(SYSTEM_IDENTIFIER_REX)
      if tok then
        return self.system_identifier_hook(tok)
      end
      return nil
      # self.parse_error("dollar-starting identifier expected")
    end

    def system_identifier_hook(tok)
      AST[:system_identifier, tok]
    end


    # 6. Specify Section
   

    RULES[:specify_block] = <<-___
<specify_block>
	::= specify <specify_item>* endspecify
___

    def specify_block_parse
      unless self.get_token(SPECIFY_REX) then
        return nil
      end
      specify_items = []
      cur_specify_item = nil
      loop do
        cur_specify_item = self.specify_item_parse
        break unless cur_specify_item
        specify_items << cur_specify_item
      end
      self.parse_error("'endspecify expected'") unless self.get_token(ENDSPECIFY_REX)
      return self.specify_block_hook(specify_items)
    end

    def specify_block_hook(specify_items)
      return AST[:specify_block, specify_items]
    end


    RULES[:specify_item] = <<-___
<specify_item>
	::= <specparam_declaration>
	||= <path_declaration>
	||= <level_sensitive_path_declaration>
	||= <edge_sensitive_path_declaration>
	||= <system_timing_check>
	||= <sdpd>
___

    def specify_item_parse
      specparam_declaration = self.specparam_declaration_parse
      if specparam_declaration then
        return self.specify_item_hook(specparam_declaration)
      end
      path_declaration = self.path_declaration_parse
      if path_declaration then
        return self.specify_item_hook(path_declaration)
      end
      level_sensitive_path_declaration = 
        self.level_sensitive_path_declaration_parse
      if level_sensitive_path_declaration then
        return self.specify_item_hook(level_sensitive_path_declaration)
      end
      edge_sensitive_path_declaration =
        self.edge_sensitive_path_declaration_parse
      if edge_sensitive_path_declaration then
        return self.specify_item_hook(edge_sensitive_path_declaration)
      end
      system_timing_check = self.system_timing_check_parse
      if system_timing_check then
        return self.specify_item_hook(system_timing_check)
      end
      sdpd = self.sdpd_parse
      if sdpd then
        return self.specify_item_hook(sdpd)
      end
      return nil
    end

    def specify_item_hook(declaration)
      return AST[:specify_item, declaration]
    end


    RULES[:specparam_declaration] = <<-___
<specparam_declaration>
	::= specparam <list_of_param_assignments> ;
___

    def specparam_declaration_parse
      unless self.get_token(SPECPARAM_REX) then
        return nil
      end
      list_of_param_assignments = self.list_of_param_assignments_parse
      self.parse_error("list of parameter assignments expected") unless list_of_param_assignments
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return self.specparam_declaration_hook(list_of_param_assignments)
    end

    def specparam_declaration_hook(list_of_param_assignments)
      return AST[:specparam_declaration, list_of_param_assignments]
    end


    RULES[:list_of_param_assignments] = <<-___
<list_of_param_assignments>
	::=<param_assignment><,<param_assignment>>*
___

    def list_of_param_assignments_parse
      cur_param_assignment = self.param_assignment_parse
      return nil unless cur_param_assignment
      param_assigments = [ cur_param_assignment ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_param_assignment = self.param_assignment_parse
        param_assigments << cur_param_assignment
      end
      return self.list_of_param_assignments_hook(param_assignments)
    end

    def list_of_param_assignments_hook(param_assignments)
      return AST[:list_of_param_assignments, param_assignments]
    end


    RULES[:param_assignment] = <<-___
<param_assignment>
	::=<<identifier>=<constant_expression>>
___

    def param_assignment_parse
      identifier = self.identifier_parse
      return nil unless identifier
      self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
      constant_expression = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression
      return self.param_assignment_hook(identifier,constant_expression)
    end

    def param_assignment_hook(identifier, constant_expression)
      return AST[:param_assignment, identifier,constant_expression ]
    end


    RULES[:path_declaration] = <<-___
<path_declaration>
	::= <path_description> = <path_delay_value> ;
___

    def path_declaration_parse
      path_description = self.path_description_parse
      return nil unless path_description
      self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
      path_delay_value = self.path_delay_value_parse
      self.parse_error("path delay value expected") unless path_delay_value
      self.parse_error("semicolon expected") unless self.get_toekn == SEMICOLON_TOK
      return self.path_declaration_hook(path_description,path_delay_value)
    end

    def path_declaration_hook(path_description, path_delay_value)
      return AST[:path_declaration, path_description,path_delay_value ]
    end


    RULES[:path_description] = <<-___
<path_description>
	::= ( <specify_input_terminal_descriptor> => <specify_output_terminal_descriptor> )
	||= ( <list_of_path_inputs> *> <list_of_path_outputs> )
___

    def path_description_parse
      parse_state = self.state
      unless self.get_token(OPEN_PAR_REX) then
        self.state = parse_state
        return nil
      end
      specify_input_terminal_descriptor =
        self.specify_input_terminal_descriptor_parse
      if self.get_token(SEND_ARROW_REX) and 
          specify_input_terminal_descriptor then
        specify_output_terminal_descriptor =
          self.specify_output_terminal_descriptor_parse
        self.parse_error("output terminal descriptor expected") unless specify_output_terminal_descriptor
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.path_description_hook(SEND_ARROW_TOK,
                                     specify_input_terminal_descriptor,
                                     specify_output_terminal_descriptor)
      end
      list_of_path_inputs = self.list_of_path_inputs_parse
      unless list_of_path_inputs then
        self.state = parse_state
        return nil
      end
      unless self.get_token(ASTERISK_ARROW_REX) then
        self.state = parse_state
      end
      list_of_path_outputs = self.list_of_path_outputs_parse
      self.parse_error("list of path outputs expected") unless list_of_path_outputs
      return self.path_description_hook(ASTERIS_ARROW_TOK,
                                        list_of_path_inputs,
                                        list_of_path_outputs)
    end

    def path_description_hook(type, input, output)
      return AST[:path_description, type,input,output ]
    end


    RULES[:list_of_path_inputs] = <<-___
<list_of_path_inputs>
	::= <specify_input_terminal_descriptor> <,<specify_input_terminal_descriptor>>*
___

    def list_of_path_inputs_parse
      cur_specify_input_terminal_descriptor = 
        self.specify_input_terminal_descriptor_parse
      return nil unless cur_specify_input_terminal_descriptor
      specify_input_terminal_descriptors = 
        [ cur_specify_input_terminal_descriptor ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_specify_input_terminal_descriptor = 
          self.specify_input_terminal_descriptor_parse
        self.parse_error("input terminal descriptor expected") unless cur_specify_input_terminal_descriptor
        specify_input_terminal_descriptors << cur_specify_input_terminal_descriptor
      end
      return self.list_of_path_inputs_hook(specify_input_terminal_descriptors)
    end

    def list_of_path_inputs_hook(specify_input_terminal_descriptors)
      return AST[:list_of_path_inputs,
                 specify_input_terminal_descriptors ]
    end


    RULES[:list_of_path_outputs] = <<-___
<list_of_path_outputs>
	::=  <specify_output_terminal_descriptor> <,<specify_output_terminal_descriptor>>*
___

    def list_of_path_outputs_parse
      cur_specify_output_terminal_descriptor = 
        self.specify_output_terminal_descriptor_parse
      return nil unless cur_specify_output_terminal_descriptor
      specify_output_terminal_descriptors = 
        [ cur_specify_output_terminal_descriptor ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_specify_output_terminal_descriptor = 
          self.specify_output_terminal_descriptor_parse
        self.parse_erro("output terminal descriptor expected") unless cur_specify_output_terminal_descriptor
        specify_output_terminal_descriptors << cur_specify_output_terminal_descriptor
      end
      return self.list_of_path_outputs_hook(specify_output_terminal_descriptors)
    end

    def list_of_path_outputs_hook(specify_output_terminal_descriptors)
      return AST[:list_of_path_outputs,
                 specify_output_terminal_descriptors ]
    end


    RULES[:specify_input_terminal_descriptor] = <<-___
<specify_input_terminal_descriptor>
	::= <input_identifier>
	||= <input_identifier> [ <constant_expression> ]
	||= <input_identifier> [ <constant_expression> : <constant_expression> ]
___

    def specify_input_terminal_descriptor_parse
      input_identifier = self.input_identifier_parse
      return nil unless input_identifier
      unless self.get_token(OPEN_BRA_REX) then
        return self.specify_input_terminal_descriptor_hook(
          input_identifier,nil,nil)
      end
      constant_expression = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression
      tok = self.get_token(CLOSE_BRA_COLON_REX)
      if tok == CLOSE_BRA_TOK then
        return self.specify_input_terminal_descriptor_hook(
          input_identifier,constant_expression,nil)
      elsif tok == COLON_TOK then
        constant_expression2 = self.constant_expression_parse
        self.parse_error("constant expression expected") unless constant_expression
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
        return self.specify_input_terminal_descriptor_hook(
          input_identifier,constant_expression,constant_expression2)
      else
        self.parse_error("invalid input terminal descriptor")
      end
    end

    def specify_input_terminal_descriptor_hook(input_identifier,
                                               constant_expression,
                                               constant_expression2)
      return AST[:specify_input_terminal_descriptor,
                 input_identifier,
                 constant_expression,constant_expression2 ]
    end


    RULES[:specify_output_terminal_descriptor] = <<-___
<specify_output_terminal_descriptor>
	::= <output_identifier>
	||= <output_identifier> [ <constant_expression> ]
	||= <output_identifier> [ <constant_expression> : <constant_expression> ]
___

    def specify_output_terminal_descriptor_parse
      output_identifier = self.output_identifier_parse
      return nil unless output_identifier
      unless self.get_token(OPEN_BRA_REX) then
        return self.specify_output_terminal_descriptor_hook(
          output_identifier,nil,nil)
      end
      constant_expression = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression
      tok = self.get_token(CLOSE_BRA_COLON_REX)
      if tok == CLOSE_BRA_TOK then
        return self.specify_output_terminal_descriptor_hook(
          output_identifier,constant_expression,nil)
      elsif tok == COLON_TOK then
        constant_expression2 = self.constant_expression_parse
        self.parse_error("constant expression expected") unless constant_expression
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
        return self.specify_output_terminal_descriptor_hook(
          output_identifier,constant_expression,constant_expression2)
      else
        self.parse_error("invalid output terminal descriptor")
      end
    end

    def specify_output_terminal_descriptor_hook(output_identifier,
                                               constant_expression,
                                               constant_expression2)
      return AST[:specify_output_terminal_descriptor,
                 output_identifier,
                 constant_expression,constant_expression2 ]
    end


    RULES[:input_identifier] = <<-___
<input_identifier>
	::= the <IDENTIFIER> of a module input or inout terminal
___

    def input_identifier_parse
      # *Auth*: it should be checked that the identifier comes from
      # an input module. Left the the AST processing.
      identifier = self._IDENTIFIER_parse
      return self.input_identifier_hook(identifier)
    end

    def input_identifier_hook(identifier)
      return AST[:input_identifier, identifier ]
    end


    RULES[:output_identifier] = <<-___
<output_identifier>
	::= the <IDENTIFIER> of a module output or inout terminal.
___

    def output_identifier_parse
      # *Auth*: it should be checked that the identifier comes from
      # an output module. Left the the AST processing.
      identifier = self.identifier_parse
      return self.output_identifier_hook(identifier)
    end

    def output_identifier_hook(identifier)
      return AST[:output_identifier, identifier ]
    end


    RULES[:path_delay_value] = <<-___
<path_delay_value>
	::= <path_delay_expression>
	||= ( <path_delay_expression>, <path_delay_expression> )
	||= ( <path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>)
	||= ( <path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression> )
	||= ( <path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression>,
		<path_delay_expression>, <path_delay_expression> )
___

    def path_delay_value_parse
      parse_state = self.state
      if self.get_token(OPEN_PAR_REX) then
        cur_path_delay_expression = self.path_delay_expression_parse
        unless cur_path_delay_expression then
          self.state = parse_state
          return nil
        end
        path_delay_expressions = [ cur_path_delay_expression ]
        tok = nil
        11.times do
          break unless self.get_token(COMMA_REX)
          cur_path_delay_expression = self.path_delay_expression_parse
          self.parse_error("path delay expression expected") unless cur_path_delay_expression
          path_delay_expressions << cur_path_delay_expression
        end
        self.parse_error("closing parenthesis expected") unless tok == CLOSE_PAR_TOK
        # Ensure there are 12 elements in the path_delay_expressions
        if path_delay_expressions.size < 12 then
          path_delay_expressions[11] = nil
        end
        return self.path_delay_value_hook(*path_delay_expressions)
      else
        path_delay_expression = self.path_delay_expression_parse
        return nil unless path_delay_expression
        return self.path_delay_value_hook(path_delay_expression,
                                         nil,nil,nil,nil,nil,nil,
                                         nil,nil,nil,nil,nil)
      end
    end

    def path_delay_value_hook(path_delay_expression0,
                              path_delay_expression1,
                              path_delay_expression2,
                              path_delay_expression3,
                              path_delay_expression4,
                              path_delay_expression5,
                              path_delay_expression6,
                              path_delay_expression7,
                              path_delay_expression8,
                              path_delay_expression9,
                              path_delay_expression10,
                              path_delay_expression11)
      return AST[:path_delay_value, 
                 path_delay_expression0,
                 path_delay_expression1,
                 path_delay_expression2,
                 path_delay_expression3,
                 path_delay_expression4,
                 path_delay_expression5,
                 path_delay_expression6,
                 path_delay_expression7,
                 path_delay_expression8,
                 path_delay_expression9,
                 path_delay_expression10,
                 path_delay_expression11 ]
    end


    RULES[:path_delay_expression] = <<-___
<path_delay_expression>
	::= <mintypmax_expression>
___

    def path_delay_expression_parse
      mintypmax_expression = self.mintypmax_expression_parse
      return nil unless mintypmax_expression
      return path_delay_expression_hook(mintypmax_expression)
    end

    def path_delay_expression_hook(mintypmax_expression)
      return AST[:path_delay_expression, mintypmax_expression]
    end


    RULES[:system_timing_check] = <<-___
<system_timing_check>
	::= $setup( <timing_check_event>, <timing_check_event>,
		<timing_check_limit>
		<,<notify_register>>? ) ;
	||= $hold( <timing_check_event>, <timing_check_event>,
		<timing_check_limit>
		<,<notify_register>>? ) ;
	||= $period( <controlled_timing_check_event>, <timing_check_limit>
		<,<notify_register>>? ) ;
	||= $width( <controlled_timing_check_event>, <timing_check_limit>
		<,<constant_expression>,<notify_register>>? ) ;
	||= $skew( <timing_check_event>, <timing_check_event>,
		<timing_check_limit>
		<,<notify_register>>? ) ;
	||= $recovery( <controlled_timing_check_event>,
		<timing_check_event>,
		<timing_check_limit> <,<notify_register>>? ) ;
	||= $setuphold( <timing_check_event>, <timing_check_event>,
		<timing_check_limit>, <timing_check_limit> <,<notify_register>>? ) ;
___

    def system_timing_check_parse
      tok = self.get_token(SYSTEM_TIMING_REX)
      case(tok)
      when SETUP_TOK, HOLD_TOK
        timing_check_event0 = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event0
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_event1 = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event1
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit
        notify_register = nil
        if self.get_token(COMMA_REX) then
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless cur_notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                             timing_check_event0,
                                             timing_check_event1,
                                             timing_check_limit,
                                             notify_register,
                                             nil)
      when PERIOD_TOK
        controlled_timing_check_event = 
          self.controlled_timing_check_event_parse
        self.parse_error("controlled timing check expected") unless controlled_timing_check_event
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit
        notify_register = nil
        if self.get_token(COMMA_REX) then
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless cur_notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                            controlled_timing_check_event,
                                            timing_check_limit,
                                            notify_register,
                                            nil,nil)
      when WIDTH_TOK
        controlled_timing_check_event = 
          self.controlled_timing_check_event_parse
        self.parse_error("controlled timing check event expected") unless controlled_timing_check_event
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit
        constant_expression = nil
        notify_register = nil
        if self.get_token(COMMA_REX) then
          constant_expression = self.constant_expression_parse
          self.parse_error("constant expression expected") unless constant_expression
          self.parse_error("comma expected") unless self.get_token(COMMA_REX)
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                            controlled_timing_check_event,
                                            timing_check_limit,
                                            constant_expression,
                                            notify_register,
                                            nil)
      when SKEW_TOK
        timing_check_event0 = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event0
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_event1 = self.timing_check_event1
        self.parse_error("timing check event expected") unless timing_check_event1
        timing_check_limit = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit
        notify_register = nil
        if self.get_token(COMMA_REX) then
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless cur_notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                             timing_check_event0.
                                             timing_check_event1,
                                             timing_check_limit,
                                             notify_register,
                                             nil)
      when RECOVERY_TOK
        controlled_timing_check_event = 
          self.controlled_timing_check_event_parse
        self.parse_error("controlled timing check event expected") unless controlled_timing_check_event
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_event = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit = self.timing_check_limit_parse
        self.parse_error("timing check event expected") unless timing_check_limit
        notify_register = nil
        if self.get_token(COMMA_REX) then
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless cur_notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                            controlled_timing_check_event,
                                            timing_check_event,
                                            timing_check_limit,
                                            notify_register,
                                            nil)
      when SETUPHOLD_TOK
        timing_check_event0 = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event0
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_event1 = self.timing_check_event_parse
        self.parse_error("timing check event expected") unless timing_check_event1
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit0 = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit0
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        timing_check_limit1 = self.timing_check_limit_parse
        self.parse_error("timing check limit expected") unless timing_check_limit1
        self.parse_error("comma expected") unless self.get_token(COMMA_REX)
        notify_register = nil
        if self.get_token(COMMA_REX) then
          notify_register = self.notify_register_parse
          self.parse_error("identifier expected") unless cur_notify_register
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.system_timing_check_hook(tok,
                                             timing_check_event0,
                                             timing_check_event1,
                                             timing_check_limit0,
                                             timing_check_limit1,
                                             notify_register)
      else
        return nil
      end
    end

    def system_timing_check_hook(tok,arg0,arg1,arg2,arg3,arg4)
      return AST[:system_timing_check,
                 tok,arg0,arg1,arg2,arg3,arg4 ]
    end


    RULES[:timing_check_event] = <<-___
<timing_check_event>
	::= <timing_check_event_control>? <specify_terminal_descriptor>
		<&&& <timing_check_condition>>?
___

    def timing_check_event_parse
      parse_state = self.state
      timing_check_event_control = self.timing_check_event_control_parse
      specify_terminal_descriptor = self.specify_terminal_descriptor_parse
      unless specify_terminal_descriptor then
        self.state = parse_state
        return nil
      end
      unless self.get_token(AND_AND_AND_REX) then
        return self.timing_check_event_hook(timing_check_event_control,
                                            specify_terminal_descriptor,
                                            nil)
      end
      timing_check_condition = self.timing_check_condition_parse
      self.parse_error("timing check condition expected") unless timing_check_condition
      return self.timing_check_event_hook(timing_check_event_control,
                                          specify_terminal_descriptor,
                                          timing_check_condition)
    end

    def timing_check_event_hook(timing_check_event_control,
                                specify_terminal_descriptor,
                                timing_check_condition)
      return AST[:timing_check_event, timing_check_event_control,
                 specify_terminal_descriptor,
                 timing_check_condition ]
    end


    RULES[:specify_terminal_descriptor] = <<-___
<specify_terminal_descriptor>
	::= <specify_input_terminal_descriptor>
	||=<specify_output_terminal_descriptor>
___

    def specify_terminal_descriptor_parse
      specify_input_terminal_descriptor = 
        self.specify_input_terminal_descriptor_parse
      if specify_input_terminal_descriptor then
        return self.specify_terminal_descriptor(
          specify_input_terminal_descriptor)
      end
      specify_output_terminal_descriptor = 
        self.specify_otuput_terminal_descriptor_parse
      unless specify_output_terminal_descriptor then
        return nil
      end
      return self.specify_terminal_descriptor_hook(
        specify_output_terminal_descriptor)
    end

    def specify_terminal_descriptor_hook(specify_terminal_descriptor)
      return AST[:specify_terminal_descriptor, specify_terminal_descriptor]
    end


    RULES[:controlled_timing_check_event] = <<-___
<controlled_timing_check_event>
	::= <timing_check_event_control> <specify_terminal_descriptor>
		<&&&  <timing_check_condition>>?
___

    def controlled_timing_check_event_parse
      parse_state = self.state
      timing_check_event_control = self.timing_check_event_control_parse
      return nil unless timing_check_event_control
      specify_terminal_descriptor = self.specify_terminal_descriptor_parse
      unless specify_terminal_descriptor then
        self.state = parse_state
        return nil
      end
      unless self.get_token(AND_AND_AND_REX) then
        return self.controlled_timing_check_event_hook(
          timing_check_event_control,
          specify_terminal_descriptor,
          nil)
      end
      timing_check_condition = self.timing_check_condition_parse
      self.parse_error("timing check condition expected") unless timing_check_condition
      return self.controlled_timing_check_event_hook(
        timing_check_event_control,
        specify_terminal_descriptor,
        timing_check_condition)
    end

    def controlled_timing_check_event_hook(
        timing_check_event_control,
        specify_terminal_descriptor,
        timing_check_condition)
      return AST[:controlled_timing_check_event,
                 timing_check_event_control,
                 specify_terminal_descriptor,
                 timing_check_condition ]
    end


    RULES[:timing_check_event_control] = <<-___
<timing_check_event_control>
	::= posedge
	||= negedge
	||= <edge_control_specifier>
___

    def timing_check_event_control_parse
      tok = self.get_token(POSEDGE_NEGEDGE_REX)
      if tok then
        return self.timing_check_event_control_hook(tok)
      end
      edge_control_specifier = self.edge_control_specifier_parse
      return nil unless edge_control_specifier
      return self.timing_check_event_control_hook(edge_control_specifier)
    end

    def timing_check_event_control_hook(edge_control_specifier)
      return AST[:timing_check_event_control, event_control_specifier ]
    end


    RULES[:edge_control_specifier] = <<-___
<edge_control_specifier>
	::= edge  [ <edge_descriptor><,<edge_descriptor>>*]
___

    def edge_control_specifier_parse
      unless self.get_token(EDGE_REX) then
        return nil
      end
      self.parse_error("opening bracket expected") unless self.get_token(OPEN_BRA_REX)
      cur_edge_descriptor = self.edge_descriptor_parse
      self.parse_error("edge descriptor expected") unless cur_edge_descriptor
      edge_descriptors = [ cur_edge_descriptor ]
      loop do
        if self.get_token(COMMA_REX) then
          break
        end
        cur_edge_descriptor = self.edge_descriptor_parse
        self.parse_error("edge descriptor expected") unless cur_edge_descriptor
        edge_descriptors << cur_edge_descriptor
      end
      self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
      return self.edge_control_specifier_hook(edge_descriptors)
    end

    def edge_control_specifier_hook(edge_descriptors)
      return AST[:edge_control_specifier, edge_descriptors ]
    end


    RULES[:edge_descriptor] = <<-___
<edge_descriptor>
	::= 01
	||= 10
	||= 0x
	||= x1
	||= 1x
	||= x0
___

    def edge_descriptor_parse
      tok = self.get_token(EDGE_DESCRIPTOR_REX)
      if tok then
        return self.edge_descriptor_hook(tok)
      end
      return nil
    end

    def edge_descriptor_hook(tok)
      return AST[:edge_descriptor, tok ]
    end


    RULES[:timing_check_condition] = <<-___
<timing_check_condition>
	::= <scalar_timing_check_condition>
	||= ( <scalar_timing_check_condition> )
___

    def timing_check_condition_parse
      scalar_timing_check_condition = nil
      if self.get_token(OPEN_PAR_REX) then
        scalar_timing_check_condition = 
          self.scalar_timig_check_condition_parse
        unless scalar_timing_check_condition then
          return nil
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      else
        scalar_timing_check_condition = 
          self.scalar_timig_check_condition_parse
        return nil unless scalar_timing_check_condition
      end
      return self.timing_check_condition_hook(scalar_timing_check_condition)
    end

    def timing_check_condition_hook(scalar_timing_check_condition)
      return AST[:timing_check_condition,
                 scalar_timing_check_condition ]
    end


    RULES[:scalar_timing_check_condition] = <<-___
<scalar_timing_check_condition>
	::= <scalar_expression>
	||= ~<scalar_expression>
	||= <scalar_expression> == <scalar_constant>
	||= <scalar_expression> === <scalar_constant>
	||= <scalar_expression> != <scalar_constant>
	||= <scalar_expression> !== <scalar_constant>
___

    def scalar_timing_check_condition_parse
      if self.get_token(TILDE_REX) then
        scalar_expression = self.scalar_expression_parse
        self.parse_error("scalar expression expected") unless scalar_expression
        return self.scalar_timing_check_condition_hook(TILDE_TOK,
                                                       scalar_expression,
                                                       nil)
      end
      scalar_expression = self.scalar_expression_parse
      return nil unless scalar_expression
      tok = self.get_token(SCALAR_TIMING_CHECK_CONDITION_REX)
      if tok then
        scalar_constant = self.scalar_constant_parse
        self.parse_error("scalar constant expected") unless scalar_constant
        return self.scalar_timing_check_condition(tok,
                                                  scalar_expression,
                                                  scalar_constant)
      end
      return self.scalar_timing_check_condition_hook(scalar_expression,
                                                     nil,nil)
    end

    def scalar_timing_check_condition_hook(scalar_expression__tok,
                                           scalar_expression,
                                           scalar_constant)
      return AST[:scalar_timing_check_condition,
                 scalar_expression__tok,
                 scalar_expression,scalar_constant ]
    end


    RULES[:scalar_expression] = <<-___
<scalar_expression>
	A scalar expression is a one bit net or a bit-select of an expanded vector net.
___

    def scalar_expression_parse
      # *Auth*: assume to be a plain expression: actually it should be
      # one-bit.
      # This is assumed to be checked at the AST level, for example
      # by redefinition the hook method.
      expression = self.expression_parse
      return nil unless expression
      return self.scalar_expression_hook(expression)
    end

    def scalar_expression_hook(expression)
      return AST[:scalar_expression, expression ]
    end


    RULES[:timing_check_list] = <<-___
<timing_check_limit>
	::= <expression>
___

    def timing_check_list_parse
      expression = self.expression_parse
      return nil unless expression
      return self.timing_check_list_hook(expression)
    end

    def timing_check_list_hook(expression)
      return AST[:timing_check_list, expression ]
    end


    RULES[:scalar_constant] = <<-___
<scalar_constant>
	::= 1'b0
	||= 1'b1
	||= 1'B0
	||= 1'B1
	||= 'b0
	||= 'b1
	||= 'B0
	||= 'B1
	||= 1
	||= 0
___

    def scalar_constant_parse
      tok = self.get_token(SCALAR_CONSTANT_REX)
      unless tok then
        return nil
      end
      return self.scalar_constant_hook(tok)
    end

    def scalar_constant_hook(tok)
      return AST[:scalar_constant, tok ]
    end


    RULES[:notify_register] = <<-___
<notify_register>
	::= <identifier>
___

    def notify_register_parse
      identifier = self.identifier_parse
      return nil unless identifier
      return self.notify_register_hook(identifier)
    end

    def notify_register_hook(identifier)
      return AST[:notify_register, identifier ]
    end


    RULES[:level_sensitive_path_declaration] = <<-___
<level_sensitive_path_declaration>
	::= if (<conditional_port_expression>)
		(<specify_input_terminal_descriptor> <polarity_operator>? =>
		<specify_output_terminal_descriptor>) = <path_delay_value>;
	||= if (<conditional_port_expression>)
		(<list_of_path_inputs> <polarity_operator>? *>
		<list_of_path_outputs>) = <path_delay_value>;
	(Note: The following two symbols are literal symbols, not syntax description conventions:)
		*>	=>
___
    
    def level_sensitive_path_declaration_parse
      unless self.get_token(IF_REX) then
        return nil
      end
      self.parse_error("opening parenthesis expected") unless self.get_tokeen(OPEN_PAR_REX)
      conditional_port_expression = self.conditional_port_expression_parse
      self.parse_error("conditional port expression expected") unless conditional_port_expression
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      self.parse_error("openning parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      parse_state = self.state
      specify_input_terminal_descriptor = 
        self.specify_input_terminal_descriptor_parse
      self.parse_error("input terminal descriptor expected") unless specify_input_terminal_descriptor
      polarity_operator = self.polarity_operator_parse
      if self.get_token(SEND_ARROW_REX) then
        # This is the right rule, go no
        specify_output_terminal_descriptor = 
          self.specify_output_terminal_descriptor_parse
        self.parse_error("output terminal descriptor expected") unless specify_output_terminal_descriptor
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
        path_delay_value = self.path_delay_value_parse
        self.parse_error("path delay value expected") unless path_delay_value
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.level_sensitive_path_declaration_hook(
          conditional_port_expression,
          specify_input_terminal_descriptor, polarity_operator, tok,
          specify_output_terminal_descriptor, path_delay_value)
      else
        # This is maybe the other rule, rewind.
        self.state = parse_state
        list_of_path_inputs = self.list_of_path_inputs_parse
        self.parse_error("list of path inputs expected") unless list_of_path_inputs
        polarity_operator = self.polarity_operator_parse
        self.parse_error("'*>' expected") unless self.get_token(ASTERISK_ARROW_REX)
        list_of_path_outputs = self.list_of_path_outputs_parse
        self.parse_error("list of path outputs expected") unless list_of_path_outputs
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("equal expected") unless self.get_token(EQUAL_TOK_REX)
        path_delay_value = self.path_delay_value_parse
        self.parse_error("path delay value expected") unless path_delay_value
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.level_sensitive_path_declaration_hook(
          conditional_port_expression,
          list_of_path_inputs, polarity_operator, tok,
          list_of_path_outputs, path_delay_value)
      end
    end

    def level_sensitive_path_declaration_hook(
      conditional_port_expression,
      input, polarity_operator, tok, output, path_delay_value)
      return AST[:level_sensitive_path_declaration,
                 input, polarity_operator, tok, output, path_delay_value ]
    end


    RULES[:conditional_port_expression] = <<-___
<conditional_port_expression>
	::= <port_reference>
	||= <UNARY_OPERATOR><port_reference>
	||= <port_reference><BINARY_OPERATOR><port_reference>
___

    def conditional_port_expression_parse
      unary_operator = self.unary_operator_parse
      port_reference0 = self.port_reference_parse
      if !port_reference0 then
        self.parse_error("there should be any of [#{UNARY_OPERATOR_TOKS.join(",")}] here") if unary_operator
        return nil
      end
      if unary_operator then
        return self.conditional_port_expression_hook(unary_operator,
                                                     port_reference0,nil)
      end
      binary_operator = self.binary_operator_parse
      if binary_operator then
        port_reference1 = self.port_reference_parse
        self.parse_error("port reference expected here") unless port_reference1
        return self.conditional_port_expression_hook(port_reference0,
                                                     binary_operator,
                                                     port_reference1)
      else
        return self.conditional_port_expression_hook(port_reference0,
                                                     nil,nil)
      end
    end

    def conditional_port_expression_hook(port_reference__unary_operator,
                                         binary_operator,
                                         port_reference)
      return AST[:conditional_port_expression,
                 port_reference__unary_operator,
                 binary_operator,
                 port_reference ]
    end


    RULES[:polarity_operator] = <<-___
<polarity_operator>
	::= +
	||= -
___

    def polarity_operator_parse
      tok = self.get_token(POLARITY_OPERATOR_REX)
      if tok then
        return polarity_operator_hook(tok)
      else
        return nil
      end
    end

    def polarity_operator_hook(tok)
      return AST[:polarity_operator, tok ]
    end


    RULES[:edge_sensitive_path_declaration] = <<-___
<edge_sensitive_path_declaration>
	::= <if (<expression>)>? (<edge_identifier>?
		<specify_input_terminal_descriptor> =>
		(<specify_output_terminal_descriptor> <polarity_operator>?
		: <data_source_expression>)) = <path_delay_value>;
	||= <if (<expression>)>? (<edge_identifier>?
		<specify_input_terminal_descriptor> *>
		(<list_of_path_outputs> <polarity_operator>?
		: <data_source_expression>)) =<path_delay_value>;
___

    def edge_sensitive_path_declaration_parse
      parse_state = self.state
      unless self.get_token(IF_REX) then
        self.state = parse_state
        return nil
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      expression = self.expression_parse
      edge_identifier = self.edge_identifier_parse
      specify_input_terminal_descriptor = 
        self.specify_input_terminal_descriptor_parse
      if !specify_input_terminal_descriptor then
        self.state = parse_state
        return nil
      end
      if self.get_token(SEND_ARROW_REX) then
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        specify_output_terminal_descriptor =
          self.specify_output_terminal_Descriptor_parse
        self.parse_error("output terminal descriptor expected") unless specify_output_terminal_descriptor
        polarity_operator = self.polarity_operator_parse
        self.parse_error("colon expected") unless self.get_token(COLON_REX)
        data_source_expression = self.data_source_expression_parse
        self.parse_error("data source expression expected") unless data_source_expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
        path_delay_value = self.path_delay_value_parse
        self.parse_error("path delay value expected") unless path_delay_value
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.edge_sensitive_path_declaration_hook(
          expression,edge_identifier,specify_input_terminal_descriptor,
          tok,specify_output_terminal_descriptor,polarity_operator,
          data_source_expression,path_delay_value)
      elsif tok == ASTERISK_ARROW_TOK then
        self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
        list_of_path_outputs = self.list_of_path_outputs_parse
        self.parse_error("list of path outputs expected") unless list_of_path_outputs
        polarity_operator = self.polarity_operator_parse
        self.parse_error("colon expected") unless self.get_token(COLON_REX)
        data_source_expression = self.data_source_expression_parse
        self.parse_error("data source expression expected") unless data_source_expression
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
        path_delay_value = self.path_delay_value_parse
        self.parse_error("path delay value expected") unless path_delay_value
        self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
        return self.edge_sensitive_path_declaration_hook(
          expression,edge_identifier,specify_input_terminal_descriptor,
          tok,list_of_path_outputs,polarity_operator,
          data_source_expression,path_delay_value)
      else
        self.state = parse_state
        return nil
      end
    end

    def edge_sensitive_path_declaration_hook(
      expression, edge_identifier, specify_input_terminal_descriptor, tok,
      specify_output_terminal_descriptor__list_of_path_outputs,
      polarity_operator, data_source_expression, path_delay_value)
      return AST[:edge_sensitive_path_declaration,
                 expression,edge_identifier,
                 specify_input_terminal_descriptor,tok,
                 spcify_output_terminal_descriptor__list_of_path_outputs,
                 polarity_operator,data_source_expression,path_delay_value]
    end


    RULES[:data_source] = <<-___
<data_source_expression>
	Any expression, including constants and lists. Its width must be one bit or
	equal to the  destination's width. If the destination is a list, the data
	source must be as wide as the sum of  the bits of the members.
___

    def data_source_parse
      # *Auth*: the check are assumed to be done at the AST level.
      #  If required, please redefine data_source_hook
      expression = self.expression_parse
      return nil unless expression
      return self.data_source_hook(expression)
    end

    def data_source_hook(expression)
      return AST[:data_source, expression ]
    end


    RULES[:edge_identifier] = <<-___
<edge_identifier>
	::= posedge
	||= negedge
___

    def edge_identifier_parse
      tok = self.get_token(EDGE_IDENTIFIER_REX)
      if tok then
        return self.edge_identifier_hook(tok)
      else
        return nil
      end
    end

    def edge_identifier_hook(tok)
      return AST[:edge_identifier, tok ]
    end


    RULES[:sdpd] = <<-___
<sdpd>
	::=if(<sdpd_conditional_expression>)<path_description>=<path_delay_value>;
___

    def sdpd_parse
      parse_state = self.state
      unless self.get_token(IF_REX) then
        self.state = parse_state
        return nil
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      sdpd_conditional_expression = self.sdpd_conditional_expression_parse
      if !sdpd_conditional_expression then
        self.state = parse_state
        return nil
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      path_description = self.path_description_parse
      self.parse_error("path description expected") unless path_description
      self.parse_error("equal expected") unless self.get_token(EQUAL_REX)
      path_delay_value = self.path_delay_value_parse
      self.parse_error("path delay value expected") unless path_delay_value
      self.parse_error("semicolon expected") unless self.get_token(SEMICOLON_REX)
      return sdpd_hook(sdpd_conditional_expression,path_description,
                       path_delay_value)
    end

    def sdpd_hook(sdpd_conditional_expression, path_description,
                  path_delay_value)
      return AST[:sdpd, 
                 sdpd_conditional_expression,path_description,
                 path_delay_value ]
    end


    RULES[:sdpd_conditional_expression] = <<-___
<sdpd_conditional_expression>
	::=<expression><BINARY_OPERATOR><expression>
	||=<UNARY_OPERATOR><expression>
___

    def sdpd_conditional_expression_parse
      unary_operator = self._UNARY_OPERATOR_parse
      if unary_operator then
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        return self.sdpd_conditional_expression_hook(unary_operator,
                                                     expression,nil)
      else
        expression0 = self.expression_parse
        return nil unless expression0
        binary_operator = self._BINARY_OPERATOR_parse
        self.parse_error("one of [#{BINARY_OPERATOR_TOKS.join(",")}] expected") unless binary_operator
        expression1 = self.expression_parse
        self.parse_error("expression expected") unless expression1
        return self.sdpd_conditional_expression_hook(expression0,
                                                     binary_operator,
                                                     expression1)
      end
    end

    def sdpd_conditional_expression_hook(unary_operator__expression,
                                         expression__binary_operator,
                                         expression)
      return AST[:sdpd_conditionla_expression,
                 unary_operator__expression,
                 expression__binary_operator,
                 expression ]
    end


    # 7. Expressions


    RULES[:lvalue] = <<-___
<lvalue>
	::= <identifier>
	||= <identifier> [ <expression> ]
	||= <identifier> [ <constant_expression> : <constant_expression> ]
	||= <concatenation>
___

    def lvalue_parse
      concatenation = self.concatenation_parse
      if concatenation then
        return self.lvalue_hook(concatenation,nil,nil)
      end
      identifier = self.identifier_parse
      return nil unless identifier
      unless self.get_token(OPEN_BRA_REX) then
        return self.lvalue_hook(identifier,nil,nil)
      end
      parse_state = self.state
      constant_expression0 = self.constant_expression_parse
      if !constant_expression0 or !self.get_token(COLON_REX) then
        # Not constant_expression : constant_expression, rewind.
        self.state = parse_state
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
        return self.lvalue_hook(identifier,expression,nil)
      end
      self.parse_error("constant expression expected") unless constant_expression0
      constant_expression1 = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression1
      self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
      return self.lvalue_hook(identifier,
                              constant_expression0, constant_expression1)
    end

    def lvalue_hook(identifier__concatenation,
                    expression__constant_expression, constant_expression)
      return AST[:lvalue, 
                 identifier__concatenation,
                 expression__constant_expression,constant_expression ]
    end


    RULES[:constant_expression] = <<-___
<constant_expression>
	::=<expression>
___

    def constant_expression_parse
      expression = self.expression_parse
      return nil unless expression
      return self.constant_expression_hook(expression)
    end

    def constant_expression_hook(expression)
      return AST[:constant_expression, expression ]
    end


    RULES[:mintypmax_expression] = <<-___
<mintypmax_expression>
	::= <expression>
	||= <expression> : <expression> : <expression>
___

    def mintypmax_expression_parse
      expression0 = self.expression_parse
      return nil unless expression0
      unless self.get_token(COLON_REX) then
        return self.mintypmax_expression_hook(expression0,nil,nil)
      end
      expression1 = self.expression_parse
      self.parse_error("expression expected") unless expression1
      self.parse_error("colon expected") unless self.get_token(COLON_REX)
      expression2 = self.expression_parse
      self.parse_error("expression expected") unless expression2
      return self.mintypmax_expression_hook(expression0,expression1,
                                            expression2)
    end

    def mintypmax_expression_hook(expression0, expression1, expression2)
      return AST[:mintypmax_expression,
                 expression0,expression1,expression2 ]
    end


    RULES[:expression] = <<-___
<expression>
	::= <primary>
	||= <UNARY_OPERATOR> <primary>
	||= <expression> <BINARY_OPERATOR> <expression>
	||= <expression> <QUESTION_MARK> <expression> : <expression>
	||= <STRING>
___

    # Auth: old version compatible with the bfn rules, but not
    # parsable.
    # def expression_parse
    #   string = self._STRING_parse
    #   if string then
    #     return self.expression_hook(string,nil,nil,nil)
    #   end
    #   unary_operator = self._UNARY_OPERATOR_parse
    #   if unary_operator then
    #     primary = self.primary_parse
    #     self.parse_error("primary expression expected") unless primary
    #     return self.primary_hook(unary_operator,primary,nil,nil)
    #   end
    #   parse_state = self.state
    #   expression0 = self.expression_parse
    #   if expression0 then
    #     binary_operator = self.BINARY_OPERATOR_parse
    #     if binary_operator then
    #       expression1 = self.expression_parse
    #       self.parse_error("expression expected") unless expression1
    #       return self.expression_hook(expression0,
    #                                   binary_operator,expression1,nil)
    #     end
    #     question_mark = self.QUESTION_MARK_parse
    #     if question_mark then
    #       expression1 = self.expression_parse
    #       self.parse_error("expression expected") unless expression1
    #       self.parse_error("colon expected") unless self.get_token(COLON_REX)
    #       expression2 = self.expression_parse
    #       return self.expression_hook(expression0,
    #                                   question_mark,
    #                                   expression1,expression2)
    #     end
    #   end
    #   # It was not a binary or trinary expression, rewind.
    #   self.state = parse_state
    #   primary = self.primary_parse
    #   return nil unless primary
    #   return self.expression_hook(primary,nil,nil,nil)
    # end

    # def expression_hook(string__primary__unary_operator__expression,
    #                     primary__binary_operator__question_mark,
    #                     expression1, expression2)
    #   return AST[:expression,
    #              string__primary__unary_operator__expression,
    #              primary__binary_operator__question_mark,
    #              expression1,expression2 ]
    # end

    # Auth: this rule has no priority handling and is infinitely recurse
    # fix it to:
    # expression
    # ::= condition_term ('?' expression ':' expression)*
    # ||= <STRING>
    #
    # condition_term
    # ::= logic_or_term ('||' expression)*
    #
    # logic_or_term
    # ::= logic_and_term ('&&' expression)*
    #
    # logic_and_term
    # ::= bit_or_term ('|' | '~|' expression)*
    #
    # bit_or_term
    # ::= bit_xor_term ('^' | '~^' expression)*
    #
    # bit_xor_term
    # ::= bit_and_term ('&' | '~&' expression)*
    #
    # bit_and_term 
    # ::= equal_term '==' | '!=' | '===' | '!==' expression
    #
    # equal_term
    # ::= comparison_term '<' | '<=' | '>' | '>=' expression
    #
    # comparison_term
    # ::= shift_term ('<<' | '>>' | '<<<' |'>>>' expression)*
    #
    # shift_term
    # ::= add_term ('+' | '-' expression)*
    #
    # add_term
    # ::= mul_term ('*' | '/' | '%' | '**' expression)*
    #
    # mul_term
    # ::= '+' | '-' | '!' | '~' primary
    # ||= primary

    def expression_parse
      string = self._STRING_parse
      if string then
        return self.expression_hook(string)
      end
      cur_condition_term = self.condition_term_parse
      return nil unless cur_condition_term
      condition_terms = [ cur_condition_term ]
      loop do
        break unless self.get_token(QUESTION_REX)
        condition_terms << QUESTION_TOK
        cur_condition_term = self.condition_term_parse
        self.parse_error("expression expected") unless cur_condition_term
        condition_terms << cur_condition_term
        self.parse_error("colon expected") unless self.get_token(COLON_REX)
        condition_terms << COLON_TOK
        cur_condition_term = self.condition_term_parse
        self.parse_error("expression expected") unless cur_condition_term
        condition_terms << cur_condition_term
      end
      return expression_hook(condition_terms)
    end

    def expression_hook(string__condition_terms)
      if string__condition_terms.is_a?(Array) and 
          string__condition_terms.size == 1 then
        return string__condition_terms[0]
      else
        return AST[:expression, *string__condition_terms ]
      end
    end

    def condition_term_parse
      cur_logic_or_term = self.logic_or_term_parse
      return nil unless cur_logic_or_term
      logic_or_terms = [ cur_logic_or_term ]
      loop do
        break unless self.get_token(OR_OR_REX)
        logic_or_terms << OR_OR_TOK
        cur_logic_or_term = self.logic_or_term_parse
        self.parse_error("expression expected") unless cur_logic_or_term
        logic_or_terms << cur_logic_or_term
      end
      return condition_term_hook(logic_or_terms)
    end

    def condition_term_hook(logic_or_terms)
      if logic_or_terms.size == 1 then
        return logic_or_terms[0]
      else
        return AST[:expression, *logic_or_terms ]
      end
    end

    def logic_or_term_parse
      cur_logic_and_term = self.logic_and_term_parse
      return nil unless cur_logic_and_term
      logic_and_terms = [ cur_logic_and_term ]
      loop do
        break unless self.get_token(AND_AND_REX)
        logic_and_terms << AND_AND_TOK
        cur_logic_and_term = self.logic_and_term_parse
        self.parse_error("expression expected") unless cur_logic_and_term
        logic_and_terms << cur_logic_and_term
      end
      return logic_or_term_hook(logic_and_terms)
    end

    def logic_or_term_hook(logic_and_terms)
      if logic_and_terms.size == 1 then
        return logic_and_terms[0]
      else
        return AST[:expression, *logic_and_terms ]
      end
    end

    def logic_and_term_parse
      cur_bit_or_term = self.bit_or_term_parse
      return nil unless cur_bit_or_term
      bit_or_terms = [ cur_bit_or_term ]
      tok = nil
      loop do
        tok = self.get_token(OR_OPERATOR_REX)
        break unless tok
        bit_or_terms << tok
        cur_bit_or_term = self.bit_or_term_parse
        self.parse_error("expression expected") unless cur_bit_or_term
        bit_or_terms << cur_bit_or_term
      end
      return logic_and_term_hook(bit_or_terms)
    end

    def logic_and_term_hook(bit_or_terms)
      if (bit_or_terms.size == 1) then
        return bit_or_terms[0]
      else
        return AST[:expression, *bit_or_terms ]
      end
    end

    def bit_or_term_parse
      cur_bit_xor_term = self.bit_xor_term_parse
      return nil unless cur_bit_xor_term
      bit_xor_terms = [ cur_bit_xor_term ]
      tok = nil
      loop do
        tok = self.get_token(XOR_OPERATOR_REX)
        break unless tok
        bit_xor_terms << tok
        cur_bit_xor_term = self.bit_xor_term_parse
        self.parse_error("expression expected") unless cur_bit_xor_term
        bit_xor_terms << cur_bit_xor_term
      end
      return bit_or_term_hook(bit_xor_terms)
    end

    def bit_or_term_hook(bit_xor_terms)
      if bit_xor_terms.size == 1 then
        return bit_xor_terms[0]
      else
        return AST[:expression, *bit_xor_terms ]
      end
    end

    def bit_xor_term_parse
      cur_bit_and_term = self.bit_and_term_parse
      return nil unless cur_bit_and_term
      bit_and_terms = [ cur_bit_and_term ]
      tok = nil
      loop do
        tok = self.get_token(AND_OPERATOR_REX)
        break unless tok
        bit_and_terms << tok
        cur_bit_and_term = self.bit_and_term_parse
        self.parse_error("expression expected") unless cur_bit_and_term
        bit_and_terms << cur_bit_and_term
      end
      return bit_xor_term_hook(bit_and_terms)
    end

    def bit_xor_term_hook(bit_and_terms)
      if bit_and_terms.size == 1 then
        return bit_and_terms[0]
      else
        return AST[:expression, *bit_and_terms ]
      end
    end

    def bit_and_term_parse
      cur_equal_term = self.equal_term_parse
      return nil unless cur_equal_term
      equal_terms = [ cur_equal_term ]
      tok = nil
      loop do
        tok = self.get_token(EQUAL_OPERATOR_REX)
        break unless tok
        equal_terms << tok
        cur_equal_term = self.equal_term_parse
        self.parse_error("expression expected") unless cur_equal_term
        equal_terms << cur_equal_term
      end
      return bit_and_term_hook(equal_terms)
    end

    def bit_and_term_hook(equal_terms)
      if equal_terms.size == 1 then
        return equal_terms[0]
      else
        return AST[:expression, *equal_terms ]
      end
    end

    def equal_term_parse
      cur_comparison_term = self.comparison_term_parse
      return nil unless cur_comparison_term
      comparison_terms = [ cur_comparison_term ]
      tok = nil
      loop do
        tok = self.get_token(COMPARISON_OPERATOR_REX)
        break unless tok
        comparison_terms << tok
        cur_comparison_term = self.comparison_term_parse
        self.parse_error("expression expected") unless cur_comparison_term
        comparison_terms << cur_comparison_term
      end
      return equal_term_hook(comparison_terms)
    end

    def equal_term_hook(comparison_terms)
      if comparison_terms.size == 1 then
        return comparison_terms[0]
      else
        return AST[:expression, *comparison_terms ]
      end
    end

    def comparison_term_parse
      cur_shift_term = self.shift_term_parse
      return nil unless cur_shift_term
      shift_terms = [ cur_shift_term ]
      tok = nil
      loop do
        tok = self.get_token(SHIFT_OPERATOR_REX)
        break unless tok
        shift_terms << tok
        cur_shift_term = self.shift_term_parse
        self.parse_error("expression expected") unless cur_shift_term
        shift_terms << cur_shift_term
      end
      return comparison_term_hook(shift_terms)
    end

    def comparison_term_hook(shift_terms)
      if shift_terms.size == 1 then
        return shift_terms[0]
      else
        return AST[:expression, *shift_terms ]
      end
    end

    def shift_term_parse
      cur_add_term = self.add_term_parse
      return nil unless cur_add_term
      add_terms = [ cur_add_term ]
      tok = nil
      loop do
        tok = self.get_token(ADD_OPERATOR_REX)
        break unless tok
        add_terms << tok
        cur_add_term = self.add_term_parse
        self.parse_error("expression expected") unless cur_add_term
        add_terms << cur_add_term
      end
      return shift_term_hook(add_terms)
    end

    def shift_term_hook(add_terms)
      if add_terms.size == 1 then
        return add_terms[0]
      else
        return AST[:expression, *add_terms ]
      end
    end

    def add_term_parse
      cur_mul_term = self.mul_term_parse
      return nil unless cur_mul_term
      mul_terms = [ cur_mul_term ]
      tok = nil
      loop do
        tok = self.get_token(MUL_OPERATOR_REX)
        break unless tok
        mul_terms << tok
        cur_mul_term = self.mul_term_parse
        self.parse_error("expression expected") unless cur_mul_term
        mul_terms << cur_mul_term
      end
      return add_term_hook(mul_terms)
    end

    def add_term_hook(mul_terms)
      if mul_terms.size == 1 then
        return mul_terms[0]
      else
        return AST[:expression, *mul_terms ]
      end
    end

    def mul_term_parse
      tok = self.get_token(UNARY_OPERATOR_REX)
      if tok then
        primary = self.primary_parse
        self.parse_error("expression expected") unless primary
        return mul_term_hook([tok,primary])
      else
        primary = self.primary_parse
        return nil unless primary
        return mul_term_hook([primary])
      end
    end

    def mul_term_hook(unary_terms)
      return AST[:expression, *unary_terms ]
    end


    RULES[:UNARY_OPERATOR] = <<-___
<UNARY_OPERATOR> is one of the following tokens:
	+  -  !  ~  &  ~&  |  ^|  ^  ~^
___

    def _UNARY_OPERATOR_parse
      tok = self.get_token(UNARY_OPERATOR_REX)
      if tok then
        return self._UNARY_OPERATOR_hook(tok)
      end
      return nil
    end

    def _UNARY_OPERATOR_hook(tok)
      return AST[:UNARY_OPERATOR, tok ]
    end


    RULES[:BINARY_OPERATOR] = <<-___
<BINARY_OPERATOR> is one of the following tokens:
	+  -  *  /  %  ==  !=  ===  !==  &&  ||  <  <=  >  >=  &  |  ^  ^~  >>  <<
___

    def _BINARY_OPERATOR_parse
      tok = self.get_token(BINARY_OPERATOR_REX)
      if tok then
        return self._BINARY_OPERATOR_hook(tok)
      end
      return nil
    end

    def _BINARY_OPERATOR_hook(tok)
      return AST[:BINARY_OPERATOR, tok ]
    end


    RULES[:QUESTION_MARK] = <<-___
<QUESTION_MARK> is ? (a literal question mark).
___

    def _QUESTION_MARK_parse
      if self.get_token(QUESTION_REX) then
        return _QUESTION_MARK_hook(QUESTION_TOK)
      end
      return nil
    end

    def _QUESTION_MARK_hook(tok)
      return AST[:QUESTION_MARK, tok ]
    end


    RULES[:STRING] = <<-___
<STRING> is text enclosed in "" and contained on one line.
___

    def _STRING_parse
      string = self.get_token(STRING_REX)
      if string then
        return _STRING_hook(string)
      end
      return nil
    end

    def _STRING_hook(string)
      return AST[:STRING, string ]
    end


    RULES[:primary] = <<-___
<primary>
	::= <number>
	||= <identifier>
	||= <identifier> [ <expression> ]
	||= <identifier> [ <constant_expression> : <constant_expression> ]
	||= <concatenation>
	||= <multiple_concatenation>
	||= <function_call>
	||= ( <mintypmax_expression> )
___

    def primary_parse
      number = self.number_parse
      if number then
        return self.primary_hook(number,nil,nil)
      end
      multiple_concatenation = self.multiple_concatenation_parse
      if multiple_concatenation then
        return self.primary_hook(multiple_concatenation,nil,nil)
      end
      concatenation = self.concatenation_parse
      if concatenation then
        return self.primary_hook(concatenation,nil,nil)
      end
      function_call = self.function_call_parse
      if function_call then
        return self.primary_hook(function_call,nil,nil)
      end
      if self.get_token(OPEN_PAR_REX) then
        mintypmax_expression = self.mintypmax_expression_parse
        if !mintypmax_expression then
          return nil
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.primary_hook(mintypmax_expression,nil,nil)
      end
      identifier = self.identifier_parse
      return nil unless identifier
      unless self.get_token(OPEN_BRA_REX) then
        return self.primary_hook(identifier,nil,nil)
      end
      parse_state = self.state
      constant_expression0 = self.constant_expression_parse
      if !constant_expression0 or !self.get_token(COLON_REX) then
        # Not constant_expression : constant_expression, rewind
        self.state = parse_state
        expression = self.expression_parse
        self.parse_error("expression expected") unless expression
        self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
        return self.primary_hook(identifier,expression,nil)
      end
      constant_expression1 = self.constant_expression_parse
      self.parse_error("constant expression expected") unless constant_expression1
      self.parse_error("closing bracket expected") unless self.get_token(CLOSE_BRA_REX)
      return self.primary_hook(identifier,
                               constant_expression0,constant_expression1)
    end

    def primary_hook(base,
                     expression__constant_expression,
                     constant_expression)
      return AST[:primary,
                 base, expression__constant_expression,
                 constant_expression ]
    end


    RULES[:number] = <<-___
<number>
	::= <DECIMAL_NUMBER>
	||= <UNSIGNED_NUMBER>? <BASE> <UNSIGNED_NUMBER>
	||= <DECIMAL_NUMBER>.<UNSIGNED_NUMBER>
	||= <DECIMAL_NUMBER><.<UNSIGNED_NUMBER>>?
		E<DECIMAL_NUMBER>
	||= <DECIMAL_NUMBER><.<UNSIGNED_NUMBER>>?
		e<DECIMAL_NUMBER>
	(Note: embedded spaces are illegal in Verilog numbers, but embedded underscore
	characters can be used for spacing in any type of number.)
___

    def number_parse
      # *Auth*: I think there is a mistake in the BNF:
      # <UNSIGNED_NUMBER>? <BASE> <UNSIGNED_NUMBER> should be:
      # <UNSIGNED_NUMBER>? <BASE> <NUMBER>
      parse_state = self.state
      unsigned_number = self._UNSIGNED_NUMBER_parse
      base = self._BASE_parse
      if base then
        number = self._NUMBER_parse(base[0])
        self.parse_error("number expected") unless number
        return self.number_hook(unsigned_number,base,number)
      end
      # Not a based number, rewind.
      self.state = parse_state
      decimal_number0 = self._DECIMAL_NUMBER_parse
      return nil unless decimal_number0
      if self.get_token(DOT_REX) then
        unsigned_number = self._UNSIGNED_NUMBER_parse
        if self.get_token(E_REX) then
          decimal_number1 = self._DECIMAL_NUMBER_parse
          self.parse_error("decimal number expected") unless decimal_number1
          return self.number_hook(decimal_number0,unsigned_number,
                                  decimal_number1)
        end
        self.parse_error("unsigned number expected") unless unsigned_number
        return self.number_hook(decimal_number0,unsigned_number,nil)
      end
      return self.number_hook(decimal_number0,nil,nil)
    end

    def number_hook(unsigned_number__decimal_number,
                    base__unsigned_number,
                    decimal_number)
      return AST[:number,
                 unsigned_number__decimal_number,
                 base__unsigned_number,
                 decimal_number ]
    end


    RULES[:DECIMAL_NUMBER] = <<-___
<DECIMAL_NUMBER>
	::= A number containing a set of any of the following characters, optionally preceded by + or -
	 	0123456789_
___

    def _DECIMAL_NUMBER_parse
      tok = self.get_token(DECIMAL_NUMBER_REX)
      if tok then
        return self._DECIMAL_NUMBER_hook(tok)
      end
      return nil
    end

    def _DECIMAL_NUMBER_hook(tok)
      return AST[:DECIMAL_NUMBER, tok ]
    end


    RULES[:UNSIGNED_NUMBER] = <<-___
<UNSIGNED_NUMBER>
	::= A number containing a set of any of the following characters:
	        0123456789_
___

    def _UNSIGNED_NUMBER_parse
      tok = self.get_token(UNSIGNED_NUMBER_REX)
      if tok then
        return self._UNSIGNED_NUMBER_hook(tok)
      end
      return nil
    end

    def _UNSIGNED_NUMBER_hook(tok)
      return AST[:UNSIGNED_NUMBER, tok ]
    end


    RULES[:NUMBER] = <<-___
<NUMBER>
	Numbers can be specified in decimal, hexadecimal, octal or binary, and may
	optionally start with a + or -.  The <BASE> token controls what number digits
	are legal.  <BASE> must be one of d, h, o, or b, for the bases decimal,
	hexadecimal, octal, and binary respectively. A number can contain any set of
	the following characters that is consistent with <BASE>:
	0123456789abcdefABCDEFxXzZ?
___

    # Auth: contrary to what the rule says, NUMBER should also accept '_',
    # added to the regular expression.
    # Also, there is no sign (+ or -) in the number, removed.
    def _NUMBER_parse(base)
      tok = self.get_token(NUMBER_REX)
      case(base)
      when Q_b_TOK, Q_B_TOK
        # Binary case.
        if tok =~ /^[0-1xXzZ\?][_0-1xXzZ\?]*$/ then
          return self._NUMBER_hook(tok)
        end
        self.parse_error("malformed number")
      when Q_o_TOK, Q_O_TOK
        # Octal case.
        if tok =~ /^[0-7xXzZ\?][_0-7xXzZ\?]*$/ then
          return self._NUMBER_hook(tok)
        end
        self.parse_error("malformed number")
      when Q_d_TOK, Q_D_TOK
        # Decimal case.
        if tok =~ /^[0-9xXzZ\?][_0-9xXzZ\?]*$/ then
          return self._NUMBER_hook(tok)
        end
        self.parse_error("malformed number")
      when Q_h_TOK, Q_H_TOK
        # hexecimal case.
        if tok =~ /^[0-9a-fA-FxXzZ\?][_0-9a-fA-FxXzZ\?]*$/ then
          return self._NUMBER_hook(tok)
        end
        self.parse_error("malformed number")
      end
      raise "Internal error: should not be there!"
    end

    def _NUMBER_hook(tok)
      return AST[:NUMBER, tok ]
    end


    RULES[:BASE] = <<-___
<BASE> is one of the following tokens:
	'b   'B   'o   'O   'd   'D   'h   'H
___

    def _BASE_parse
      tok = self.get_token(BASE_REX)
      if tok then
        return _BASE_hook(tok)
      end
      return nil
    end

    def _BASE_hook(tok)
      return AST[:BASE, tok]
    end


    RULES[:concatenation] = <<-___
<concatenation>
	::= { <expression> <,<expression>>* }
___

    def concatenation_parse
      parse_state = self.state
      unless self.get_token(OPEN_CUR_REX) then
        self.state = parse_state
        return nil
      end
      cur_expression = self.expression_parse
      self.parse_error("expression expected") unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << cur_expression
      end
      unless self.get_token(CLOSE_CUR_REX) then
        # Maybe it was a multiple concatenation, rewind and cancel.
        self.state = parse_state
        return nil
      end
      return self.concatenation_hook(expressions)
    end

    def concatenation_hook(expressions)
      return AST[:concatenation, expressions ]
    end


    RULES[:multiple_concatenation] = <<-___
<multiple_concatenation>
	::= { <expression> { <expression> <,<expression>>* } }
___

    def multiple_concatenation_parse
      parse_state = self.state
      unless self.get_token(OPEN_CUR_REX) then
        return nil
      end
      expression = self.expression_parse
      self.parse_error("expression expected") unless expression
      unless self.get_token(OPEN_CUR_REX) then
        # It is not a multiple concatenation, maybe it is a simple one.
        # Rewind and cancel.
        self.state = parse_state
        return nil
      end
      cur_expression = self.expression_parse
      self.parse_error("expression expected") unless cur_expression
      expressions = [ cur_expression ]
      loop do
        unless self.get_token(COMMA_REX) then
          break
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions << expression
      end
      self.parse_error("closing curly bracket expected") unless self.get_token(CLOSE_CUR_REX)
      self.parse_error("closing curly bracket expected") unless self.get_token(CLOSE_CUR_REX)
      return self.multiple_concatenation_hook(expression,expressions)
    end

    def multiple_concatenation_hook(expression, expressions)
      return AST[:multiple_concatenation, expression,expressions ]
    end


    RULES[:function_call] = <<-___
<function_call>
	::= <name_of_function> ( <expression> <,<expression>>* )
	||= <name_of_system_function> ( <expression> <,<expression>>* )
	||= <name_of_system_function>
___

    def function_call_parse
      parse_state = self.state
      name_of_function = self.name_of_function_parse
      if name_of_function then
        unless self.get_token(OPEN_PAR_REX) then
          self.state = parse_state
          return nil
        end
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions = [ cur_expression ]
        loop do
          unless self.get_token(COMMA_REX) then
            break
          end
          cur_expression = self.expression_parse
          self.parse_error("expression expected") unless cur_expression
          expressions << cur_expression
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.function_call_hook(name_of_function,expressions)
      end
      name_of_system_function = self.name_of_system_function_parse
      return nil unless name_of_system_function
      if self.get_token(OPEN_PAR_REX) then
        cur_expression = self.expression_parse
        self.parse_error("expression expected") unless cur_expression
        expressions = [ cur_expression ]
        loop do
          unless self.get_token(COMMA_REX) then
            break
          end
          cur_expression = self.expression_parse
          self.parse_error("expression expected") unless cur_expression
          expressions << expression
        end
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.function_call_hook(name_of_system_function,expressions)
      else
        return self.function_call_hook(name_of_system_function,nil)
      end
    end

    def function_call_hook(name_of_function__name_of_system_function,
                           expressions)
      return AST[:function_call,
                 name_of_function__name_of_system_function,
                 expressions ]
    end


    RULES[:name_of_function] = <<-___
<name_of_function>
	::= <identifier>
___

    def name_of_function_parse
      identifier = self.identifier_parse
      return nil unless identifier
      return name_of_function_hook(identifier)
    end

    def name_of_function_hook(identifier)
      return AST[:name_of_function, identifier ]
    end


    RULES[:name_of_function] = <<-___
<name_of_system_function>
	::= $<SYSTEM_IDENTIFIER>
	(Note: the $ may not be followed by a space.)
___

    def name_of_system_function_parse
      # *Auth*: the $ is integrated into the system_identifier!!
      tok = self.get_token(SYSTEM_IDENTIFIER_REX)
      if tok then
        return self.name_of_system_function_hook(tok)
      end
      return nil
    end

    def name_of_system_function_hook(identifier)
      return AST[:name_of_system_function, identifier ]
    end


    # 8. General


    RULES[:comment] = <<-___
<comment>
	::= <short_comment>
	||= <long_comment>
___

    def comment_parse
      short_comment = self.short_comment_parse
      if short_comment then
        return self.comment_hook(short_comment)
      end
      long_comment = self.long_comment_parse
      if long_comment then
        return self.comment_hook(long_comment)
      end
      return nil
    end

    def comment_hook(comment)
      return AST[:comment, comment ]
    end


    RULES[:short_comment] = <<-___
<short_comment>
	::= // <comment_text> <END-OF-LINE>
___

    def short_comment_parse
      unless self.get_token(SLASH_SLASH_REX) then
        return nil
      end
      # *Auth*: long and short comment are separated while in the
      # BNF the are the same rule.
      comment_text = self.short_comment_text_parse
      self.parse_error("comment text expected") unless comment_text
      self.parse_error("end of line expected") unless self.get_token(EOL_REX)
      return self.short_comment_hook(comment_text)
    end

    def short_comment_hook(comment_text)
      return AST[:short_comment, comment_text ]
    end


    RULES[:long_comment] = <<-___
<long_comment>
	::= /* <comment_text> */
___

    def long_comment_parse
      unless self.get_token(SLASH_ASTERISK_REX) then
        return nil
      end
      # comment_text = self.comment_text_parse
      # *Auth*: long and short comment are separated while in the
      # BNF the are the same rule.
      comment_text = self.long_comment_text_parse
      self.parse_error("comment text expected") unless comment_text
      self.parse_error("'*/' expected") unless self.get_token(ASTERISK_SLASH_REX)
      return self.long_comment_hook(comment_text)
    end

    def long_comment_hook(comment_text)
      return AST[:long_comment, comment_text ]
    end


    RULES[:comment_text] = <<-___
<comment_text>
	::= The comment text is zero or more ASCII characters
___
    
    def short_comment_text_parse
      # *Auth*: long and short comment are separated while in the
      # BNF the are the same rule.
      return comment_text_hook(self.get_token(SHORT_COMMENT_TEXT_REX))
    end
    
    def long_comment_text_parse
      # *Auth*: long and short comment are separated while in the
      # BNF the are the same rule.
      return comment_text_hook(self.get_token(LONG_COMMENT_TEXT_REX))
    end

    def comment_text_hook(tok)
      return AST[:comment_text, tok ]
    end


    RULES[:identifier] = <<-___
<identifier>
	::= <IDENTIFIER><.<IDENTIFIER>>*
	(Note: the period may not be preceded or followed by a space.)
___

    def identifier_parse
      # *BNF*: (Note: the period may not be preceded or followed by a
      #         space.)
      cur_identifier = self._IDENTIFIER_parse
      return nil unless cur_identifier
      identifiers = [ cur_identifier ]
      loop do
        break unless self.get_token(DOT_REX)
        cur_identifier = self._IDENTIFIER_parse
        self.parse_error("identifier expected") unless cur_identifier
        identifiers << identifier
      end
      return self.identifier_hook(identifiers)
    end

    def identifier_hook(identifiers)
      return AST[:identifier, *identifiers ]
    end


    RULES[:identifier] = <<-___
<IDENTIFIER>
	An identifier is any sequence of letters, digits, dollar signs ($), and
	underscore (_) symbol, except that the first must be a letter or the
	underscore; the first character may not be a digit or $. Upper and lower case
	letters are considered to be different. Identifiers may be up to 1024
	characters long. Some Verilog-based tools do not recognize  identifier
	characters beyond the 1024th as a significant part of the identifier. Escaped
	identifiers start with the backslash character (\) and may include any
	printable ASCII character. An escaped identifier ends with white space. The
	leading backslash character is not considered to be part of the identifier.
___

    def _IDENTIFIER_parse
      tok = self.get_token(IDENTIFIER_REX)
      if tok then
        return self._IDENTIFIER_hook(tok)
      end
      return nil
    end

    def _IDENTIFIER_hook(tok)
      return AST[:_IDENTIFIER, tok ]
    end


    RULES[:delay] = <<-___
<delay>
	::= # <number>
	||= # <identifier>
	||= # ( <mintypmax_expression> <,<mintypmax_expression>>?
		<,<mintypmax_expression>>?)
___

    def delay_parse
      unless self.get_token(SHARP_REX) then
        return nil
      end
      number = self.parse_number
      if number then
        self.delay_hook(number,nil,nil)
      end
      identifier = self.parse_identifier
      if identifier then
        self.delay_hook(identifier,nil,nil)
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      mintypmax_expression0 = self.mintypmax_expression_parse
      self.parse_error("min:typical:max expression expected") unless mintypmax_expression0
      mintypmax_expression1 = nil
      if self.get_token(COMMA_REX) then
        mintypmax_expression1 = self.mintypmax_expression_parse
        self.parse_error("min:typical:max expression expected") unless mintypmax_expression1
      else
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.delay_hook(mintypmax_expression0,nil,nil)
      end
      if self.get_token(COMMA_REX) then
        mintypmax_expression2 = self.mintypmax_expression_parse
        self.parse_error("min:typical:max expression expected") unless mintypmax_expression2
      else
        self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
        return self.delay_hook(mintypmax_expression0,
                               mintypmax_expression1,nil)
      end
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return self.delay_hook(mintypmax_expression0,
                             mintypmax_expression1,
                             mintypmax_expression2)
    end

    def delay_hook(number__identifier__mintypmax_expression,
                   mintypmax_expression1, mintypmax_expression2)
      return AST[:delay,
                 number__identifier__mintypmax_expression,
                 mintypmax_expression1,mintypmax_expression2 ]
    end


    RULES[:delay_control] = <<-___
<delay_control>
	::= # <number>
	||= # <identifier>
	||= # ( <mintypmax_expression> )
___

    def delay_control_parse
      unless self.get_token(SHARP_REX) then
        return nil
      end
      number = self.parse_number
      if number then
        self.delay_hook(number,nil,nil)
      end
      identifier = self.parse_identifier
      if identifier then
        self.delay_hook(identifier,nil,nil)
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      mintypmax_expression = self.mintypmax_expression_parse
      self.parse_error("min:typical:max expression expected") unless mintypmax_expression
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return self.delay_hook(mintypmax_expression)
    end

    def delay_hook(number__identifier__mintypmax_expression)
      return AST[:delay, number__identifier__mintypmax_expression ]
    end


    RULES[:event_control] = <<-___
<event_control>
	::= @ <identifier>
	||= @ ( <event_expression> )
___
    
    def event_control_parse
      unless self.get_token(AT_REX) then
        return nil
      end
      identifier = self.identifier_parse
      if identifier then
        return self.event_control_hook(identifier)
      end
      self.parse_error("opening parenthesis expected") unless self.get_token(OPEN_PAR_REX)
      event_expression = self.event_expression_parse
      self.parse_error("event expression expected") unless event_expression
      self.parse_error("closing parenthesis expected") unless self.get_token(CLOSE_PAR_REX)
      return self.event_control_hook(event_expression)
    end

    def event_control_hook(identifier__event_control)
      return AST[:event_control, identifier__event_control ]
    end


    RULES[:event_expression] = <<-___
<event_expression>
	::= <expression>
	||= posedge <scalar_event_expression>
	||= negedge <scalar_event_expression>
	||= <event_expression> or <event_expression>
___

    # Auth: old version compatible with the bfn rules, but not
    # parsable. Also, the case of @ (*) is not present, so need
    # to add it too.
    #
    # def event_expression_parse
    #   tok = self.get_token(EDGE_IDENTIFIER_REX)
    #   if tok then
    #     scalar_event_expression = self.scalar_event_expression_parse
    #     self.parse_error("scalar event expression expected") unless scalar_event_expression
    #     return self.event_expression_hook(tok,scalar_event_expression)
    #   end
    #   parse_state = self.state
    #   event_expression0 = self.event_expression_parse
    #   if event_expression0 and self.get_token(EVENT_OR_REX) then
    #     event_expression1 = self.event_expression_parse
    #     self.parse_error("event epxression expected") unless event_expression1
    #     return self.event_expression_hook(event_expression0,
    #                                       event_expression1)
    #   else
    #     # Rewind and try expression.
    #     self.state = parse_state
    #     expression = self.expression_parse
    #     return nil unless expression
    #     return self.event_expression_hook(expression,nil)
    #   end
    # end

    # def event_expression_hook(tok__expression__event_expression,
    #                           event_expression)
    #   return AST[:event_expression,
    #              tok__expression__event_expression,
    #              event_expression ]
    # end
    #
    # Auth: this rule is infinitely recurse and do not support @ *
    # fix it to:
    # event_expression
    # ::= <event_primary> ( or <event_primary> )*
    #
    # event_primary
    # ::= '*'
    # ||= <expression>
    # ||= posedge <scalar_event_expression>
	# ||= negedge <scalar_event_expression>

    def event_expression_parse
      cur_event_primary = self.event_primary_parse
      return nil unless cur_event_primary
      event_primaries = [ cur_event_primary ]
      loop do
        break unless self.get_token(EVENT_OR_REX)
        cur_event_primary = self.event_primary_parse
        self.parse_error("event expression expected") unless cur_event_primary
        event_primaries << cur_event_primary
      end
      return event_expression_hook(event_primaries)
    end

    def event_expression_hook(event_primaries)
      if event_primaries.size == 1 then
        return event_primaries[0]
      else
        return AST[:event_expression, *event_primaries ]
      end
    end

    def event_primary_parse
      if self.get_token(MUL_REX) then
        return event_primary_hook(MUL_TOK,nil)
      end
      tok = self.get_token(EDGE_IDENTIFIER_REX)
      if tok then
        scalar_event_expression = self.scalar_event_expression_parse
        self.parse_error("scalar event expression expected") unless scalar_event_expression
        return self.event_primary_hook(tok,scalar_event_expression)
      end
      expression = self.expression_parse
      return nil unless expression
      return self.event_primary_hook(expression,nil)
    end

    def event_primary_hook(tok__expression, event_expression)
      return AST[:event_expression,
                 tok__expression, event_expression ]
    end



    RULES[:scalar_event] = <<-___
<scalar_event_expression>
	Scalar event expression is an expression that resolves to a one bit value.
___

    def scalar_event_expression_parse
      # *BNF*: Scalar event expression is an expression that resolves to
      # a one bit value.
      # *Auth*: we use a simple expression here. The check is left to
      # the AST.
      expression = self.expression_parse
      return nil unless expression 
      return self.scalar_event_expression_hook(expression)
    end

    def scalar_event_expression_hook(scalar_event_expression)
      return AST[:scalar_event_expression, scalar_event_expression ]
    end


  end


end

