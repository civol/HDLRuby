require 'HDLRuby'

configure_high


def hello_out
    puts "hello_out"
end

def hello_mix(u,v,w)
    puts "hello_mix"
    behavior do
        inner :something
        w <= u - v
    end
end

function :hello_sub do |name|
    inner :nothing
    puts "hello_sub, #{name}"
    1
end

# A system for testing functions
system :functions do
    [15..0].input :x,:y, :z
    [15..0].output :a, :b, :c, :d

    hello_out

    def hello_in
        puts "hello_in"
        a <= x + y
    end

    function :hello_in_sub do
        inner :nothing_really
        puts "hello_in_sub"
        d <= x - y
    end

    hello_in

    hello_mix(x,y,b)

    c <= hello_sub("John Doe")

    hello_in_sub
end

hello_out

# Instantiate it for checking.
functions :functionsI

# Generate the low level representation.
low = functionsI.to_low

# Displays it
puts low.to_yaml
