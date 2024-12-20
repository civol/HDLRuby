$LOAD_PATH << "#{__dir__}/../../"

require "HDLRuby/verilog_hruby.rb"

parser = VerilogTools::Parser.new

ast = nil

begin
  ast = parser.run(filename: ARGV[0], compress: ARGV[1] == "--compress" )
rescue => error
  puts error
  exit
end

puts "#################################"
puts "##             AST             ##"
puts "#################################"
puts "\n"

puts ast

hdlruby = ""
begin
  hdlruby = ast.to_HDLRuby
rescue => error
  puts error
  exit
end

puts "\n"
puts "#################################"
puts "##           HDLRuby           ##"
puts "#################################"

puts hdlruby
