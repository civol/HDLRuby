require 'HDLRuby'

configure_high


def hello_out
    puts "hello_out"
end

def hello_mix(u,v,w)
    puts "hello_mix"
    behavior do
        w <= u - v
    end
end

def hello_sub
    sub do
        puts "hello_sub"
        1
    end
end

# A system for testing functions
system :functions do
    [15..0].input :x,:y, :z
    [15..0].output :a, :b, :c

    hello_out

    def hello_in
        puts "hello_in"
        a <= x + y
    end

    hello_in

    hello_mix(x,y,b)

    c <= hello_sub
end

hello_out

# Instantiate it for checking.
functions :functionsI

# Generate the low level representation.
low = functionsI.to_low

# Displays it
puts low.to_yaml
