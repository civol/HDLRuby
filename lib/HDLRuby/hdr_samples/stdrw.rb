require 'RubyHDL'

def stdrw
  RubyHDL.sigI = $stdin.read.to_i
  $stdout.puts(RubyHDL.sigO)
end
