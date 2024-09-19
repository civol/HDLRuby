require "HDLRuby/verilog_hruby.rb"

parser = VerilogTools::Parser.new

ast = nil

unless ARGV.size == 2 or ARGV[0] == "--help" then
  puts "Usage: v2hdr <input verilog file name> <output HDLRuby file name>"
  exit
end

if ARGV[0] == ARGV[1] then
  puts "Error: input and output files are identical."
  exit(1)
end

begin
  ast = parser.run(filename: ARGV[0], compress: true)
rescue => error
  puts error
  exit
end

hdlruby = ""
begin
  hdlruby = ast.to_HDLRuby
rescue => error
  puts error
  exit
end

File.open(ARGV[1],"w") { |f| f.write(hdlruby) }
