require 'mkmf'

append_cppflags(["-DRCSIM"])
# For debugging RCSIM
append_cflags(["-g"])
# append_cflags(["-fsanitize=address"])
# append_ldflags(["-fsanitize=address"])

abort "missing malloc()" unless have_func "malloc"
abort "missing free()"   unless have_func "free"

create_header
create_makefile 'hruby_sim/hruby_sim'
