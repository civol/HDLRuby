require "HDLRuby/verilog_hruby.rb"

parser = VerilogTools::Parser.new

ast = nil

HELP = "Usage: v2hdr <input verilog file name> <output HDLRuby file name>" 

if  ARGV[0] == "--help" then
  puts HELP
  exit
end

unless ARGV.size == 2 then
  puts HELP
  exit(1)
end

if ARGV[0] == ARGV[1] then
  puts "Error: input and output files are identical."
  exit(1)
end

begin
  ast = parser.run(filename: ARGV[0], compress: true)
rescue => error
  puts error
  exit(1)
end

hdlruby = ""
begin
  hdlruby = ast.to_HDLRuby
rescue => error
  puts error
  exit(1)
end

File.open(ARGV[1],"w") { |f| f.write(hdlruby) }
