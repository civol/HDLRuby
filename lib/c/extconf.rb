require 'mkmf'

append_ldflags("-L #{RCSIM_DIR} -l:hruby_sim.so") if Gem.win_platform?

# $LDFLAGS << " -L #{RCSIM_DIR} -l:hruby_sim.so" if Gem.win_platform?

create_makefile(C_PROGRAM)
