# Program with inverse conversion
# last update 2019 01 29

module HDLRuby::Verilog

  # This is sample.
  # n = "abc_ABC_いろは"
  # puts n            
  # name = n.split("")

  @@hdr2verilog = { "buf" => "_v0_buf" }

  # Since it is possible to use $ and numbers other than the beginning of the character string, it is divided.
  def name_to_verilog(name)
      # puts "name_to_verilog with name=#{name}"
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
      # puts "result vname=#{vname}"
      return vname
  end

  #puts ref

end
