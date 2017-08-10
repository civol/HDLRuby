# HDLRuby

HDLRuby is a library for describing and simulating digital electronic
systems.

__Warning__: 

 - This is very preliminary work which may  (will) change a lot before a
   stable version is released.
 - It is highly recommended to have both basic knowledge of the Ruby language
   and hardware description languages before using HDLRuby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'HDLRuby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install HDLRuby

## Usage

### Using HDLRuby

You can use HDLRuby in a ruby program by loading `HDLRuby.rb` in your ruby file:

```ruby
require 'HDLRuby'
```

Then, Ruby has to be set up for supporting high-level description of hardware
components. This is done as adding the following line of code:

```ruby
configure_high
```

Alternatively, you can include `HDLRuby::Low` for gaining access to the
classes used for low-level description of hardware components.

```ruby
include HDLRuby::Low
```

It is then possible to load a low level representations of hardware as
follows, where `stream` is a stream containing the representation.

```ruby
hardwares = HDLRuby::from_yaml(stream)
```

For instance, you can load a sample description of an 8-bit adder as follows:

```ruby
typ,adder = HDLRuby::from_yaml(File.read("#{$:[0]}/HDLRuby/low_samples/adder.yaml"))
```

__Notes__:

- A `HDLRuby::Low` description of hardware can only be built through standard
  Ruby class constructors, and does not include any validity check of the
  resulting hardware.
- HDLRuby cannot be configured for both `HDLRuby::High` and `HDLRuby::Low` at
  the same time.



## HDLRuby::High programming guide

HDLRuby::High has been designed to bring the high flexibility of the Ruby
language to HDL while ensuring the hardware descriptions are always
synthesizable. In this context, all the abstraction provided by HDLRuby::High
is in the way of describing hardware, but not in its execution model, this
latter being designed to be RTL by construct.

The second specificity of HDLRuby::High is that it supports natively all the
features of the Ruby language.

__Notes__:

- It is still possible to extend HDLRuby::High to support hardware
  descriptions of higher level than RTL, please refer to then
  [Extending HDLRuby::High](#extend) section for more details.
- In this document, HDLRuby:High constructs will often be compared to their
  Verilog or VHDL equivalents for simpler explanations.

### Introduction

This introduction gives a glimpse of what can be done with this language.
However, we do recommend to consult the section about the [high-level
programming features](#highfeat) to have a more complete view of the advanced
possibilities of this language.

At first glance, HDLRuby::High is similar to any other HDL languages (like
Verilog or VHDL), for instance the following code describes a simple D-FF:

```ruby
system :dff do
   bit.input :clk, :rst, :d
   bit.output :q

   behavior(clk.posedge) do
      q <= d & ~rst
   end
end
```

As in can be seen in the code above, `system` is the key word used for
describing a digital circuit, and can be seen as a equivalent of the Verilog's
`module`. In such a system, signals are declared using a `<type>.<direction>`
construct where `type` is the data type of the signal (e.g., `bit` as in the
code above) and direction indicates if the signal is an input, an output, an
inout or an inner signal; and executable blocks (similar to `always` block of
Verilog) are decribed using the `behavior` keyword.

Once described, a HDLRuby::High system can be converted to a low-level
description (HDLRuby::Low) using the `to_low` method.  For example the
following code converts `dff` system to a low-level description and assign the
result to variable `low_dff`:

```ruby
low_dff = dff.to_low
```

This low-level description can then be used for simulation or for generating
synthesizable Verilog or VHDL code.

__Note:__

- The majority of the hardware description generation is done when
  instantiating systems. Actually, the `to_low` method only mangles the names
  when inheriting so that Verilog or VHDL is easier to generate. It is high
  probable this method becomes deprecated in the future.

---

The code describing a `dff` given above is not much different from its
equivalent in other HDL.  However, HDLRuby::High provides several features for
achieving a higher productivity when describing hardware. We will now describes
a few of them.

First, several syntactic sugars exist that allow shorter code, for instance
the following code is strictly equivalent to the previous description of `dff`:

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end
```

Furthermore, generic parameters can be used for anything in HDLRuby::High.
For instance the following code describes a 8-bit register without any
parameterization:

```ruby
system :reg8 do
   input :clk, :rst
   [7..0].input :d
   [7..0].output :q

   (q <= d & [~rst]*8).at(clk.posedge)
end
```

But it is also possible to describe a register of arbitrary size as follows,
where `n` is the parameter giving the number of bits of the register:

```ruby
system :regn do |n|
   input :clk, :rst
   [n-1..0].input :d
   [n-1..0].output :q

   (q <= d & [~rst]*n).at(clk.posedge)
end
```

Or, even further, it is possible to describe a register of arbitrary type
(not only bit vectors) as follows:

```ruby
system :reg do |typ|
   input :clk, :rst
   typ.input :d
   typ.output :q

   (q <= d & [~rst]*typ.width).at(clk.posedge)
end
```

Now, one might think it is painful to write almost the same code for each
example. If that is the case, he can wrap up everything as follows:

```ruby
# Function generating the body of a register description.
def reg_body(typ)
   input :clk, :rst
   typ.input :d
   typ.output :q

   (q <= d & [~rst]*typ.width).at(clk.posedge)
end

# Now declare the systems decribing the registers.
system :dff do
   reg_body(bit)
end

system :reg8 do
   reg_body(bit[7..0])
end

system :regn do |n|
   reg_body(bit[n-1..0])
end

system :reg do |typ|
   reg_body(typ)
end
```

It also possible to go further and write a method for generating examples of
register descriptions as follows (such an example, excessive on purpose, will
be explained little by little in this document):

```ruby
# Function generating a register declaration.
def make_reg(name,&blk)
   system name do |*arg|
      input :clk, :rst
      blk.(*arg).input :d
      blk.(*arg).output :q

      (q <= d & [~rst]*blk.(*arg).width).at(clk.posedge)
   end
end

# Now let's generate the register declarations.
make_reg(:dff) { bit }
make_reg(:reg8){ bit[7..0] }
make_reg(:regn){ |n| bit[n-1..0] }
make_reg(:reg) { |typ| typ }
```

Wait... I have just realized: a D-FF without an inverted output does not look
very serious. So let us extend the existing `dff` to provide an inverted
output. This can be done basically in three ways. First, inheritance can be
used: a new system is built inheriting from `dff` as it is done in the following
code.

```ruby
system :dff_full, dff do
   output :qb
   qb <= ~q
end
```

The second possibility is to modify `dff` afterward. In HDLRuby::High, this
achieved using the `open` method as it is done the following code:

```ruby
dff.open do
   output :qb
   qb <= ~q
end
```

The third possibility is to modify directly a single instance of `dff` which
require an inverted output, using again the `open` method, as in the following
code:

```ruby
# Declare dff0 as an instance of dff
dff :dff0

# Modify it
dff0.open do
   output :qb
   qb <= ~q
end
```

In this later case, only `dff0` will have an inverted output, the other
instances of `dff` will not change.

Now assuming we opted for the first solution, we have now `dff_full` a highly
advanced D-FF with such unique features as an inverted output. So we would like
to use it in other designs, for example a shift register of `n` bits. Such a
system will include a generic number of `dff_full` instance, and can be
described as follows making use of the `zip` methods of the standard Ruby
library for connecting them together with compact code:

```ruby
system :shifter do |n|
   input :i0
   output :o0, :o0b

   # Instantiating n D-FF
   [n].(dff_full).make :dffIs

   # Interconnect them as a shift register
   dffIs[0..-2].zip(dffIs[1..-1]) { |ff0,ff1| ff1.d <= ff0.q }

   # Connects the input and output of the circuit
   dffIs[0].d <= in
   o0 <= dffIs[-1].q
   o0b <= dffIs[-1].qb
end
```


As it can be seen in the above examples, in HDLRuby::High, any construct is
an object, and therefore include methods. For instance, declaring a signal
of a given `type` and direction (input, output or inout) is done as follows,
so that `direction` is actually a method of the type, and the signal names
are actually the arguments of this method (symbols or string are supported).
```ruby
<type>.<direction> <list of symbols representing the signal>
```


### How does HDLRuby::High work

Contrary to descriptions in high-level HDL like SystemVerilog, VHDL or SystemC, 
HDLRuby::High descriptions are not software-like description of hardware, but
are programs meant to produce hardware descriptions. In other words, while
the execution of a common HDL code will result of some simulation of
the described hardware, the execution of HDLRuby::High code will result
in some low-level hardware description. This low-level description is
synthesizable, and can also be simulated like any standard hardware description.
This decoupling of the representation of the hardware from the point of view
of the user (HDLRuby::High), and the actual hardware description (HDLRuby::Low)
make it possible to provide the user with any advanced software features
without jeopardizing the synthesizability of the actual hardware description.

For that purpose, each construct in HDLRuby::High is not a direct description of
some hardware construct, but a program which generates the corresponding
description. For example, let us consider the following line of code
of HDLRuby::High describing the connection between signal `a` and signal `b`:

```ruby
   a <= b
```

Its execution will produce the actual hardware description of this connection,
as an object of the HDLRuby::Low library (in the case an instance of the
`HDLRuby::Low::Connection` class). Concretely, a HDLRuby::High system are
described by a ruby block, and the instantiation of this system is actually
performed by executing this block. It is the execution result of this
instantiation which is the synthesizable description of the hardware.



From there, we will describe into more details each construct of HDLRuby::High.

### Naming rules
<a name="names"></a>

Several construct in HDLRuby::High are refered by name, e.g., systems, signals.
When such construct are declared, their name is to be specified by a ruby
symbol starting with a lower case. For example, `:hello` is a valid name
declaration, but `:Hello` is not.

After being declared, the construct can be referred using the name directly
(i.e., without the `:` of ruby symbols). For example, if a construct has
be declared with `:hello` as name, it will be afterward referred by `hello`.

### Systems and signals

A system represents a digital system and corresponds to a Verilog 
module. A system has an interface comprising input, output, and
inout signals, and is made of structural and behavioral descriptions.

A signal represents a state in a system. It has a data type and a value, the
latter varying with time.  Similarly to VHDL, HDLRuby::High signals can be
viewed as abstractions of both wires and registers in a digital circuit.  As a
general rule, a signal whose value is explicitly set all the time models a wire
(for example a signal connected to another), otherwise it models a register.

#### Declaring an empty system

A system is declared using the keyword `system`. It must be given a ruby symbol
for name and a block that describe its content.  For instance the following
code describes an empty system named `void`:

```ruby
system(:void) {}
```

__Notes__:

- Since this is ruby code, the body can be delimited by the `do` and `end` ruby
  keywords (in which case parenthesis can be omitted), as follows:

```ruby
system :void do
end
```

- Names in HDLRuby::High are natively stored as ruby symbols, but strings can
  also be used, e.g., `system("void") {}` is also valid.

#### Declaring a system with an interface

The interface of a system can be describes anywhere in its body, but it
is recommended to do it at its beginning. It is done by declaring input, output
or inout signals of given data types as follows:

```ruby
<data type>.<direction> <list of colon-preceded names>
```

For example, declaring an input 1-bit signal named `clk` can be declared as
follows:

```ruby
bit.input :clk
```

Now, since `bit` is the default data type in HDLRuby::High, it can be omitted
as follows:

```ruby
input :clk
```

Here is a more complete example of a system describng a 8-bit data, 16-bit
address memory whose interface includes a 1-bit input clock (`clk`), a 1-bit
input read/!write (`rwb`) for selecting reading or writing access, a 16-bit
address input (`addr`) and an 8-bit data inout (the remaining of the code
describes the content and the behavior of the memory):

```ruby
system :mem8_16 do
    input :clk, :rwb
    [15..0].input :addr
    [7..0].inout :data

    bit[7..0][2**16].inner :content
    
    behavior(clk.posedge) do
        hif(rwb) { data <= content[addr] }
        helse    { content[addr] <= data }
    end
end
```

#### Structural description in a system.

In a system, structural descriptions consist of subsystems and 
interconnections among them.

A subsystem is obtained by instantiating an existing system as follows, where
`<system name>` is the name of the system to instantiate (without any colon):

```ruby
<system name> instance name
```

For example, system `mem8_16` system declared in the previous section can be
instantiated as follows:

```ruby
mem8_16 :mem8_16I
```

It is also possible to declare multiple instance of a same system at time
as follows:

```ruby
<system name> [list of colon-speparated instance names]
```

For example, the following code declares two instances of the `mem8_16` system:

```ruby
mem8_16 [ :mem8_16I0, :mem8_16I1 ]
```

Interconnecting instances, may require internal signals in the system.
Such signals are declared using the `inner` direction.
For example, the following code declares a 1-bit inner signal named `w1` and a
2-bit inner signal named `w2`:

```ruby
inner w1
[1..0].inner w2
```

A connection between signals is done using the arrow operator `<=` as follows:

```ruby
<destination> <= <source>
```

The `<destination>` must be a reference to a signal, and the `<source>` can
be any expression.

For example the following code, connects signal `w1` to signal `ready`
and signal `clk` to the first bit of signal `w2`:

```ruby
ready <= w1
w2[0] <= clk
```

As an other example, the following code connects to the second bit of `w2` the
output of an AND operation between `clk` and `rst` as follows:

```ruby
w2[1] <= clk & rst
```

The signals of an instance can be connected through the arrow operator too,
provided they are properly referred to. One way to refer them is to use the dot
operator `.` on the instance as follows:

```ruby
<instance name>.<signal name>
```

For example the following code connects signal `clk` of instance `mem8_16I` to
signal `clk` of the current system:

```ruby
mem8_16I.clk <= clk
```

It is also possible to connect multiple signals of an instance using the call
operator `.()` as follows, where each target can be any expression:

```ruby
<intance name>.(<signal name0>: <target0>, ...)
```

For example, the following code connects signals `clk` and `rst` of instance
`mem8_16I` to signals `clk` and `rst` of the current system. As seen in this
example, this method allows partial connection since the address and data bus
are not connected yet.

```ruby
mem8_16I.(clk: clk, rst: rst)
```

This last connection method can be used directly while declaring an instance,
for example, `mem8_16I` could have been declared and connected to `clk` and
`rst` as follows:

```ruby
mem8_16(:mem8_16I).(clk: clk, rst: rest)
```

To summarize this section, here is a structural description of a 16-bit memory
made of two 8-bit memories (or equivalent) sharing the same address bus, and
using respectively the lower and the higher 8-bits of the data bus:

```ruby
system :mem16_16 do
   input :clk, :rwb
   [15..0].input :addr
   [15..0].inout :data

   mem8_16(:memL).(clk: clk, rwb: rwb, addr: addr, data: data[7..0])
   mem8_16(:memH).(clk: clk, rwb: rwb, addr: addr, data: data[15..8])
end
```

And here is an equivalent code using the arrow operator:

```ruby
system :mem16_16 do
   input :clk, :rwb
   [15..0].input :addr
   [15..0].inout :data

   mem8_16 [:memL, :memH]

   memL.clk  <= clk
   memL.rwb  <= rwb
   memL.addr <= addr
   memL.data <= data[7..0]

   memH.clk  <= clk
   memH.rwb  <= rwb
   memH.addr <= addr
   memH.data <= data[15..8]
end
```


#### Behavioral description in a system.

In a system, behavioral descriptions are declared using the `behavior` keyword and are the equivalent of the Verilog `always` blocks.

A behavior is made of a list of events (the sensitivity list) upon which it is
activated, and a list of statements. A behavior is declared as follows:

```ruby
behavior <list of events> do
   <list of statements>
end
```

In addition, it is possible to declare inner signals within an execution block.
While such signal will physically linked to the system, they are only
accessible within the block they are declared into. This permits a tighter scope
for signals, which improves the readability of the code, and make it possible
to declare additional signals with a name identical to an existing signal
provided their respective scopes are different.

An event represents a specific change of state of a signal. 
For example, a rising edge of a clock signal named `clk` will be represented
by the `clk.posedge` event. In HDLRuby::High, events are obtained directly from
expressions using the respectively the following methods: `posedge` for rising 
edge, `negedge` for falling edge, and `edge` for any edge.
Events are described in more details in the [events section](#events).

When one of the event of the sensitivity list of a behavior occurs, the
behavior is executed, i.e., each of its statement is executed in sequence. A
statement can represent a data transmission to a signal, a control flow, a
nested execution block or the declaration of an inner signal (as stated
earlier). Statements are described in more details in [statements
section](#statements), in this section, we will focus on the transmission
statements and the block statements.

A transmission statement is declared using the arrow operator `<=` as follows:

```ruby
<destination> <= <source>
```

The `<destination>` must be a reference to a signal, and the `<source>` can
be any expression. A transmission has therefore exactly the same structure
as a connection. However, its execution model is different: whereas a
connection is continuously executed, a transmission is only executed during
the sequential execution of its block.

A block statement is a sequence of statements, and allows to add hierarchy
within a behavior. By default a block statement is in parallel mode, i.e., ita
s execution is equivalent to a parallel execution.  For that purpose, the
transmissions such a block are non-blocking, i.e., the destination values will
only change when the block is fully executed.  The other possible execution
mode is called sequential and correspond to a true sequential execution.  For
this latter mode, the transmissions are blocking, i.e., the destination value
of a transmission is updated before the next statement is executed. A behavior
based on a sequential block is declared as follows:

```ruby
behavior <list of events>,seq do
   <list of statements>
end

It is possible to change the execution mode inside a block by declaring a new
block statement. An sequential inner block is declared as follows:

```ruby
seq do
   <list of statements>
end
```

It is also possible to declare a parallel block statement as follows:

```ruby
par do
   <list of statements>
end
```

Finally it is possible to declare a block statement with the same mode as the
enclosing one as follows:

```ruby
block do
    <list of statements>
end
```

This latter kind of block statemetn is used for creating a new scope for
declaring signals without colliding with existing ones while keeping the
current execution mode. For example it is possible to declare three different
inner signals all called `sig` as follows:

```ruby
...
behavior(<sensibility list>) do
   inner :sig
   ...
   block do
      inner :sig
      ...
      block do
         inner :sig
         ...
      end
   end
   ...
end
```

To summarize this section, here is a behavioral description of a 16-bit shift
register with asynchronous reset (`hif` and `helse` are keywords used for
specifying hardware _if_ and _else_ control statements).

```ruby
system :shift16 do
   input :clk, :rst, :din
   output :dout

   [15..0].inner :reg

   dout <= reg[15] # The output is the last bit of the register.

   behavior(clk.posedge) do
      hif(rst) { reg <= 0 }
      helse do
         reg[0] <= din
         reg[15..1] <= reg[14..0]
      end
   end
end
```

In the example above, the order of the transmission statements is of no
consequence. This is not the case for the following example, that implements
the same register using a sequential block. In this second example, putting
statement `reg[0] <= din` in the last place would have lead to an invalid
functionality for a shift register.

```ruby
system :shift16 do
   input :clk, :rst, :din
   output :dout

   [15..0].inner :reg

   dout <= reg[15] # The output is the last bit of the register.

   behavior(clk.posedge) do
      hif(rst) { reg <= 0 }
      helse seq do
         reg[0] <= din
         reg <= reg[14:0]
      end
   end
end
```

__Note__:

  - `helse seq` ensures that the block of the hardware else is in sequential
     mode.
  - `hif(rst)` could also have been set to sequential mode as follows:
    
    ```ruby
       hif rst, seq do
          reg <= 0
       end
    ```
  - Parallel mode can be set the same way using `par`.

Finally, it often happens that a behavior contains only one statement.
In such a case, the description can be shortened using the `at` operator
as follows:

```ruby
( statement ).at(<list of events>)
```

For example the following two code samples are equivalent:

```ruby
behavior(clk.posedge) do
   a <= b+1
end
```

```ruby
( a <= b+1 ).at(clk.posedge)
```

This operator can also be applied on block statements as follows, but the code
might not be as readable as one using the `behavior` keyword:

```ruby
( seq do
     a <= b+1
     c <= d+2
  end ).at(clk.posedge)
```


### Events
<a name="events"></a>

Each behavior of a system is associated with a list of events, called
sensibility list, that specifies when the behavior is to be executed.  An event
is associated with a signal and represents the instants when the signal varies
to a given state.

There are three kind of events: positive edge events represent the instants
when their corresponding signals vary from 0 to 1, negative edge events
represent the instants when their corresponding signals vary from 1 to 0 and
the change events represent the instants when their corresponding signal vary.
Events are declared directly from the signals, using the `posedge` operator
for positive edge, `negedge` operator for negative edge, and `change` operator
for change. For example the following code declares 3 behaviors activated
respectively on the positive edge, the negative edge and any change of the
`clk` signal.

```ruby
inner :clk

behavior(clk.posedge) do
...
end

behavior(clk.negedge) do
...
end

behavior(clk.change) do
...
end
```

__Note:__
 - The `change` keyword can be omitted.

### Statements
<a name="statements"></a>

Statements are the basic elements of a behavioral description and are regrouped
in blocks that specify their execution mode (parallel or sequential).  There
are four kinds of statements: the transmit statements whose execution computes
expressions and transmit its result to the target signals, the control segments
that change the execution flow of the behavior, the block statements (described
earlier) and the inner signal declarations.

__Note__:

 - There is actually a fifth type of statement, the time statement. It will be
   discussed in section [Time](#time).


#### Transmit statement

A transmit statement is declared using the arrow operator `<=` within a
behavior. Its right value is the expression to compute and its left
value is a reference to the target signals (or parts of signals), i.e., the
signals (or part of signals) that receives the computation result.

For example following code transmits the value `3` to signal `s0` and the sum
the values of signals `i0` and `i1` to the first four bits of signal `s1`:

```ruby
s0 <= 3
s1[3..0] <= i0 + i1
```

The behavior of the transmit statement depends on the execution mode of the
enclosing block:

 - If the mode is parallel, the target signals are updated
   when all the statements of the current block are processed.
 - If the mode is sequential, the target signals are updated immediately
   after the right value of the statement is computed.


#### Control statements

There are only two possible control statements: the hardware if `hif` and
the hardware case `hcase`. 

##### hif

The `hif` construct is made of a condition and a block that is to be
executed if the condition is met. It is declared as follows:

```ruby
hif <condition> do
   <block contents>
end
```

The condition can be any expression provided they are of a 1-bit type where `0`
stands false and `1` for true (`Z` and `X` lead to undefined behavior).

##### hcase

The `hcase` construct is made of an expression, and a list of value-block pair.
A block is executed when the corresponding value is equal to the value of
the expression of the hcase. This construct is declared as follows:

```ruby
hcase <expression>
hwhen <value 0> do
   <block contents 0>
end
hwhen <value 1> do
   <block contents 1>
end
...
```

##### helse

It is possible to add a block that is executed when the condition of an `hif` is
not met, or when no case matches the expression of a `hcase`, using the `helse`
keyword as follows:

```ruby
<hif or hcase construct>
helse do
   <block contents>
end
```

##### About loops

HDLRuby does not include any hardware construct for describing loops.
It might look quite poor compared to the other HDL, but it is important to understand that current synthesis
tools do not really synthesize hardware from such loops but instead preprocess
them (e.g., unroll them) to synthesizable loop-less hardware. In HDLRuby::High,
such features are natively supported using the Ruby control instructions, i.e.,
the ruby loop constructs (`for`, `while`, and so on), but also more advanced
ruby constructs like the enumerators (`each`, `times`, and so on).

__Notes__:

 - HDLRuby::High being based on Ruby, it is highly recommended to avoid `for`
   or `while` constructs and to use enumerators instead.
 - The Ruby `if` and `case` statements can also be used, but will not produce
   any equivalent hardware. Actually, they are be executed when the
   corresponding system is instantiated.  For example the following code will
   display `Hello world!` when the described system is instantiated provided
   its generic parameter is not nil.

   ```ruby
   system :say_hello do |param = nil|
      if param != nil then
         puts "Hello world!"
      end
   end
   ```


### Types
<a name="types"></a>

Signals and expressions have a data type which describes the kind of value they
represent. In HDLRuby::High, the data types basically represent bit vectors
associated with the way they should be interpreted, i.e., as bit strings,
unsigned values, signed values, or hierarchical content, and so on.

#### Type construction

There are three basic types, `bit`, `signed`, `unsigned`, that represent
respectively 1-bit bit string, 1-bit unsigned value and 1-bit signed value.

The other types are built from them using one of the two type operators.

__The vector operator__ `[]` allows to make types representing vectors of
single or multiple other types. A vector of values of identical types is
declared as follows:

```ruby
<type>[<range>]
```

The `<range>` of a vector type indicates the position of the starting and ending
bits relatively to the radix point. If the position of starting bit is on the
left side of the range, the vector is big endian, otherwise it is little
endian.  Negative positions are also possible and indicate positions bellow the
radix point.  For example the following code described a big endian fixed point
type with 8 bits above the radix point and 4 bits bellow:

```ruby
bit[7..-4]
```

A `n..0` range can also be abbreviated to `n+1`. For instance the two following
types are identical:

```ruby
bit[7..0]
bit[8]
```

A vector of multiple types is declared as follows:

```ruby
[<type 0>, <type 1>, ... ]
```

For example the following code declares a vector of a 8-bit, a 16-bit signed and
a 16-bit unsigned values:

```ruby
[ bit[8], signed[16], unsigned[16] ]
```

__The structure opertor__ `{}` allows the declaration of a hierarchy made of 
named sub types. This operator is used as follows:

```ruby
{ <name 0>: <type 0>, <name 1>: <type 1>, ... }
```

For instance, the following code declares a hierarchical type with an 8-bit sub
type named `header` and a 24-bit sub type named `data`:

```ruby
{ header: bit[7..0], data: bit[23..0] }
```


#### Type compatibility and casting

When two types are not compatible together, operations, connection or 
transmission between two expression of these types are not permitted.
The compatibility rules between two types are as follows:

1. The basic types are not compatible with one another.

2. Two types of different bit width are not compatible together with two
   exceptions:

   - Two vectors of unsigned of are compatible together whatever their
     respective size may be.

   - Two vectors of signed of are compatible together whatever their respective
     size may be.

3. Two types of different endianness are not compatible together.

3. Vectors are compatible if they have the same width and if their sub
   types are compatible.

4. Hierarchical types are compatible if the have the same sub types names
   and if each sub type of same name are compatible.

The type of an expression can be converted to one of another type using a
casting operator. Please refer to section [Casting operators](#cast) for
more details about such an operator.


#### Declaring new types

For sake of readability, it is possible, and recommended, to declare new types
in HDLRuby::High. This is done using the `type` keyword as follows:

```ruby
type :<new type name> do
   <type description>
end
```

Or, alternatively as follows:

```ruby
type(:<new type name>) { <type description> }
```

For example, one can declare an 8-bit vector as a new `char` type as follows:

```ruby
type(:char) { bit[7..0] }
```

From there, `char` can be used like the standard `bit`, `usinged` and `signed`
types. For example, declaring a new input char signal can be done as follows:

```ruby
char.input :sig
```


### Expressions
<a name="expressions"></a>

Expressions are any construct that represents a value associated with a type.
They include [immediate values](#values), [reference to signals](#references)
and operations among other expressions using [expression operators](#operators).


### Immediate values
<a name="values"></a>

The immediate values of HDLRuby::High can represent the values of vectors of
`bit`, `unsigned` and `signed`. They are described with a header that indicates
the vector type and the base used for representing the value, followed by a
numeral representing the value.  The bit width of a value is obtained by
default from the width of the numeral, but it is also possible to enforce it in
the header.

The vector type specifiers are the followings:
 
 - `b`: `bit` type, can be omitted,
  
 - `u`: `unsigned` type,

 - `s`: `signed` type, the last figure is signed extended if required for the
        binary, octal and hexadecimal bases, but not for the decimal base.

The base specifiers are the followings:

 - `b`: binary,

 - `o`: octal,
 
 - `d`: decimal,

 - `h`: hexadecimal.

For example, all the following immediate values represent an 8-bit `100` (either
in unsigned or signed representation):

```ruby
bb01100100
b8b1100100
b01100100
u8d100
s8d100
uh64
s8o144
```

__Notes__:

 - Other values are built combining immediate values with operators. For
   example, -100 can be represented with a decimal immediate as `-d100`.

 - Ruby immediate values can also be used, their bit width is automatically
   adjusted to match the data type of the expression they are used in. Please
   notice this adjusting may change the value of the immediate, for example the
   following code will actually  set `sig` to 4 instead of 100:

   ```ruby
   [3..0].inner sig
   sig <= 100
   ```


### References
<a name="references"></a>

References are expressions used to designate signals, or a part of signals.

The most simple reference is simply the name of a signal, and it designates the
signal of the current system corresponding to this name. For instance, in the
following code, inner signal `sig0` is declared, and therefore the name *sig0*
becomes a reference to designate this signal.

```ruby
# Declaration of signal sig0.
inner :sig0

# Access to signal sig0 using a name reference.
sig0 <= 0
```

In oder to designate the signal of another system, or a sub signal of a
hierarchical signal, the `.` operator is to be used as follows:

```ruby
<parent name>.<signal name>
```

For example, in the following code, input signal `d` of system instance `dff0`
is connected to sub signal `sub0` of hierarchical signal `sig`.

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   behavior(clk.posedge) { q <= d & ~rst }
end

system :my_system do
   input :clk, :rst
   { sub0: bit, sub1: bit}.inner sig
   
   dff(:dff0).(clk: clk, rst: rst)
   dff0.d <= sig.sub0
   ...
end
```

### Expression operators
<a name="operators"></a>

The following table gives a summary of the operator available in HDLRuby::High.
More details are given for each group of operator in the subsequent sections.

<style>
table { width: 60%; }
</style>

| arithmetic operators                          |
| :---:         | :---                          |

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :+            | addition                      |
| :-            | subtraction                   |
| :\*           | multiplication                |
| :/            | division                      |
| :%            | modulo                        |
| :\*\*         | power                         |
| :+@           | positive sign                 |
| :-@           | negation                      |

| Comparison operators                          |
| :---:         | :---                          |

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :==           | equality                      |
| :!=           | difference                    |
| :>            | greater than                  |
| :<            | smaller than                  |
| :>=           | greater or equal              |
| :<=           | smaller or equal              |

| Logic and shift operators                     |
| :---:         | :---                          |

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :&            | bitwise / logical and         |
| :|            | bitwise / logical or          |
| :~            | bitwise / logical not         |
| :mux          | multiplex                     |
| :<< / :ls     | left shift                    |
| :>> / :rs     | right shift                   |
| :lr           | left rotate                   |
| :rr           | right rotate                  |

| Casting operators                             |
| :---:         | :---                          |

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :to\_bit      | cast to bit vector            |
| :to\_unsigned | cast to unsigned vector       |
| :to\_signed   | cast to signed vector         |
| :to\_big      | cast to big endian            |
| :to\_little   | cast to little endian         |
| :reverse      | reverse the bit order         |
| :ljust        | increase width from the left  |
| :rjust        | increase width from the right |
| :zext         | zero extension                |
| :sext         | sign extension                |

| Selection /concatenation operators            |
| :---:         | :---                          |

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :[]           | sub vector selection          |
| :@[]          | concatenation operator        |
| :.            | field selection               |


__Notes__:
 
 - The operator precedence is the one of Ruby.

 - Ruby does not allow to override the `&&`, the `||` and the `?:` operators so
   that they are not present in HDLRuby::High. Instead of the `?:` operator,
   HDLRuby::High provides the more general multiplex operator `mux`. However,
   HDLRuby::High does not provides any replacement for the `&&` and the `||`
   operators, please refer to section [Logic operators](#logic) for a
   justification about this issue.

#### Arithmetic operators
<a name="arithmetic"></a>

The arithmetic operators can only be used on `bit`, `unsigned` or `signed`
vector types. These operators are `+`, `-`, `*`, `%` and the unary arithmetic
operators are `-` and `+`. They have the same meaning as their Ruby
equivalents. The operation actually performed depends on the data types of
the operands according to the following table:

<style>
table { width: 90%; }
</style>

| type of operand(s) | operator  | type of arithmetic | type of result    | width of result |
| :---               | :---      | :---               | :---              | :---
| both `bit`         | any       | unsigned           | `bit`             | largest operand's
| both `unsigned`    | :+ and :- | unsigned           | `unsigned`       | largest operand's plus 1 |
| `bit` and `unsigned` | :+ and :- | unsigned           | `unsigned`       | largest operand's plus 1 |
| both `signed`    | :+ and :- | signed  | `signed`       | largest operand's plus 1 |
| `bit` and `signed`    | :+ and :- | signed  | `signed`       | largest operand's plus 1 |
| `unsigned` and `signed` | :+ and :- | signed  | `signed`       | largest operand's plus 1 |
| both `unsigned`    | :\*     | unsigned           | `unsigned`       | twice the largest operand's |
| `bit` and `unsigned` | :\* | unsigned           | `unsigned`       | twice the largest operand's |
| both `signed`    | :\* | signed  | `signed`       | twice largest operand's |
| `bit` and `signed`    | :\* | signed  | `signed`       | twice the largest operand's |
| `unsigned` and `signed` | :\* | signed  | `signed`       | twice the largest operand's |
| both `unsigned`    | :/ and :% | unsigned           | `unsigned`       | largest operand's |
| `bit` and `unsigned` | :/ and :% | unsigned           | `unsigned`       | largest operand's |
| both `signed`    | :/ and :% | signed  | `signed`       | largest operand's |
| `bit` and `signed`    | :/ and :% | signed  | `signed`       | largest operand's |
| `unsigned` and `signed` | :/ and :% | signed  | `signed`       | largest operand's |
| any | :+@ | identity | no change | no change |
| `bit` | :-@ | two complement | `bit` | operand's |
| `unsigned` | :-@ | two complement | `unsigned` | operand's |
| `signed` | :-@ | opposite | `signed` | operand's plus 1 |


In the table above:

 - Unsigned arithmetic stands from binary arithmetic without any sign. In this
   case, the smallest operand is zero-extended to the width of the largest one.
 - Signed arithmetic stands for two's complement arithmetic. In this case, the
   `signed` operands are signed extended, and the `unsigned` or the `bit`
   operands are zero extended to the width of the largest value.

#### Comparison operators
<a name="comparison"></a>

Comparison operators are the operators whose result is either true or false.
In HDLRuby::High, true and false are represented by respectively `bit` value 1
and `bit` value 0. This operators are `==`, `!=`, `<`, `>`, `<=`, `>=` . They
have the same meaning as their Ruby equivalents.

__Note__:
 
 - When compared, `bit` vector values are evaluated as unsigned values.


#### Logic and shift operators
<a name="logic"></a>

In HDLRuby::High, there is no boolean operators, but only bitwise ones.  For
performing boolean computation it is necessary to use single bit values.  The
bitwise logic binary operators are `&`, `|`, and `^`, and the unary one is `~`.
They have the same meaning as their Ruby equivalents.

__Note__: there is two reasons why there is no boolean operators

 1. Ruby language does not support redefinition of the boolean operators

 2. In Ruby, each value which is not `false` nor `nil` is considered to be
    true. This is perfectly relevant for software, but not for hardware where
    the basic data types are bit vectors. Hence, it seemed preferable to
    support boolean computation for one-bit values only, which can be done
    through bitwise operations.

The shift operators are `<<` and `>>` and have the same meaning as their Ruby
equivalent. They do not change the bit width, and preserve the sign for `signed`
values.

The rotation operators are `rl` and `rr`, respectively for left and right
rotate. Like the shift they do not change the bit width and preserve the
sign for `signed` values. However, since such operator do not exist in Ruby,
they are actually used like methods as follows:

```ruby
<expression>.rl(<other expression>)
<expression>.rr(<other expression>)
```

For example, for rotating left signal `sig` 3 times, the following code can be
used:

```ruby
sig.rl(3)
```

It possible to perform other kind of shifts or rotations using the selection and
concatenation operators (please refer to section [Concatenation and selection
operators](#concat). 


#### Casting operators
<a name="cast"></a>

There are two kind of casting operators.  The first kind of cast changes the
type of the expression without changing its raw content, and are called the
reinterpretation casts. The second kind of cast changes both the type and the
value and are called conversion casts.

The reinterpretation casts include `to_bit`, `to_unsigned` and `to_signed` that
convert any type to a vector of respectively bit, unsigned and signed elements.
For example the following code convert an expression of hierarchical type to an
8-bit signed vector:

```ruby
[ up: signed[3..0], down: unsigned[3..0] ].inner sig
sig.to_bit <= b01010011
```

The second kind of cast change both the type and the value and are used to
adjust the width of the types. They can only be applied to vector of `bit`,
`signed` or `unsinged` and can only increase the bit width (bit width can be
truncated using the selection operator, please refer to the [next
section](#concat)). These operators include first the bit width conversion
casts: `ljust`, `rjust`, `zext` and `sext`; and include second, `to_big` and
`to_little` that convert the endianness to respectively big or little endian by
reversing the bit order if required, and `reverse` that reverse the bit order
unconditionally.

More precisely, the bit width conversion casts operate as follows:

 - `ljust` and `rjust` increases the size from respectively the left or the
   right. They take as argument the width of the new type and the value (0 or
   1) used for the bit that are added. For example the following code increases
   the size of the sig0 to 12 bits by adding 1 on the right:

   ```ruby
   [7..0].inner sig0
   [11..0].inner sig1
   sig0 <= 25
   sig1 <= sig0.ljust(12,1)
   ```

 - `zext` increases the size by adding several 0 bit on the most significant
   bit side. Therefore the side of the extension depends on the endianness of
   the expression.  This cast takes as argument the width of the resulting
   type. For example, the following code increases the size of sig0 to 12 bits
   by adding 0 on the left:

   ```ruby
   signed[7..0].inner sig0
   [11..0].inner sig1
   sig0 <= -120
   sig1 <= sig0.zext(12)
   ```

 - `sext` increases the size by duplicating the most significant bit. Therefore
   the side of the extension depends on the endianness of the expression. This
   cast take as argument the width of the resulting type. For example, the
   following increases the size of sig0 to 12 bits by adding 1 on the right:

   ```ruby
   signed[0..7].inner sig0
   [0..11].inner sig1
   sig0 <= -120
   sig1 <= sig0.sext(12)
   ```

#### Concatenation and selection operators
<a name="concat"></a>

Concatenation and selection are done using the `[]` operator as follows:

 - `[]` when taking as arguments several expressions concatenates them. For
   example, the following code concatenates sig0 to sig1:

   ```ruby
   [3..0].inner sig0
   [7..0].inner sig1
   [11..0].inner sig2
   sig0 <= 5
   sig1 <= 6
   sig2 <= [sig0, sig1]
   ```

 - `[]` when applied to an expression of `bit`, `unsigned` or `signed` vector
   types and taking as argument a range selects the bits corresponding to this
   range.  If only one bit is to select, the offset of this bit can be used
   instead.  For example, the following code selects bits from 3 to 1 of `sig0`
   and bit 4 of `sig1`:

   ```ruby
   [7..0].inner sig0
   [7..0].inner sig1
   [3..0].inner sig2
   bit.inner    sig3
   sig0 <= 5
   sig1 <= 6
   sig2 <= sig0[3..1]
   sig3 <= sig1[4]
   ```

   

### Time
<a name="time"></a>

#### Time values
<a name="time_val"></a>

In HDLRuby::High, time values can be created using the time operators, i.e.,
respectively, `s` for seconds, `ms` for millisecond, `us` for microsecond, `ns`
for nano second, `ps` for pico second and `fs` for femto second. For example the
followings are all indicating one second of time:

```ruby
1.s
1000.ms
1000000.us
1000000000.ns
1000000000000.ps
1000000000000000.fs
```


#### Time behaviors and statements
<a name="time_beh"></a>

Similarly to the other HDL, HDLRuby::High simulates time using specific
statements that advance time. However, since such statements are not
synthesizable, they are only allowed in specific non-synthesizable behavior.
These behavior are declared using the `timed` keyword as follows, and contrary
to the default behavior do not have any sensibility list.

```ruby
timed do
   <statements>
end
```

A time behavior can include any statement supported by a standard behavior,
and the additional time statements. There are two such statements:

 - The `wait` statement: it waits the amount of time given in argument before
   the following statements are executed. For example the following code
   waits 10ns before proceeding:

   ```ruby
      wait(10.ns)
   ```

   This statement can also be abbreviated using the `!` operator as follows:
   
   ```ruby
      !10.ns
   ```

 - The `repeat` statement: it repeats the execution of its block until the delay
   given in argument expires. For example the following code will execute
   repeatedly the inversion of the `clk` signal every 10 nanoseconds for 10
   seconds (i.e., it simulates a clock signal for 10 seconds):

   ```ruby
      repeat(10.s) do 
         !10.ns
         clk <= ~clk
      end
   ```

#### Parallel and sequential execution

Time behaviors can include both parallel and sequential blocks. The execution
semantic is the followings:

 - A sequential block in a time behavior is executed sequentially similarly
   to a standard behavior.

 - A parallel block in a time behavior is executed in semi-parallel fashion as
   follows:

   1. Statements are grouped in sequence until a time statement is met.

   2. The grouped sequence are executed in parallel.

   3. The time statement is executed.

   4. The subsequent statements are processed the same way.



### High-level programming features
<a name="highfeat"></a>

#### Using Ruby in HDLRuby::High

Since HDLRuby is pure Ruby code, the constructs of Ruby can be freely used
without any compatibility issue. Moreover, the Ruby code will not interfere
with the synthesizability of the design.

In particular, Ruby is object-oriented, and therefore an HDLRuby::High
description can make use of object-oriented features. For instance, it possible
to define classes, and subclasses used for generating systems or any othe
construct of HDLRuby::High.

#### Generic programming

##### Declaring

Systems can be declared with generic parameters. For that purpose, the
parameters must be given as follows:

```ruby
system :<system name> do |<list of generic parameters>|
   ...
end
```

For example, the following code describes an empty system with two generic
parameters named respectively `a` and `b`:

```ruby
system(:nothing) { |a,b| }
```

The generic parameters can be anything: values, data types, systems and so on.
For example, the following system uses generic argument `t` as a type for an
input signal, generic argument `w` as a bit range for an output signal and
generic argument `s` as a system used for creating instance `sI` whose input
and output signals `i` and `o` are connected respectively to signals `isig` and
`osig`.

```ruby
system :something do |t,w,s|
   t.input isig
   [w].output osig

   s :sI.(i: isig, o: osig)
end
```

It is also possible to use a variable number of generic parameters using the
variadic operator `*` like in the following example. In this examples, `args`
is an array containing an indefinite number of parameters.

```ruby
system(:variadic) { |*args| }
```

Finally, it is possible to pass a ruby block as generic parameter using
the block operator `&` like in the following example.

```ruby
system(:with_block) { |&blk| }
```

##### Instantiating

When instantiated, the values of the generic arguments are to be provided to
the system after the name of instance as follows:

```ruby
<system name> :<instance name>, <generic argument value 0>, ...
```

If some arguments are omitted, an exception will be raised even if the
arguments are not actually used in the system's body.

For example, in the previous section, system `nothing` did not used the
generic arguments, but the following instantiation is invalid:

```ruby
nothing :nothingI
```

However the following is valid since both generic arguments' value are provided.

```ruby
nothing :nothingI, 1,2
```

The validity of the generic value itself is checked dynamically.
For example, the following instantiation of previous system `something` 
will raise an exception since the first generic value is not a type:

```ruby
something :somethingI, 1,7..0
```

However, the following is valid:

```ruby
something :somethingI, bit,7..0
```



#### Inheritance
<a name="inherit"></a>

##### Basics

In HDLRuby::High, a system can inherit the content of one or several other
systems using the `include` command as follows: `include <list of systems>`.
This command can be put anywhere in the body of a system, the resulting content
being accessible only from there.

For example, the following code describes first a simple D-FF, and then use it
to described a FF with an additional reversed output (`qb`):

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   behavior(clk.posedge) { q <= d & ~rst }
end

system :dff_full do
    output :qb

    include dff

    qb <= ~q
end
```

For sake of readability, it is also possible to give the list of systems
to include when declaring a system as follows:

```ruby
system :<new system name>, <list of mixin systems> do
   <additional system code>
end
```

For example, the following code is another to describe `dff_full`:

```ruby
system :dff_full, dff do
   output :qb

   qb <= ~q
end
```

__Note__:

 - As a matter of implementation, HDLRuby::High systems can be seen as set
   of methods used for accessing various constructs (signals, instances).
   Hence the inheritance in HDLRuby::High is actually closer the
   ruby mixin mechanism than a true software inheritance.


##### About inner signals and system instances

By default, inner signals and system instances are not accessible through
inheritance. The can be made accessible using the `export` keyword as follows:
`export <name 0>, <name 1>, ...` . For example the following code exports
signals `clk` and `rst` and instance `dff0` of system `:exporter` so that they
can be accessed in sub system `:importer`.

```ruby
system :exporter do
   input :d
   inner :clk, :rst

   dff(:dff0).(clk: clk, rst: rst, d: d)

   export :clk, :rst, :dff0 
end

system :importer, exporter do
   input :clk0, :rst0
   output q

   clk <= clk0
   rst <= rst0
   dff.q <= q
end
```

##### Conflicts when inheriting

Signals and instances cannot be overridden, this is also the case for signals
and instances accessible through inheritance. For example the following code is
invalid since `rst` has already been defined in `dff`:

```ruby
   system :dff_bad, dff do
      input :rst
   end
```

Conflicts among several inherited systems can be avoided by renaming the
signals and instances that collides with other. The renaming mechanism is
presented in the next section.


#### Shadowed signals and instances

It is possible in HDLRuby::High to declare a signal or an instance whose name
is identical to one used in one of the included systems. In such a case, the
corresponding construct of the included system is still present, but is not
directly accessible even if exported, they are said to be shadowed.

In order to access to its shadowed signals or instances, a system must be
casted to the relevant included system using the `as` operator as follows:
`as(system)`.

For example the in following examples, signal `db` of system `dff_db` is
shadowed by signal `db` of system `dff_shadow`, but is accessed using the `as`
operator.

```ruby
system :dff_db do
   input :clk,:rst,:d
   inner :db
   output :q

   db <= ~d
   (q <= d & ~rst).at(clk.posedge)
end

system :dff_shadow, dff_db do
   output :qb, :db

   db <= ~d
   qb <= as(dff_db).db
end
```



#### Opening a system
<a name="system_open"></a>

It is possible to pursue the definition of a system after it has been declared
using the `open` methods as follows:

```ruby
<system>.open do
   <additional system description>
end
```

For example `dff`, a system describing a D-FF, can be modified to have an
inverted ouput as follows:

```ruby
dff.open do
   output :qb

   qb <= ~q
end
```

Opening a system can be used, for instance,to modify an existing system, to
describe a system in serval files, or to resolve circular dependancies among
several systems.


#### Opening an instance
<a name="instance_open"></a>

When there is a minor modification to apply to an instance of a system, it is
sometimes preferable to modify this sole instance rather than declaring a all
new system to derivate the instance from. For that purpose it is possible to
open an instance for modification as follows:

```ruby
<instance name>.open do
   <additional description for the instance>
end
```

For example, an instance of the previous `dff` system can be extended with
an inverted output as follows:
```ruby
system :some_system do
   ...
   dff :dff0
   dff0.open do
      output qb
      qb <= ~q
   end
   ...
end
```

#### Opening a single signal, or the totality of the signals

Contrary to system and system instances, signals dot not have any inner
structures. Its however sometimes useful to add features to them (cf.
[hooks](#hooks)). Again, this is done using the `open` method.
For a single signal, `open` is to be used directly on it as, and for the
totality of the signals, `open` is to be used on the `signal` keyword
as follows:

```ruby
signal.open do
   <some code>
end
```

With this latter construct, the code will be applied to all the present
and future signals of the design.




#### Hooked hardware
<a name="hook"></a>

When trying to describe a generic system, it is sometimes not possible to know
exactly which hardware is to use for handling particular signals. For example
one might want to describe a circuit which process some data, that is acquired
through an unkown interface. Not knowing the interface makes it impossible to
handle properly the timing, or the synchronization required for accessing the
signal and therefore makes it impossible to describe the circuit at all with a
conventional HDL.

It is for such cases, that HDLRuby::High provide the possibility to attach
hardware to signals and system instances using hooks.

There are four hooks defined by default for the signals: `read` and `write`,
where behaviors can be attached, and `can\_read?` and `can\_write?`, where
expressions can be attached.  Other hooks can be added to an hardware construct
by opening it, and using the `hook_<hook type>` method as follows:

```ruby
<hardware construct>.open do
   define_hook_<hook type>(:<hook name>)
end
```

For example the following code defines the behavior hook `blink` for the
signal named `led`:

```ruby
led.open do
    define_hook_behavior(:blink)
end
```

When a hook is defined for an hardware construct the corresponding kind of hardware description can be attached as follows:

```ruby
<signal or instance>.<hook name> = <expression, statement, block, behavior, ruby proc>
```

The hook can then be used, i.e., its code will be inserted in place, as
follows:

```ruby
<signal or instance>.<hook name>
```

For example, the previously defined hook on the `led` signal can be used
as follows:

```ruby
system :circuit0 do
   output :led
   led.open do
      define_hook_statement(:blink)
   end
   led.blink = led <= ~led
end

system :circuit1 do
   input :clk
   inner :led

   circuit0 :circuit0I(led : led)

   ( led.blink ).at(clk.posedge)
end
```

As it can be seen in the upper example, hooks are propagated throw connections,
and therefore the `led` of `circuit1` has access to the hook of the led of
`circuit0`.



#### Predicate and access methods

In order to get information about the current state of the hardware description
HDLRuby::High provides the following predicates:

| predicate name | predicate type | predicate meaning                          |
| :---           | :---           | :---                                       |
| `is_block?`    | bit            | tells if in execution block                |
| `is_par?`      | bit            | tells if current parallel block is parallel|
| `is_seq?`      | bit            | tells if current parallel block is sequential|
| `is_clocked?`  | bit            | tells if current behavior is clocked (activated on a sole rising or falling edge of a signal) |
| `cur_block`    | block          | gets the current block                     |
| `cur_behavior` | behavior       | gets the current behavior                  |
| `cur_system`   | system         | gets the current system                    |
| `one_up`       | block/system   | gets the upper construct (block or system) |
| `last_one`     | any            | last declared construct                    |

Several enumerators are also provided for accessing the internals of the current
construct (in the current state):

| enumerator name   | accessed elements                    |
| :---              | :---                                 |
| `each_input`      | input signals of the current system  |
| `each_output`     | output signals of the current system |
| `each_inout`      | inout signals of the current system  |
| `each_behavior`   | behaviors of the current system      |
| `each_event`      | events of the current behavior       |
| `each_block`      | blocks of the current behavior       |
| `each_statement`  | statements of the current block      |
| `each_inner`      | inner signals of the current block (or system if not within a block) |

#### Global signals

HDLRuby::High allows to declare global signals similarity the same way
system's signals are declare, but outside the scope of any system.
After being declared, these signals are accessible directly from within an
construct of a HDLRuby::High description.

In order to ease the design of standardized libraries, the following global
signals are defined by default:

| signal name | signal type | signal function                       |
| :---        | :---        | :---                                  |
| `$reset`    | bit         | global reset                          |
| `$resetb`   | bit         | global reset complement               |
| `$clk`      | bit         | global clock                          |
| `$err`      | bit         | used to indicate if an error occurred |
| `$errno`    | bit[7..0]   | indicates the error number            |

__Note__:
 
 - The default global signals are considered to be inner signals
   (inner to the implicit system representing the universe).

 - When not used, the default global signals are discarded.



#### Defining and executing ruby method within HDLRuby::High constructs
<a name="method"></a>

Like with any Ruby program it is possible to define and execute methods
anywhere in HDLRuby:High using the standard Ruby syntax. When defined,
a method is attached to the enclosing HDLRuby::High construct. For instance,
when defining a method when declaring a system, it will be usable within
this system, while when defining a method outside any construct, it will
be usable everywhere in the HDLRuby::High description.

A method can include HDLRuby::High code in which case the resulting hardware
is appended to the current construct. For example the following code
adds a connection between `sig0` and `sig1` in system `sys0`, and transmission
between the same signal in `clk`-dependent behavior of `sys1`.

```ruby
def some_arrow
   sig1 <= sig0
end

system :sys0 do
   input :sig0
   output :sig1

   some_arrow
end

system :sys1 do
   input :sig0, :clk
   output :sig1

   behavior(clk.posedge) do
      some_arrow
   end
end
```

__Warning__:

- In the above example, indeed, the semantic of `some_arrow` changes
  depending on where it is invoked from: within a system, it is a connection,
  within a behavior it is a transmit.

- Using Ruby method for describing hardware might lead to weak code, for
  example the in following code, the method declares `in0` as input signal.
  Hence, while used in `sys0` no problems happens, an exception is will
  be raised for `sys1` because a signal `in0` is already declare, and will
  also be raised for `sys2` because it is not possible to declare an input
  from within a behavior.

  ```ruby
  def in_decl
     input :in0
  end

  system :sys0 do
     in_decl
  end

  system :sys1 do
     input :in0
     in_decl
  end

  system :sys2 do
     behavior do
        in_decl
     end
  end
  ```

Like any other Ruby method, methods defined in HDLRuby::High supports
variadic arguments, named arguments and block arguments.
For example, the following method can be used to connects a driver to multiple
signals:

```ruby
def mconnect(driver, *signals)
   signals.each do |signal|
      signal <= driver
   end
end

system :sys0 do
   input :i0
   input :o0, :o1, :o2, oi3

   mconnect(i0,o0,o1,o2,o3)
end
```


While requiring care, properly designed method can be very useful for clean
code reuse. For example the following method allow to start the execution
of a behavior's block after a given number of cycles:

```ruby
def after(cycles,rst = $reset)
   block do
      inner :count
      hif rst == 1 do
         count <= 0
      end
      helse do
         hif count < cycles do
            count <= count + 1
         end
         helse
            yield
         end
      end
   end
end
```

In the code above: 
 
 - the default initialization of `rst` to the global `$reset` allows to reset
   the counter even if no such signal it provided as argument.

 - `block` ensures that the `count` signal do not conflict with anther signal
   with the same name.

 - the `yield` keyword is the standard Ruby one, and executes the block passed
   as argument.

This method can be used like with the following example that switches a LED
on after 1000000 clock cycles:

```ruby
system :led_after do
   output :led
   input :clk

   behavior(clk.posedge) do
      (led <= 0).hif($reset)
      after(100000) { led <= 1 }
   end
end
```

__Note__:

 - Ruby's closure still applies in HDLRuby::High, hence, the block sent to
   after can use the signals and instances of the current block. Moreover,
   the signal declared in the `after` method will not collide with them.


#### Dynamic description

When describing a system, it is possible to disconnect or completely undefine
a signal or an instance.


### Extending HDLRuby::High
<a name="extend"></a>

Like any Ruby classes, the constructs of HDLRuby::High can be dynamically
extended. If it is not recommended to change their internal structure,
it is possible to add methods to them for extension.

#### Extending HDLRuby::High constructs globally

By gobal extension of HDLRuby::High constructs we actually mean the classical
extension of Ruby classes by monkey patching the corresponding class. For
example, it is possible to add a methods giving the number of signals in the
interface of a system instance as follows:

```ruby
class SystemI
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

From there the methods `interface_size` can be used on any system instance
as follows: `<system instance>.interface_size`.

The following table gives the class corresponding to each construct of
HDLRuby::High.

| construct       | class      |
| :---            | :---       |
| data type       | Type       |
| system          | SystemT    |
| system instance | SystemI    |
| signal          | Signal     |
| connection      | Connection |
| behavior        | Behavior   |
| event           | Event      |
| block           | Block      |
| transmit        | Transmit   |
| hif             | Hif        |
| hcase           | Hcase      |


#### Extending HDLRuby::High constructs locally

By local extension of a HDLRuby::High construct, we mean that while the
construct will be changed, all the other constructs (even when of the same
kind) will remain unchanged. This is achieved like in Ruby by accessing the
eigenclass using the `singleton_class` method, and extending it using the
`class_eval` method.  For example, with the following code, only system
`dff` will respond to method `interface_size`:

```ruby
dff.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

It is also possible to extend locally a system instance using the same methods.
For example, with the following code, only instance `dff0` will respond to
method `interface_size`:

```ruby
dff :dff0

dff0.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

Finally, it is possible to extend locally all the instances of a system
using the `singleton_method` in place of `singleton_class` method.
For example, with the following code, all the instance of system `dff`
will respond to method `interface_szie`:

```ruby
dff.singleton_instance.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

#### Modifying the generation behavior

The main purpose of allowing global and local extensions of HDLRuby::High
construct is to give the user the possibility implements its own generation
methods. For example, one may want to implement some algorithm for a given
system, which will then included into the systems that requires this
generation step. Assuming this system is called `my_base`, he could
write the following code:

```ruby
system(:my_base) {}

my_base.singleton_instance.class_eval do
   def my_generation
      <some code>
   end
end
```

Then he could declare his systems as follows so that the inherit from
`my_generation` method:

```ruby
system :some_system, my_base do
   <some system description>
end
```

However, when generation the low-level description of his system he
will need to write some code similar to the following:

```ruby
some_system :instance0
instance0.my_generation
low = instance0.to_low
```

This can be avoid by redefining the `to_low` method as follows:

```ruby
system(:my_base) {}

my_base.singleton_instance.class_eval do
   def my_generation
      <some code>
   end

   alias :_to_low :to_low
   def to_low
      my_generation
      _to_low
   end
end
```

This way, calling directly `to_low` will automatically use `my_generation`.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Lovic Gauthier/HDLRuby.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

