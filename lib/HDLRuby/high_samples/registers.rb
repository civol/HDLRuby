require 'HDLRuby'

configure_high

# Describes a simple D-FF
system :dff0 do
    bit.input :clk, :rst, :d
    bit.output :q, :qb

    qb <= ~q

    behavior(clk.posedge) do
        q <= d & ~rst
    end
end

# Instantiate it for checking.
Universe.dff0 :dff0I


# Decribes another D-FF
system :dff1 do
    input :clk, :rst, :d
    output :q, :qb

    qb <= ~q
    (q <= d & ~rst).at(clk.posedge)
end

# Instantiate it for checking.
Universe.dff1 :dff1I


# Describes an 8-bit register
system :reg8 do
    input :clk, :rst
    [7..0].input :d
    [7..0].output :q, :qb

    qb <= ~q
    (q <= d & [~rst]*8).at(clk.posedge)
end

# Instantiate it for checking.
Universe.reg8 :reg8I


# Describes a n-bit register.
system :regn do |n|
    input :clk, :rst
    [n-1..0].input :d
    [n-1..0].output :q,:qb

    qb <= ~q
    (q <= d & [~rst]*n).at(clk.posedge)
end

# Instantiate it for checking.
Universe.regn :regn8I,8


# Describes a register of generic type.
system :reg do |typ|
    input :clk, :rst
    typ.input :d
    typ.output :q,:qb

    qb <= ~q
    (q <= d & [~rst]*typ.width).at(clk.posedge)
end

# Instantiate it for checking.
Universe.reg :regbit8I, bit[7..0]



# Function generating the body of a register description.
def reg_body(typ)
    input :clk, :rst
    typ.input :d
    typ.output :q,:qb

    qb <= ~q
    (q <= d & [~rst]*typ.width).at(clk.posedge)
end

# Now declare the systems decribing the registers.
system :dff_body do
    reg_body(bit)
end

system :reg8_body do
    reg_body(bit[7..0])
end

system :regn_body do |n|
    reg_body(bit[n-1..0])
end

system :reg_body do |typ|
    reg_body(typ)
end

# Instantiate these systems for checking them.
Universe.dff_body  :dff_bodyI
Universe.reg8_body :reg8_bodyI
Universe.regn_body :regn_bodyI, 8
Universe.reg_body  :reg_bodyI, bit[7..0]


# Function generating a register declaration.
def make_reg(name,&blk)
    system name do |*arg|
        input :clk, :rst
        blk.(*arg).input :d
        blk.(*arg).output :q,:qb

        qb <= ~q
        (q <= d & [~rst]*blk.(*arg).width).at(clk.posedge)
    end
end

# Now let's generate the register declarations.
make_reg(:dff_make) { bit }
make_reg(:reg8_make){ bit[7..0] }
make_reg(:regn_make){ |n| bit[n-1..0] }
make_reg(:reg_make) { |typ| typ }

# Instantiate these systems for checking them.
dff_make  :dff_makeI
reg8_make :reg8_makeI
regn_make :regn_makeI, 8
reg_make  :reg_makeI, bit[7..0]

# Generate the low level representation.
low = reg_makeI.to_low

# Displays it
puts low.to_yaml
