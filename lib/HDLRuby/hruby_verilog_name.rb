# Program with inverse conversion
# last update 2019 01 29

module HDLRuby::Verilog

  # This is sample.
  # n = "abc_ABC_いろは"
  # puts n            
  # name = n.split("")

  @@hdr2verilog = {}

  # Since it is possible to use $ and numbers other than the beginning of the character string, it is divided.
  def name_to_verilog(name)
      # name = name.to_s
      # # Convert special characters.
      # name = name.each_char.map do |c|
      #     if c=~ /[a-z0-9]/ then
      #         c
      #     elsif c == "_" then
      #         "__"
      #     else
      #         "_" + c.ord.to_s
      #     end
      # end.join
      # # First character: only letter is possible.
      # unless name[0] =~ /[a-z_]/ then
      #     name = "_" + name
      # end
      # return name
      name = name.to_s
      vname = @@hdr2verilog[name]
      unless vname then
          # Shall we change the string?
          if name.match?(/^[_a-zA-Z][_a-zA-Z0-9]*$/) then
              # No, just clone
              vname = name.clone
          else
              # Yes, ensure it is a verilog-compatible name.
              vname = "_v#{@@hdr2verilog.size}_#{name.split(/[^a-zA-Z_0-9]/)[-1]}"
          end
          @@hdr2verilog[name] = vname
      end
      return vname
  end

  #puts ref

end
