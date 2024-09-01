require "../verilog_parser.rb"

# Read a verilog file.
verilog = File.read(ARGV[0])

parser = VerilogTools::Parser.new

ast = parser.parse(verilog)

puts ast
