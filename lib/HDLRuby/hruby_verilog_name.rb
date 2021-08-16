# Program with inverse conversion
# last update 2019 01 29

module HDLRuby::Verilog

  # This is sample.
  # n = "abc_ABC_いろは"
  # puts n            
  # name = n.split("") 

  # Since it is possible to use $ and numbers other than the beginning of the character string, it is divided.
  def name_to_verilog(name)
    # ref = ""         # For storing the converted character.
    # name = name.to_s # Ensure name is a string
    # 
    # if (name[0] =~ /[a-zA-Z]/) then
    #   ref << name[0]
    #   # _ To convert it to __.
    # elsif (name[0] == "_") then
    #   ref << "__"
    # # If it does not satisfy the above, it is another character.
    # # In that case, convert it to UTF-8 and convert it to a usable character string.
    # else
    #   l = name[0].bytes.map{|v| v.to_s(16)}.join # Conversion to UTF-8 hexadecimal number.
   
    #   ref << "_" + l.rjust(6,"0")      # Add an underscore indicating conversion.
    #                                    # The remainder of 6 digits is filled with 0.
    # end
    # 
    # name[1..-1].each_char do |c|
    #   # Confirmation of characters in array.
    #   # If it is a-zA-Z 0 - 9, it is added to ref as it is.
    #   if (c =~ /[a-zA-Z0-9]|\$/) then
    #     ref << c
    #   # _ To convert it to __.
    #   elsif (c == "_") then
    #     ref << "__"
    #   # If it does not satisfy the above, it is another character.
    #   # In that case, convert it to UTF-8 and convert it to a usable character string.
    #   else
    #     l = c.bytes.map{|v| v.to_s(16)}.join # Conversion to UTF-8 hexadecimal number.
    #  
    #     ref << "_" + l.rjust(6,"0")      # Add an underscore indicating conversion.
    #                                      # The remainder of 6 digits is filled with 0.
    #   end
    # end
    # return ref

    
      name = name.to_s
      # Convert special characters.
      name = name.each_char.map do |c|
          if c=~ /[a-z0-9]/ then
              c
          elsif c == "_" then
              "__"
          else
              "_" + c.ord.to_s
          end
      end.join
      # First character: only letter is possible.
      unless name[0] =~ /[a-z_]/ then
          name = "_" + name
      end
      return name
  end

  #puts ref

end
