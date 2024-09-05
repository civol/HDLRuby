require "../verilog_parser.rb"

parser = VerilogTools::Parser.new

ast = nil

begin
  ast = parser.run(filename: ARGV[0])
rescue => error
  puts error
  exit
end

puts ast
