# About HDLRuby

HDLRuby is a library for describing and simulating digital electronic
systems.

__Note__:

If you are new to HDLRuby, it is recommended that you consult first the following tutorial (even if you are a hardware person):

 * [HDLRuby tutorial for software people](tuto/tutorial_sw.md)

__What's new__

For HDLRuby version 3.1.0:

 * [Functions for sequencers](#sequencer-specific-function-std-sequencer_func-rb) supporting recursion;

 * The `function` keyword was replaced with `hdef` for better consistency with the new functions for sequencers;

 * The `steps` command was added for waiting several steps in a sequencer;

 * Verilog HDL code generation was improved to preserve as much as possible the original names of the signals;

 * Several bug fixes for the sequencers.

For HDLRuby version 3.0.0:

 * This section;

 * [The sequencers](#sequencer-software-like-hardware-coding-stdsequencerrb) for software-like hardware design;

 * A [tutorial](tuto/tutorial_sw.md) for software people;

 * The stable [standard libraries](#standard-libraries) are loaded by default.


__Install__:

The recommended installation method is from rubygem as follows:

```
gem install HDLRuby
```

Developers willing to contribute to HDLRuby can install the sources from GitHub as follows:

```
git clone HDLRuby
```

__Warning__: 

 - This is still preliminary work which may change before we release a stable version.
 - It is highly recommended to have both basic knowledges of the Ruby language and hardware description languages before using HDLRuby.


# Compiling HDLRuby descriptions

## Using the HDLRuby compiler

'hdrcc' is the HDLRuby compiler. It takes as input an HDLRuby file, checks it, and can produce as output a Verilog HDL, VHDL, or a YAML low-level description of HW components but it can also simulate the input description.


__Usage__:

```
hdrcc [options] <input file> <output directory>
```

Where:

 * `options` is a list of options
 * `<input file>` is the initial file to compile (mandatory)
 *  `<output directory>` is the directory where the generated files will be put

|  Options         |          |
|:------------------|:-----------------------------------------------------|
| `-I, --interactive` | Run in interactive mode                            |
| `-y, --yaml`      | Output in YAML format                                |
| `-v, --verilog`   | Output in Verilog HDL format                         |
| `-V, --vhdl`      | Output in VHDL format                                |
| `-s, --syntax`    | Output the Ruby syntax tree                          |
| `-C, --clang`     | Output the C code of the standalone simulator        |
| `-S, --sim`       | Perform the simulation with the default engine       |
| `--csim`          | Perform the simulation with the standalone engine    |
| `--rsim`          | Perform the simulation with the Ruby engine          |
| `--rcsim`         | Perform the simulation with the Hybris engine        |
| `--vcd`           | Make the simulator generate a VCD file               |
| `-d, --directory` | Specify the base directory for loading the HDLRuby files |
| `-D, --debug`     | Set the HDLRuby debug mode |
| `-t, --top system`| Specify the top system describing the circuit to compile |
| `-p, --param x,y,z`     | Specify the generic parameters                 |
| `--get-samples`   | Copy the sample directory (hdr_samples) to current one, then exit |
| `--version`       | Show the version number, then exit                  |
| `-h, --help`      | Show the help message                                    |

__Notes__:

* If no top system is given, it is automatically looked for from the input file.
* If no option is given, it simply checks the input file.
* If you are new to HDLRuby, or if you want to see how new features work, we strongly encourage to get a local copy of the test HDLRuby sample using:  
    
  ```bash
  hdrcc --get-samples
  ```  
    
  Then in your current directory (folder) the `hdr_samples` subdirectory will appear that contains several HDLRuby example files. Details about the samples can be found here: [samples](#sample-hdlruby-descriptions).


__Examples__:

* Compile system named `adder` from `adder.rb` input file and generate a low-level YAML description into directory `adder`:

```bash
hdrcc --yaml --top adder adder.rb adder
```

* Compile `adder.rb` input file and generate a low-level Verilog HDL description into the directory `adder`:

```bash
hdrcc -v adder.rb adder
```
  
* Compile system `adder` whose bit width is generic from `adder_gen.rb` input file to a 16-bit circuit low-level VHDL description into directory `adder`:

```bash
hdrcc -V -t adder --param 16 adder_gen.rb adder
```

* Compile system `multer` with inputs and output bit width is generic from `multer_gen.rb` input file to a 16x16->32-bit circuit whose low-level YAML description into directory `multer`:

```bash
hdrcc -y -t multer -p 16,16,32 multer_gen.rb multer
```

* Simulate the circuit described in file `counter_bench.rb` using the default simulation engine and putting the simulator's files in the directory `counter`:

```bash
hdrcc -S counter_bench.rb counter
```

As a policy, the default simulation engine is set to the fastest one (currently it is the hybrid engine).

* Run in interactive mode.

```bash
hdrcc -I
```

* Run in interactive mode using pry as UI.

```bash
hdrcc -I pry
```

## Using HDLRuby in interactive mode

When running in interactive mode, the HDLRuby framework starts a REPL prompt and creates a working directory called 'HDLRubyWorkspace'. By default, the REPL is 'irb', but it can be set to 'pry'. Within this prompt, HDLRuby code can be written like in an HDLRuby description file. However, to process this code the following commands are added:

* Compile an HDLRuby module:

```ruby
hdr_make(<module>)
```

* Generate and display the IR of the compiled module in YAML form:

```ruby
hdr_yaml
```

* Regenerate and display the HDLRuby description of the compiled module:

```ruby
hdr_hdr
```

* Generate and output in the working directory the Verilog HDL RTL of the compiled module:

```ruby
hdr_verilog
```

* Generate and output in the working directory the Verilog HDL RTL of the compiled module:

```ruby
hdr_vhdl
```

* Simulate the compiled module:

```ruby
hdr_sim
```




# HDLRuby programming guide

HDLRuby has been designed to bring the high flexibility of the Ruby language to hardware descriptions while ensuring that they remain synthesizable. In this
context, all the abstractions provided by HDLRuby are in the way of describing hardware, but not in its execution model, this latter being RTL by construction.

The second specificity of HDLRuby is that it supports natively all the features of the Ruby language.

__Notes__:

- It is still possible to extend HDLRuby to support hardware descriptions of a higher level than RTL, please refer to section [Extending HDLRuby](#extending-hdlruby) for more details.
- In this document, HDLRuby constructs will often be compared to their Verilog HDL or VHDL equivalents for simpler explanations.

## Introduction

This introduction gives a glimpse of the possibilities of the language.
However, we do recommend consulting the section about the [high-level programming features](#high-level-programming-features) to have a more complete view of the advanced possibilities of this language.

At first glance, HDLRuby appears like any other HDL (like Verilog HDL or VHDL), for instance, the following code describes a simple D-FF:

```ruby
system :dff do
   bit.input :clk, :rst, :d
   bit.output :q

   par(clk.posedge) do
      q <= d & ~rst
   end
end
```

As can be seen in the code above, `system` is the keyword used for describing a digital circuit. This keyword is the equivalent of the Verilog HDL `module`. In such a system, signals are declared using a `<type>.<direction>` construct where `type` is the data type of the signal (e.g., `bit` as in the code above) and `direction` indicates if the signal is an input, an output, an inout or an inner one; and executable blocks (similar to `always` block of Verilog HDL) are described using the `par` keyword when they are parallel and `seq` when they are sequential (i.e., with respectively non-blocking and blocking assignments).

After such a system has been defined, it can be instantiated. For example, a single instance of the `dff` system named `dff0` can be declared as follows:

```ruby
dff :dff0
```

The ports of this instance can then be accessed to be used like any other signals, e.g., `dff0.d` for accessing the `d` input of the FF.

Several instances can also be declared in a single statement. For example, a 2-bit counter based on the previous `dff` circuits can be described as follows:

```ruby
system :counter2 do
   input :clk,:rst
   output :q

   dff [ :dff0, :dff1 ]

   dff0.clk <= clk
   dff0.rst <= rst
   dff0.d   <= ~dff0.q

   dff1.clk <= ~dff0.q 
   dff1.rst <= rst
   dff1.d   <= ~dff1.q

   q <= dff1.q
end
```

The instances can also be connected while being declared. For example, the code above can be rewritten as follows:

```ruby
system :counter2 do
   input :clk, :rst
   output :q

   dff(:dff0).(clk: clk, rst: rst, d: ~dff0.q)
   dff(:dff1).(~dff0.q, rst, ~dff1.q, q)
end
```

In the code above, two possible connection methods are shown: for `dff0` ports are connected by name, and for `dff1` ports are connected in declaration order. Please notice that it is also possible to connect only a subset of the ports while declaring, as well as to reconnect already connected ports in further statements.

While a circuit can be generated from the code given above, a benchmark must
be provided to test it. Such a benchmark is described by constructs called
timed behavior that give the evolution of signals depending on the time.
For example, the following code simulates the previous D-FF for 4 cycles
of 20ns each, with a reset on the first cycle, set of signal `d` to 1 for
the third cycle and set this signal to 0 for the last.

```ruby
system :dff_bench do
   
   dff :dff0

   timed do
      dff0.clk <= 0
      dff0.rst <= 1
      !10.ns
      dff0.clk <= 1
      !10.ns
      dff0.clk <= 0
      dff0.rst <= 0
      dff0.d   <= 1
      !10.ns
      dff0.clk <= 1
      !10.ns
      dff0.clk <= 0
      !10.ns
      dff0.clk <= 1
      !10.ns
      dff0.clk <= 0
      dff0.d   <= 1
      !10.ns
      dff0.clk <= 1
      !10.ns
   end
end
```

---

The code describing a `dff` given above is not much different from its equivalent in any other HDL.  However, HDLRuby provides several features for achieving higher productivity when describing hardware. We will now describe a few of them.

First, several syntactic sugars exist that allow shorter code, for instance, the following code is strictly equivalent to the previous description of `dff`:

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end
```

Then, it often happens that a system will end up with only one instance.
In such a case, the system declaration can be omitted, and an instance can be directly declared as follows:

```ruby
instance :dff_single do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end
```

In the example above, `dff_single` is an instance describing, again, a D-FF, but whose system is anonymous.

Furthermore, generic parameters can be used for anything in HDLRuby.
For instance, the following code describes an 8-bit register without any parameterization:

```ruby
system :reg8 do
   input :clk, :rst
   [7..0].input :d
   [7..0].output :q

   (q <= d & [~rst]*8).at(clk.posedge)
end
```

But it is also possible to describe a register of arbitrary size as follows, where `n` is the parameter giving the number of bits of the register:

```ruby
system :regn do |n|
   input :clk, :rst
   [n-1..0].input :d
   [n-1..0].output :q

   (q <= d & [~rst]*n).at(clk.posedge)
end
```

Or, even further, it is possible to describe a register of arbitrary type (not only bit vectors) as follows:

```ruby
system :reg do |typ|
   input :clk, :rst
   typ.input :d
   typ.output :q

   (q <= d & [~rst]*typ.width).at(clk.posedge)
end
```

Wait... I have just realized that D-FF without any inverted output does not look very serious. So, let us extend the existing `dff` to provide an inverted output. There are three ways for doing this. First, inheritance can be used: a new system is built inheriting from `dff` as it is done in the following code.

```ruby
system :dff_full, dff do
   output :qb
   qb <= ~q
end
```

The second possibility is to modify `dff` afterward. In HDLRuby, this is achieved using the `open` method as it is done in the following code:

```ruby
dff.open do
   output :qb
   qb <= ~q
end
```

The third possibility is to modify directly a single instance of `dff` which requires an inverted output, using again the `open` method, as in the following code:

```ruby
# Declare dff0 as an instance of dff
dff :dff0

# Modify it
dff0.open do
   output :qb
   qb <= ~q
end
```

In this latter case, only `dff0` will have an inverted output, the other instances of `dff` will not change.

Now assuming we opted for the first solution, we have now `dff_full`, a highly advanced D-FF with such unique features as an inverted output. So, we would like to use it in other designs, for example, a shift register of `n` bits. Such a system will include a generic number of `dff_full` instances and can be
described as follows making use of the native Ruby method `each_cons` for connecting them:

```ruby
system :shifter do |n|
   input :clk, :rst
   input :i0
   output :o0, :o0b

   # Instantiating n D-FF
   [n].dff_full :dffIs
   
   # Connect the clock and the reset.
   dffIs.each { |ff| ff.clk <= clk ; ff.rst <= rst }

   # Interconnect them as a shift register
   dffIs[0..-1].each_cons(2) { |ff0,ff1| ff1.d <= ff0.q }

   # Connects the input and output of the circuit
   dffIs[0].d <= i0
   o0 <= dffIs[-1].q
   o0b <= dffIs[-1].qb
end
```

As can be seen in the above examples, in HDLRuby, any construct is an object and therefore include methods. For instance, declaring a signal of a given `type` and direction (input, output, or inout) is done as follows so that `direction` is a method of the type, and the signal names are the arguments of this method (symbols or string are supported.)

```ruby
<type>.<direction> <list of symbols representing the signal>
```

Of course, if you do not need to use the specific component `dff_full` you can describe a shift register more simply as follows:

```ruby
system :shifter do |n|
   input :clk, :rst
   input :i0
   output :o0
   [n].inner :sh
   
   par (clk.posedge) do
      hif(rst) { sh <= 0 }
      helse { sh <= [sh[n-2..0], i0] }
   end
   
   o0 <= sh[n-1]
end
```

Now, let us assume you want to design a circuit that performs a sum of products of several inputs with constant coefficients. For the case of 4 16-bit signed inputs and given coefficients as 3, 4, 5, and 6. The corresponding basic code could be as follows:

```ruby
system :sumprod_16_3456 do
   signed[16].input :i0, :i1, :i2, :i3
   signed[16].output :o
   
   o <= i0*3 + i1*4 + i2*5 + i3*6
end
```

The description above is straightforward, but it would be necessary to rewrite it if another circuit with different bit widths or coefficients is to be designed. Moreover, if the number of coefficients is large an error in the expression will be easy to make and hard to find. A better approach would be to use a generic description of such a circuit as follows:

```ruby
system :sumprod do |typ,coefs|
   typ[coefs.size].input :ins
   typ.output :o
   
   o <= coefs.each_with_index.reduce(_b0) do |sum,(coef,i)|
      sum + ins[i]*coef
   end
end
```

In the code above, there are two generic parameters,
`typ`, which indicates the data type of the circuit, and `coefs`, which is assumed to be an array of coefficients. Since the number of inputs depends on the number of provided coefficients, it is declared as an array of `width` bit signed whose size is equal to the number of coefficients.

The description of the sum of products may be more difficult to understand for people not familiar with the Ruby language. The `each_with_index` method iterates over the coefficients adding their index as an iteration variable, the resulting operation (i.e., the iteration loop) is then modified by the `reduce` method that accumulates the code passed as arguments. This code, starting by `|sum,coef,i|` simply performs the addition of the current accumulation result (`sum`) with the product of the current coefficient (`coef`) and input (`ins[i]`, where `i` is the index) in the iteration. The argument `_b0` initializes the sum to `0`.

While slightly longer than the previous description, this description allows declaring a circuit implementing a sum of products with any bit width and any number of coefficients. For instance, the following code describes a signed 32-bit sum of products with  16 coefficients (just random numbers here).

```ruby
sumprod(signed[32], [3,78,43,246, 3,67,1,8, 47,82,99,13, 5,77,2,4]).(:my_circuit)  
```

As seen in the code above, when passing a generic argument for instantiating a generic system, the name of the instance is put between brackets for avoiding confusion.

While the description `sumprod` is already usable in a wide range of cases, it still uses standard addition and multiplication. However, there are cases where specific components are to be used for these operations, either for the sake of performance, compliance with constraints, or because functionally different operations are required (e.g., saturated computations). This can be solved by using functions implementing such computation in place of operators, for example, as follows:

```ruby
system :sumprod_func do |typ,coefs|
   typ[coefs.size].input ins
   typ.output :o
   
   o <= coefs.each_with_index.reduce(_b0) do 
   |sum,(coef,i)|
      add(sum, mult(ins[i]*coef))
   end
end
```

Where `add` and `mult` are functions implementing the required specific operations. HDLRuby functions are equivalent to the Verilog HDL ones. In our example, an addition that saturates at 1000 could be described as follows:

```ruby
hdef :add do |x,y|
   inner :res
   seq do
      res <= x + y
      (res <= 1000).hif(res > 1000)
   end
end
```

With HDLRuby functions, the result of the last statement in the return value, in this case, that will be the value of res. The code above is also an example of the usage of the postfixed if statement, it is an equivalent of the following code:

```ruby
      hif(res>1000) { res <= 1000 }
```

With functions, it is enough to change their content to obtain a new kind of circuit without changing the main code. This approach suffers from two drawbacks though: first, the level of saturation is hard coded in the function, and second, it would be preferable to be able to select the function to execute instead of modifying its code. For the first problem, a simple approach is to add an argument to the function given the saturation level. Such an add function would therefore be as follows:

```ruby
hdef :add do |max, x, y|
   inner :res
   seq do
      res <= x + y
      (res <= max).hif(res > max)
   end
end
```

It would however be necessary to add this argument when invoking the function, e.g., `add(1000,sum,mult(...))`. While this argument is relevant for addition with saturation, it is not for the other kind of addition operations, and hence, the code of `sumprod` is no general purpose.

HDLRuby provides two ways to address such issues. First, it is possible to pass code as an argument. In the case of `sumprod`, it would then be enough to add two arguments that perform the required addition and multiplication. The example is below:

```ruby
system :sumprod_proc do |add,mult,typ,coefs|
   typ[coefs.size].input ins
   typ.output :o
   
   o <= coefs.each_with_index.reduce(_b0) do 
   |sum,(coef,i)|
      add.(sum, mult.(ins[i]*coef))
   end
end
```

__Note__: 
 
- With HDLRuby, when some code is passed as an argument, it is invoked using the `.()` operator, and not simple parenthesis-like functions.

Assuming the addition with saturation is now implemented by a function named `add_sat` and a multiplication with saturation is implemented by a function named `mult_sat` (with similar arguments), a circuit implementing a signed 16-bit sum of product saturating at 1000 with 16 coefficients could be described as follows:

```ruby
sumprod_proc( 
        proc { |x,y| add_sat(1000,x,y) },
        proc { |x,y| mult_sat(1000,x,y) },
        signed[64], 
        [3,78,43,246, 3,67,1,8,
         47,82,99,13, 5,77,2,4]).(:my_circuit)
```

As seen in the example above, a piece of code is passed as an argument using the proc keyword.

A second possible approach provided by HDLRuby is to declare a new data type with redefined addition and multiplication operators. For the case of a 16-bit saturated addition and multiplication the following generic data type can be defined (for signed computations):

```
signed[16].typedef(:sat16_1000)

sat16_1000.define_operator(:+) do |x,y|
      tmp = x + y
      mux(tmp > 1000,tmp,1000)
   end
end
```

In the code above, the first line defines the new type `sat16_1000` to be 16-bit signed and the remaining overloads (redefines) the `+` operator for this type (the same should be done for the `*` operator).
Then, the initial version of `sumprod` can be used with this type to achieve saturated computations as follows:

```ruby
sumprod(sat16_1000, 
        [3,78,43,246, 3,67,1,8,
        47,82,99,13, 5,77,2,4]).(:my_circuit)
```

It is also possible to declare a generic type. For instance, a generic signed type with saturation can be declared as follows:

```ruby
typedef :sat do |width, max|
   signed[width]
end


sat.define_operator(:+) do |width,max, x,y|
      tmp = x + y
      mux(tmp > max, tmp, max)
   end
end
```

__Note:__

- The generic parameters have also to be declared for the operator redefinitions.

With this generic type, the circuit can be declared as follows:

```ruby
sumprod(sat(16,1000), 
        [3,78,43,246, 3,67,1,8,
         47,82,99,13, 5,77,2,4]).(:my_circuit)
```


Lastly note, HDLRuby is also a language with supports reflection for all its constructs. For example, the system of an instance can be accessed using the `systemT` method, and this latter can be used to create other instances. For example, previously, `dff_single` was declared with an anonymous system (i.e., it cannot be accessed by name). This system can however be used as follows to generate another instance:

```ruby
dff_single.systemT.instantiate(:dff_not_single)
```

In the above example, `dff_not_single` is declared to be an instance
of the same system as `dff_single`.

This reflection capability can also be used for instance, for accessing the data type of a signal (`sig.type`), but also the current basic block (`cur_block`), the current process (`cur_behavior`), and so on.
The standard library of HDLRuby includes several hardware constructs like finite state machine descriptors and is mainly based on using these reflection features.



## How does HDLRuby work

Contrary to descriptions in high-level HDL like SystemVerilog, VHDL, or SystemC, HDLRuby descriptions are not software-like descriptions of hardware but are programs meant to produce hardware descriptions. In other words, while the execution of a common HDL code will result in some simulation of the described hardware, the execution of HDLRuby code will result in some low-level hardware description. This low-level description is synthesizable and can also be simulated like any standard hardware description.
This decoupling of the representation of the hardware from the point of view of the user (HDLRuby), and the actual hardware description (HDLRuby::Low) makes it possible to provide the user with any advanced software features without jeopardizing the synthesizability of the actual hardware description.

For that purpose, each construct in HDLRuby is not a direct description of some hardware construct, but a program that generates the corresponding description. For example, let us consider the following line of code of HDLRuby describing the connection between signal `a` and signal `b`:

```ruby
   a <= b
```

Its execution will produce the actual hardware description of this connection as an object of the HDLRuby::Low library — in this case, an instance of the `HDLRuby::Low::Connection` class. Concretely, an HDLRuby system is described by a Ruby block, and the instantiation of this system is performed by executing this block. The actual synthesizable description of this hardware is the execution result of this instantiation.



From there, we will describe in more detail each construct of HDLRuby.

## Naming rules
<a name="names"></a>

Several constructs in HDLRuby are referred to by name, e.g., systems and signals.  When such constructs are declared, their names are to be specified by Ruby symbols starting with a lowercase. For example, `:hello` is a valid name declaration, but `:Hello` is not.

After being declared, the construct can be referred to by using the name directly (i.e., without the `:` of Ruby symbols). For example, if a construct
has been declared with `:hello` as the name, it will be afterward referred to by `hello`.

## Systems and signals

A system represents a digital system and corresponds to a Verilog HDL module. A system has an interface comprising input, output, and inout signals, and includes structural and behavioral descriptions.

A signal represents a state in a system. It has a data type and a value, the latter varying with time. HDLRuby signals can be viewed as abstractions of both wires and registers in a digital circuit.  As a general rule, a signal whose value is explicitly set all the time models a wire, otherwise it models a register.

### Declaring an empty system

A system is declared using the keyword `system`. It must be given a Ruby symbol for its name and a block that describe its content. For instance, the following code describes an empty system named `box`:

```ruby
system(:box) {}
```

__Notes__:

- Since this is Ruby code, the body can also be delimited by the `do` and `end` Ruby keywords (in which case the parentheses can be omitted) are as follows:

```ruby
system :box does
end
```

- Names in HDLRuby are natively stored as Ruby symbols, but strings can
  also be used, e.g., `system("box") {}` is also valid.

### Declaring a system with an interface

The interface of a system can be described anywhere in its body, but it is recommended to do it at its beginning. This is done by declaring input, output, or inout signals of given data types as follows:

```ruby
<data type>.<direction> <list of colon-preceded names>
```

For example, declaring a 1-bit input signal named `clk` can be declared as follows:

```ruby
bit.input :clk
```

Now, since `bit` is the default data type in HDLRuby, it can be omitted as follows:

```ruby
input :clk
```

The following is a more complete example: it is the code of a system describing an 8-bit data, 16-bit address memory whose interface includes a 1-bit input clock (`clk`), a 1-bit signal for selecting reading or writing access (`rwb`), a 16-bit address input (`addr`), and an 8-bit data inout — the remaining of the code describes the content and the behavior of the memory.

```ruby
system :mem8_16 do
    input :clk, :rwb
    [15..0].input :addr
    [7..0].inout :data

    bit[7..0][2**16].inner :content
    
    par(clk.posedge) do
        hif(rwb) { data <= content[addr] }
        helse    { content[addr] <= data }
    end
end
```

### Structural description in a system

In a system, structural descriptions consist of subsystems and interconnections among them.

A subsystem is obtained by instantiating an existing system as follows, where `<system name>` is the name of the system to instantiate (without any colon):

```ruby
<system name> :<instance name>
```

For example, system `mem8_16` declared in the previous section can be instantiated as follows:

```ruby
mem8_16 :mem8_16I
```

It is also possible to declare multiple instances of the same system at a time as follows:

```ruby
<system name> [list of colon-separated instance names]
```

For example, the following code declares two instances of system `mem8_16`:

```ruby
mem8_16 [ :mem8_16I0, :mem8_16I1 ]
```

Interconnecting instances may require internal signals in the system.
Such signals are declared using the `inner` direction.
For example, the following code declares a 1-bit inner signal named `w1` and a 2-bit inner signal named `w2`:

```ruby
inner :w1
[1..0].inner :w2
```

If the signal is not meant to be changed, it can be declared using the `constant` keyword instead of `inner`.

A connection between signals is done using the arrow operator `<=` as follows:

```ruby
<destination> <= <source>
```

The `<destination>` must be a reference to a signal, and the `<source>` can be any expression.

For example, the following code connects signal `w1` to signal `ready` and signal `clk` to the first bit of signal `w2`:

```ruby
ready <= w1
w2[0] <= clk
```

As another example, the following code connects to the second bit of `w2` the output of an AND operation between `clk` and `rst` as follows:

```ruby
w2[1] <= clk & rst
```

The signals of an instance can be connected through the arrow operator too, provided they are properly referred to. One way to refer to them is to use the dot operator `.` on the instance as follows:

```ruby
<instance name>.<signal name>
```

For example, the following code connects signal `clk` of instance `mem8_16I` to signal `clk` of the current system:

```ruby
mem8_16I.clk <= clk
```

It is also possible to connect multiple signals of an instance using the call operator `.()` as follows, where each target can be any expression:

```ruby
<instance name>.(<signal name0>: <target0>, ...)
```

For example, the following code connects signals `clk` and `rst` of instance `mem8_16I` to signals `clk` and `rst` of the current system. As seen in this example, this method allows partial connection since the address and the data buses are not connected yet.

```ruby
mem8_16I.(clk: clk, rst: rst)
```

This last connection method can be used directly while declaring an instance.
For example, `mem8_16I` could have been declared and connected to `clk` and `rst` as follows:

```ruby
mem8_16(:mem8_16I).(clk: clk, rst: rest)
```

To summarize this section, here is a structural description of a 16-bit memory made of two 8-bit memories (or equivalent) sharing the same address bus, and using respectively the lower and the higher 8-bits of the data bus:

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

### Initialization of signals
<a name="initialization"></a>

Output, inner and constant signals of a system can be initialized when declared using the following syntax in place of the usual name of the signal:

```ruby
<signal name>: <intial value>
```

For example, a single-bit inner signal named `sig` can be initialized to 0 as follows:

```ruby
inner sig: 0
```

As another example, an 8-bit 8-word ROM could be declared and initialized as follows:

```ruby
bit[8][-8] rom: [ 0,1,2,3,4,5,6,7 ]
```


### Scope in a system

#### General scopes

The signals of the interface of signals are accessible from anywhere in an HDLRuby description. This is not the case for inner signals and instances: they are accessible only within the scope they are declared in.

A scope is a region of the code where locally declared objects are accessible. Each system has its scope that cannot be accessible from another part of an HDLRuby description. For example, in the following code signals `d` and `qb` as well as instance `dffI` cannot be accessed from outside system `div2`:

```ruby
system :div2 do
   input :clk
   output :q
   
   inner :d, :qb
   d <= qb
   
   dff_full(:dffI).(clk: clk, d: d, q: q, qb: qb)
   
```

For robustness or, readability purpose, it is possible to add inner scope inside the existing scope using the `sub` keyword as follows:

```ruby
sub do
   <code>
end
```

For example, in the code below signal `sig` is not accessible from outside the additional inner scope of system `sys`

```ruby
system :sys do
   ...
   sub
      inner :sig
      <sig is accessible here>
   end
   <sig is not accessible from here>
end
```

It is also possible to add an inner scope within another inner scope as follows:

```ruby
system :sys do
   ...
   sub
      inner :sig0
      <sig0 is accessible here>
      sub
         inner :sig1
         <sig0 and sig1 are accessible here>
      end
      <sig1 is not accessible here>
   end
   <neither sig0 nor sig1 are accessible here>
end
```

Within the same scope, it is not possible to declare multiple signals or instances with the same name. However, it is possible to declare a signal or an instance with a name identical to one previously declared outside the scope: the inner-most declaration will be used. 


#### Named scopes

It is possible to declare a scope with a name as follows:

```ruby
sub :<name> do
   <code>
end
```

Where:

 * `<name>` is the name of the scope.
 * `<code>` is the code within the scope.

Contrary to the case of scopes without a name, signals, and instances declared within a named scope can be accessed outside using this name as a reference. For example, in the code below signal `sig` declared within scope named `scop` is accessed outside it using `scop.sig`:

```ruby
sub :scop do
   inner :sig
   ...
end
...
scop.sig <= ...
```


### Behavioral description in a system.

In a system, parallel behavioral descriptions are declared using the `par` keyword, and sequential behavioral descriptions are declared using the `seq` keyword.  They are the equivalent of the Verilog HDL `always` blocks.

A behavior is made of a list of events (the sensitivity list) upon which it is activated, and a list of statements. A behavior is declared as follows:

```ruby
par <list of events> do
   <list of statements>
end
```

In addition, it is possible to declare inner signals within an execution block.
While such signals will be physically linked to the system, they are only accessible within the block they are declared into. This permits a tighter scope for signals, which improves the readability of the code and make it possible to declare several signals with identical names provided their respective scopes are different.

An event represents a specific change in the state of a signal. 
For example, a rising edge of a clock signal named `clk` will be represented by the event `clk.posedge`. In HDLRuby, events are obtained directly from
expressions using the following methods: `posedge` for a rising edge, `negedge` for a falling edge, and `edge` for any edge.
Events are described in more detail in section [Events](#events).

When one of the events of the sensitivity list of a behavior occurs, the behavior is executed, i.e., each of its statements is executed in sequence. A statement can represent a data transmission to a signal, a control flow, a nested execution block, or the declaration of an inner signal (as stated
earlier). Statements are described in more detail in section [statements](#statements). In this section, we focus on the transmission statements and the block statements.

A transmission statement is declared using the arrow operator `<=` as follows:

```ruby
<destination> <= <source>
```

The `<destination>` must be a reference to a signal, and the `<source>` can be any expression. A transmission has therefore the same structure as a connection. However, its execution model is different: whereas a connection is continuously executed, a transmission is only executed during the execution of its block.

A block comprises a list of statements. It is used for adding hierarchy to a behavior. Blocks can be either parallel or sequential, i.e., their transmission statements are respectively non-blocking or blocking.
By default, a top block is created when declaring a behavior, and it inherits from its execution mode. For example, with the following code, the top block of the behavior is sequential.

```ruby
system :with_sequential_behavior do
   seq do
      <list of statements>
   end
end
```

It is possible to declare new blocks within an existing block.
For declaring a sub-block with the same execution mode as the upper one, the keyword `sub` is used. For example, the following code declares a sub-block within a sequential block, with the same execution mode:

```ruby
system :with_sequential_behavior do
   seq do
      <list of statements>
      sub do
         <list of statements>
      end
   end
end
```

A sub-block can also have a different execution mode if it is declared using `seq`, which will force sequential execution mode and `par` which will force parallel execution mode. For example, in the following code a parallel sub-block is declared within a sequential one:

```ruby
system :with_sequential_behavior do
   seq do
      <list of statements>
      par do
         <list of statements>
      end
   end
end
```

Sunblocks have their scope so that it is possible to declare signals without colliding with existing ones. For example, it is possible to
declare three different inner signals all called `sig` as follows:

```ruby
...
par(<sensibility list>) do
   inner :sig
   ...
   sub do
      inner :sig
      ...
      sub do
         inner :sig
         ...
      end
   end
   ...
end
```

To summarize this section, here is a behavioral description of a 16-bit shift register with asynchronous reset (`hif` and `helse` are keywords used for specifying hardware _if_ and _else_ control statements).

```ruby
system :shift16 do
   input :clk, :rst, :din
   output :dout

   [15..0].inner :reg

   dout <= reg[15] # The output is the last bit of the register.

   par(clk.posedge) do
      hif(rst) { reg <= 0 }
      helse do
         reg[0] <= din
         reg[15..1] <= reg[14..0]
      end
   end
end
```

In the example above, the order of the transmission statements is of no consequence. This is not the case for the following example, which implements the same register using a sequential block. In this second example, putting the statement `reg[0] <= din` in the last place would have led to an invalid functionality for a shift register.

```ruby
system :shift16 do
   input :clk, :rst, :din
   output :dout

   [15..0].inner :reg

   dout <= reg[15] # The output is the last bit of the register.

   par(clk.posedge) do
      hif(rst) { reg <= 0 }
      helse seq do
         reg[0] <= din
         reg <= reg[14..0]
      end
   end
end
```

__Note__:

  - `helse seq` ensures that the block of the hardware else is in sequential mode.
  - `hif(rst)` could also have been set to sequential mode as follows:
    
    ```ruby
       hif rst, seq do
          reg <= 0
       end
    ```
  - Parallel mode can be set the same way using `par`.

### Extra features for the description of behaviors

#### Single-statement behaviors

It often happens that a behavior contains only one statement.  In such a case, the description can be shortened using the `at` operator as follows:

```ruby
( statement ).at(<list of events>)
```

For example, the following two code samples are equivalent:

```ruby
par(clk.posedge) do
   a <= b+1
end
```

```ruby
( a <= b+1 ).at(clk.posedge)
```

For sake of consistency, this operator can also be applied to block statements as follows, but it is probably less readable than the standard declaration of behaviors:

```ruby
( seq do
     a <= b+1
     c <= d+2
  end ).at(clk.posedge)
```

#### Insertion of statements at the beginning of a block

By default, the statements of a  block are added in order of appearance in the code. However, it is also possible to insert statements at the top of the current block using the unshift command within a block as follows:

```ruby
unshift do
   <list of statements>
end
```

For example, the following code inserts two statements at the beginning of the current block:

```ruby
par do
   x <= y + z
   unshift do
      a <= b - c
      u <= v & w
    end
end
```

The code above will result in the following block:

```ruby
par do
   a <= b - c
   u <= v & w
   x <= y + z
end
```

__Note__: 
 - While of no practical use for simple circuit descriptions, this feature can be used in advanced generic component descriptions.


### Reconfiguration

In HDLRuby, dynamically reconfigurable devices are modeled by instances having more than one system. Adding systems to an instance is done as follows:

```ruby
<instance>.choice(<list of named systems>)
```

For example, assuming systems `sys0`, `sys1`, and `sys2` have been previously declared a device named `dev012` able to be reconfigured to one of these three systems would be declared as follows (the connections of the instance, omitted in the example, can be done as usual):

```ruby
sys0 :dev012 # dev012 is at first a standard instance of sys0
dev012.choice(conf1: sys1, conf2: sys2) # Now dev012 is reconfigurable
```

After the code above, instance `dev012` can be dynamically reconfigured to `sys0`, `sys1`, and `sys2` with respective names `dev012`, `conf1`, and `conf2`.

__Note:__
The name of the initial system in the reconfigurations is set to be the name of the instance.

A reconfigurable instance can then be reconfigured using the command `configure` as follows:

```ruby
<instance>.configure(<name or index>)
```

In the code above, the argument of `configure` can either be the name of the configuration as previously declared with `choice`, or its index in order of declaration. For example in the following code, instance `dev012` is reconfigured to system `sys1`, then system `sys0` the system `sys2`:

```ruby
dev012.configure(:conf1)
!1000.ns
dev012.configure(:dev012)
!1000.ns
dev012.configure(2)
```

These reconfiguration commands are treated as regular RTL statements in HDLRuby and are supported by the simulator. However, in the current version of the HDLRuby, these statements are ignored when generating Verilog HDL or VHDL code.


## Events

Each behavior of a system is associated with a list of events, called a sensitivity list, that specifies when the behavior is to be executed. An event is associated with a signal and represents the instant when the signal reaches a given state.

There are three kinds of events: positive edge events represent the instants when their corresponding signals vary from 0 to 1, and negative edge events
represent the instants when their corresponding signals vary from 1 to 0 and the change events represent the instants when their corresponding signals vary.
Events are declared directly from the signals, using the `posedge` operator for a positive edge, the `negedge` operator for a negative edge, and the `change` operator for change. For example, the following code declares 3 behaviors activated respectively on the positive edge, the negative edge, and any change of the `clk` signal.

```ruby
inner :clk

par(clk.posedge) do
...
end

par(clk.negedge) do
...
end

par(clk.change) do
...
end
```

__Note:__
 - The `change` keyword can be omitted.

## Statements

Statements are the basic elements of a behavioral description. They are regrouped in blocks that specify their execution mode (parallel or sequential).
There are four kinds of statements: the transmit statement which computes expressions and sends the result to the target signals, the control statement
that changes the execution flow of the behavior, the block statement (described earlier), and the inner signal declaration.

__Note__:

 - There is a fifth type of statement, named the time statement, that will be discussed in section [Time](#time).


### Transmit statement

A transmit statement is declared using the arrow operator `<=` within a behavior. Its right value is the expression to compute and its left value is a reference to the target signals (or parts of signals), i.e., the signals (or parts of signals) that receive the computation result.

For example, the following code transmits the value `3` to signal `s0` and the sum of the values of signals `i0` and `i1` to the first four bits of signal `s1`:

```ruby
s0 <= 3
s1[3..0] <= i0 + i1
```

The behavior of a transmit statement depends on the execution mode of the enclosing block:

 * If the mode is parallel, the target signals are updated when all the statements of the current block are processed.
 * If the mode is sequential, the target signals are updated immediately after the right value of the statement is computed.


### Control statements

There are only two possible control statements: the hardware if `hif` and the hardware case `hcase`. 

#### hif

The `hif` construct is made of a condition and a block that is executed if and only if the condition is met. It is declared as follows, where the condition can be any expression:

```ruby
hif <condition> do
   <block contents>
end
```

#### hcase

The `hcase` construct is made of an expression and a list of value-block pairs.
A block is executed when the corresponding value is equal to the value of the expression of the `hcase`. This construct is declared as follows:

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

#### helse

It is possible to add a block that is executed when the condition of an `hif` is not met, or when no case matches the expression of a `hcase`, using the `helse` keyword as follows:

```ruby
<hif or hcase construct>
helse do
   <block contents>
end
```

### helsif

In addition to `helse`, it is possible to set additional conditions to an `hif` using the `helsif` keyword as follows:

```ruby
hif <condition 0> do
   <block contents 0>
end
helsif <condition 1> do
   <block contents 1>
end
...
```

#### About loops

HDLRuby does not include any hardware construct for describing loops. This might look poor compared to the other HDL, but it is important to understand
that the current synthesis tools do not really synthesize hardware from such loops but instead preprocess them (e.g., unroll them) to synthesizable loopless hardware. In HDLRuby, such features are natively supported by the Ruby loop constructs (`for`, `while`, and so on), but also by advanced Ruby constructs like the enumerators (`each`, `times`, and so on).

__Notes__:

 - HDLRuby being based on Ruby, it is highly recommended to avoid `for` or `while` constructs and to use enumerators instead.
 - The Ruby `if` and `case` statements can also be used, but they do not represent any hardware. They are executed when the corresponding system is instantiated. For example, the following code will display `Hello world!` when the described system is instantiated, provided the generic parameter `param` is not nil.

   ```ruby
   system :say_hello do |param = nil|
      if param != nil then
         puts "Hello world!"
      end
   end
   ```

## Types
<a name="types"></a>

Each signal and each expression is associated with a data type that describes the kind of value it can represent.  In HDLRuby, the data types represent
bit-vectors associated with the way they should be interpreted, i.e., as bit strings, unsigned values, signed values, or hierarchical contents.

### Type construction

There are five basic types, `bit`, `signed`, `unsigned`, `integer`, and `float` that represent respectively single bit logical values, single-bit unsigned values, single-bit signed values, Ruby integer values, and Ruby floating-point values (double precision). The first three types are HW and support four-valued logic, whereas the two last ones are SW (but are compatible with HW) and only support Boolean logic. Ruby integers can represent any element of **Z** (the mathematical integers) and have for that purpose a variable bit-width.


The other types are built from them using a combination of the two following
type operators.

__The vector operator__ `[]` is used for building types representing vectors of single or multiple other types. A vector whose elements have all the same type is declared as follows:

```ruby
<type>[<range>]
```

The `<range>` of a vector type indicates the position of the starting and ending bits.
An `n..0` range can also be abbreviated to `n+1`. For instance, the two following types are identical:

```ruby
bit[7..0]
bit[8]
```

A vector of multiple types, also called a tuple, is declared as follows:

```ruby
[<type 0>, <type 1>, ... ]
```

For example, the following code declares the type of the vectors made of an 8-bit logical, a 16-bit signed, and a 16-bit unsigned values:

```ruby
[ bit[8], signed[16], unsigned[16] ]
```

__The structure operator__ `{}` is used for building hierarchical types made of named subtypes. This operator is used as follows:

```ruby
{ <name 0>: <type 0>, <name 1>: <type 1>, ... }
```

For instance, the following code declares a hierarchical type with an 8-bit subtype named `header` and a 24-bit subtype named `data`:

```ruby
{ header: bit[7..0], data: bit[23..0] }
```


### Type definition

It is possible to give names to type constructs using the `typedef` keywords as follows:

```ruby
<type construct>.typedef :<name>
```

For example, the following gives the name `char` to a signed 8-bit vector:

```ruby
signed[7..0].typedef :char
```

After this statement, `char` can be used like any other type.  For example, the following code sample declares a new input signal `sig` whose type is `char`:

```ruby
char.input :sig
```

Alternatively, a new type can also be defined using the following syntax:

```ruby
typedef :<type name> do
   <code>
end
```

Where:

 * `type name` is the name of the type
 * `code` is a description of the content of the type

For example, the previous `char` could have been declared as follows:

```ruby
typedef :char do
   signed[7..0]
end 
```

### Type compatibility and conversion

The basis of all the types in HDLRuby is the vector of bits (bit vector) where each bit can have four values: 0, 1, Z, and X (for undefined).  Bit vectors are by default unsigned but can be set to be signed.  When performing computations between signals of different bit-vector types, the shorter signal is extended to the size of the larger one preserving its sign if it is signed.

While the underlying structure of any HDLRuby type is the bit vector, complex types can be defined. When using such types in computational expressions and assignments they are first implicitly converted to an unsigned bit vector of the same size.

## Expressions
<a name="expressions"></a>

Expressions are any construct that represents a value associated with a type.
They include [immediate values](#immediate-values), [reference to signals](#references) and operations among other expressions using [expression operators](#expression-operators).


### Immediate values

The immediate values of HDLRuby can represent vectors of `bit`, `unsigned`, and `signed`, and integer or floating-point numbers. They are prefixed by a `_` character and include a header that indicates the vector type and the base used for representing the value, followed by a numeral representing the value. The bit width of a value is obtained by default from the width of the numeral, but it is also possible to specify it in the header. In addition, the character `_` can be put anywhere in the number for increasing the readability, it will be ignored.

The vector type specifiers are the followings:
 
 - `b`: `bit` type, can be omitted,
  
 - `u`: `unsigned` type, (equivalent to `b` and can be used for avoiding confusion with the binary specifier),

 - `s`: `signed` type, the last figure is sign-extended if required by the binary, octal, and hexadecimal bases, but not for the decimal base.

The base specifiers are the followings:

 - `b`: binary,

 - `o`: octal,
 
 - `d`: decimal,

 - `h`: hexadecimal.

For example, all the following immediate values represent an 8-bit `hundred` (either in unsigned or signed representation):

```ruby
_bb01100100
_b8b110_0100
_b01100100
_u8d100
_s8d100
_uh64
_s8o144
```

Finally, it is possible to omit either the type specifier, the default being unsigned bit, or the base specifier, the default being binary. For example, all the following immediate values represent an 8-bit unsigned `hundred`:

```ruby
_b01100100
_h64
_o144
```

__Notes__:

 - `_01100100` used to be considered equivalent to `_b01100100`, however, due to compatibility troubles with a recent version of Ruby it is considered deprecated.

 - Ruby immediate values can also be used, their bit width is automatically adjusted to match the data type of the expression they are used in. Please notice this adjustment may change the value of the immediate, for example, the following code will set `sig` to 4 instead of 100:

   ```ruby
   [3..0].inner :sig
   sig <= 100
   ```


### References

References are expressions used to designate signals or a part of signals.

The simplest reference is simply the name of a signal. It designates the signal corresponding to this name in the current scope. For instance, in the
following code, inner signal `sig0` is declared, and therefore the name *sig0* becomes a reference to designate this signal.

```ruby
# Declaration of signal sig0.
inner :sig0

# Access to signal sig0 using a name reference.
sig0 <= 0
```

For designating a signal of another system, or a sub-signal in a hierarchical signal, you can use the `.` operator as follows:

```ruby
<parent name>.<signal name>
```

For example, in the following code, input signal `d` of system instance `dff0` is connected to sub-signal `sub0` of hierarchical signal `sig`.

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :my_system do
   input :clk, :rst
   { sub0: bit, sub1: bit}.inner :sig
   
   dff(:dff0).(clk: clk, rst: rst)
   dff0.d <= sig.sub0
   ...
end
```

### Expression operators

The following table gives a summary of the operators available in HDLRuby.
More details are given for each group of operators in the subsequent sections.

__Assignment operators (left-most operator of a statement):__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                                     |
| :<=           | connection, if outside behavior          |
| :<=           | transmission, if inside behavior         |

__Arithmetic operators:__

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

__Comparison operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :==           | equality                      |
| :!=           | difference                    |
| :>            | greater than                  |
| :<            | smaller than                  |
| :>=           | greater or equal              |
| :<=           | smaller or equal              |

__Logic and shift operators:__

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

__Conversion operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :to\_bit      | cast to bit vector            |
| :to\_unsigned | cast to unsigned vector       |
| :to\_signed   | cast to signed vector         |
| :to\_big      | cast to big endian            |
| :to\_little   | cast to little endian         |
| :reverse      | reverse the bit order         |
| :ljust        | increase width from the left, preserves the sign  |
| :rjust        | increase width from the right, preserves the sign |
| :zext         | zero extension, converts to unsigned if signed    |
| :sext         | sign extension, converts to sign                  |

__Selection /concatenation operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| :[]           | sub vector selection          |
| :@[]          | concatenation operator        |
| :.            | field selection               |


__Notes__:
 
 - The operator precedence is the one of Ruby.

 - Ruby does not allow to override the `&&`, the `||`, and the `?:` operators so they are not present in HDLRuby. Instead of the `?:` operator, HDLRuby provides the more general multiplex operator `mux`. However, HDLRuby does not provide any replacement for the `&&` and the `||` operators, please refer to section [Logic operators](#logic-and-shift-operators) for a justification for this issue.

#### Assignment operators

The assignment operators can be used with any type. They are the connection and the transmission operators both being represented by `<=`.

__Note__:

- The first operator of a statement is necessarily an assignment operator, while the other occurrences of `<=` represent the usual `less than or equal to` operators.

#### Arithmetic operators
<a name="arithmetic"></a>

The arithmetic operators can only be used on vectors of `bit`, `unsigned` or `signed` values, `integer`, or `float` values.  These operators are `+`, `-`, `*`, `%` and the unary arithmetic operators are `-` and `+`. They have the same meaning as their Ruby equivalents.

#### Comparison operators
<a name="comparison"></a>

Comparison operators are the operators whose result is either true or false.
In HDLRuby, true and false are represented by respectively `bit` value 1 and `bit` value 0. These operators are `==`, `!=`, `<`, `>`, `<=`, `>=` . They
have the same meaning as their Ruby equivalents.

__Notes__:

 - The `<`, `>`, `<=` and `>=` operators can only be used on vectors of `bit`, `unsigned` or `signed` values, `integer` or `float` values.
 
 - When compared, values of a type different from the vector of `signed` and from `float` are considered as vectors of `unsigned`.


#### Logic and shift operators

In HDLRuby, the logic operators are all bitwise.  For performing Boolean computations, it is necessary to use single-bit values.  The bitwise logic binary operators are `&`, `|`, and `^`, and the unary one is `~`.  They have the same meaning as their Ruby equivalents.

__Note__: there are two reasons why there are no Boolean operators

 1. Ruby language does not support the redefinition of the Boolean operators

 2. In Ruby, each value that is not `false` nor `nil` is assumed to be true. This is perfectly relevant for software, but not for hardware where the basic data types are bit vectors. Hence, it seemed preferable to support Boolean computation for one-bit values only, which can be done through bitwise operations.

The shift operators are `<<` and `>>` and have the same meaning as their Ruby equivalent. They do not change the bit width and preserve the sign for `signed` values.

The rotation operators are `rl` and `rr` for respectively left and right bit rotations. Like the shifts, they do not change the bit width and preserve the sign for the `signed` values. However, since such operators do not exist in Ruby, they are used like methods as follows:

```ruby
<expression>.rl(<other expression>)
<expression>.rr(<other expression>)
```

For example, for rotating the left signal `sig` 3 times, the following code can be used:

```ruby
sig.rl(3)
```

It is possible to perform other kinds of shifts or rotations using the selection and concatenation operators. Please refer to section [Concatenation and selection operators](#concatenation-and-selection-operators) for more details about these operators. 


#### Conversion operators

The conversion operators are used to change the type of an expression.
There are two kinds of such operators: the type pun that does not change the raw value of the expression and the type cast that changes the raw value.

The type puns include `to_bit`, `to_unsigned`, and `to_signed` that convert expressions of any type to vectors of respectively `bit`, `unsigned`, and `signed` elements.  For example, the following code converts an expression of hierarchical type to an 8-bit signed vector:

```ruby
[ up: signed[3..0], down: unsigned[3..0] ].inner :sig
sig.to_bit <= _b01010011
```

The type casts change both the type and the value and are used to adjust the width of the types.  They can only be applied to vectors of `bit`, `signed`, or `unsinged` and can only increase the bit width (bit width can be truncated using the selection operator, please refer to the next section).
These operators comprise the bit width conversions: `ljust`, `rjust`, `zext` and `sext`.

More precisely, the bit width conversions operate as follows:

 - `ljust` and `rjust` increase the size from respectively the left or the right side of the bit vector. They take as an argument the width of the new type and the value (0 or 1) of the bits to add. For example, the following code increases the size of `sig0` to 12 bits by adding 1 on the right:

   ```ruby
   [7..0].inner :sig0
   [11..0].inner :sig1
   sig0 <= 25
   sig1 <= sig0.ljust(12,1)
   ```

 - `zext` increases the size by adding several 0 bits on the most significant bit side, this side depending on the endianness of the expression.  This conversion takes as an argument the width of the resulting type. For example, the following code increases the size of `sig0` to 12 bits by adding 0 on the left:

   ```ruby
   signed[7..0].inner :sig0
   [11..0].inner :sig1
   sig0 <= -120
   sig1 <= sig0.zext(12)
   ```

 - `sext` increases the size by duplicating the most significant bit, the side of the extension depending on the endianness of the expression. This conversion takes as an argument the width of the resulting type. For example, the following code increases the size of `sig0` to 12 bits by adding 1 on the right:

   ```ruby
   signed[0..7].inner :sig0
   [0..11].inner :sig1
   sig0 <= -120
   sig1 <= sig0.sext(12)
   ```


#### Concatenation and selection operators

Concatenation and selection are done using the `[]` operator as follows:

 - when this operator takes as arguments several expressions, it concatenates them. For example, the following code concatenates `sig0` to `sig1`:

   ```ruby
   [3..0].inner :sig0
   [7..0].inner :sig1
   [11..0].inner :sig2
   sig0 <= 5
   sig1 <= 6
   sig2 <= [sig0, sig1]
   ```

 - when this operator is applied to an expression of `bit`, `unsigned`, or `signed` vector type while taking as argument a range, it selects the bits corresponding to this range.  If only one bit is to be selected, the offset of this bit can be used instead.  For example, the following code selects bits from 3 to 1 of `sig0` and bit 4 of `sig1`:

   ```ruby
   [7..0].inner :sig0
   [7..0].inner :sig1
   [3..0].inner :sig2
   bit.inner    :sig3
   sig0 <= 5
   sig1 <= 6
   sig2 <= sig0[3..1]
   sig3 <= sig1[4]
   ```

#### Implicit conversions
<a name="implicit"></a>

When there is no ambiguity, HDLRuby will automatically insert conversion operators when two types are not compatible with one another.  The cases where such implicit conversions are applied are summarized in the following tables where:

 - `operator` is the operator in use
 - `result width` is the width of the result's type
 - `result base` is the base type of the result's type
 - `S` is the shortest operand
 - `L` is the longest operand
 - `S operand type` is the base type of the shortest operand
 - `L operand type` is the base type of the longest operand
 - `operand conversion` is the conversions added to make the operands
   compatible.
 - `w` is the width of the operands after conversion
 - `lw` is the width of the left operand's type before conversion
 - `rw` is the width of the right operand's type before conversion
 


__Additive and logical operators:__

| operator    | result's width |
| :---        | :---           |
| <= (assign) | w  (error is raised if L.width < R.width) |
| +, -        | w+1            |
| &, \|, ^    | w              |
| ==          | 1              |
| <           | 1              |
| >           | 1              |
| <= (comp.)  | 1              |
| >=          | 1              |

| S operand base | L operand base | result base | operand conversion          |
| :---           | :---           | :---        | :---                        |
| bit            | bit            | bit         | S.zext(L.width)             |
| bit            | unsigned       | unsigned    | S.zext(L.width).to_unsigned |
| bit            | signed         | signed      | S.zext(max(S.width+1,L.width).to_signed |
| unsigned       | bit            | unsigned    | S.zext(L.width), L.to_unsigned |
| unsigned       | unsigned       | unsigned    | S.zext(L.width)             |
| unsigned       | signed         | signed      | S.zext(max(S.width+1,L.width).to_signed |
| signed         | bit            | signed      | S.sext(L.width+1), L.zext(L.width+1).to_signed |
| signed         | unsigned       | signed      | S.sext(L.width+1), L.zext(L.width+1).to_signed |
| signed         | signed         | signed      | S.sext(L.width)             |


__Multiplicative operators:__

| operator    | result width      |
| :---        | :---              |
| *           | lw * rw           |
| /           | lw                |
| %           | rw                |
| **          | rw                |
| << / ls     | lw                |
| >> / rs     | lw                |
| lr          | lw                |
| rr          | lw                |

| S operand base | L operand base | result base | operand conversion          |
| :---           | :---           | :---        | :---                        |
| bit            | bit            | bit         |                             |
| bit            | unsigned       | unsigned    | S.to_unsigned               |
| bit            | signed         | signed      | S.zext(S.width+1).to_signed |
| unsigned       | bit            | unsigned    | L.to_unsigned               |
| unsigned       | unsigned       | unsigned    |                             |
| unsigned       | signed         | signed      | S.zext(S.width).to_signed   |
| signed         | bit            | signed      | L.zext(L.width+1).to_signed |
| signed         | unsigned       | signed      | L.zext(L.width+1).to_signed |
| signed         | signed         | signed      |                             |


## Functions

### HDLRuby functions

Like Verilog HDL, HDLRuby provides function constructs for reusing code. HDLRuby functions are declared as follows:

   ```ruby
      hdef :<function name> do |<arguments>|
      <code>
      end
   ```

Where:

 * `function name` is the name of the function.
 * `arguments` is the list of arguments of the function.
 * `code` is the code of the function.

__Notes__:

- Functions have their scope, so any declaration within a function is local. It is also forbidden to declare interface signals (input, output, or inout) within a function.

- Like the Ruby proc objects, the last statement of a function's code serves as the return value. For instance, the following function returns `1` (in this example the function does not have any argument):

   ```ruby
   function :one { 1 }
   ```
   
- Functions can accept any kind of object as an argument, including variadic arguments or blocks of code as shown below with a function that applies the code passed as an argument to all the variadic arguments of `args`:

   ```ruby
   function :apply do |*args, &code|
      args.each { |arg| code.call(args) }
   end
   ```
   
   Such a function can be used for example for connecting a signal to a set of other signals as follows (where `sig` is connected to `x`, `y` and `z`):
   ```ruby
    apply(x,y,z) { |v| v <= sig }
   ```

A function can be invoked anywhere in the code using its name and passing its argument between parentheses as follows:

```ruby
<function name>(<list of values>)
```



### Ruby functions

HDLRuby functions are useful for reusing code, but they cannot interact with the code they are called in. For example, it is not possible to add interface signals through a function nor to modify a control statement (e.g., `hif`) with them. These high-level generic operations can however be performed using the functions of the Ruby language declared as follows:

```ruby
def <function name>(<arguments>)
   <code>
end
```
Where:

 * `function name` is the name of the function.
 * `arguments` is the list of arguments of the function.
 * `code` is the code of the function.
 
These functions are called the same way HDLRuby functions are called, but this operation pastes the code of the function as is within the code.
Moreover, these functions do not have any scope so any inner signal or instance declared within them will be added to the object they are invoked in.

For example, the following function will add input `in0` to any system where it is invoked:

```ruby
def add_in0
   input :in0
end
```

This function can be used as follows:

```ruby
system :sys do
   ...
   add_in0
   ...
end
```

As another example, the following function will add an alternative code that generates a reset to a condition statement (`hif` or `hcase`):

```ruby
def too_bad
   helse { $rst <= 1 }
end
```

This function can be used as follows:

```ruby
system :sys do
   ...
   par do
      hif(sig == 1) do
         ...
      end
      too_bad
   end
end
```

Ruby functions can be compared to the macros of the C languages: they are more flexible since they edit the code they are invoked in, but they are also dangerous to use. In general, it is not recommended to use them, unless when designing a library of generic code for HDLRuby.


## Time

### Time values
<a name="time_val"></a>

In HDLRuby, time values can be created using the time operators: `s` for seconds, `ms` for a millisecond, `us` for microseconds, `ns` for nanoseconds, `ps` for picoseconds. For example, the following are all indicating one second:

```ruby
1.s
1000.ms
1000000.us
1000000000.ns
1000000000000.ps
```


### Time behaviors and time statements
<a name="time_beh"></a>

Like the other HDL, HDLRuby provides specific statements that model the advance of time. These statements are not synthesizable and are used for simulating the environment of a hardware component.  For the sake of clarity, such statements are only allowed in explicitly non-synthesizable behavior declared using the `timed` keyword as follows.

```ruby
timed do
   <statements>
end
```

A time behavior does not have any sensitivity list, but it can include any statement supported by a standard behavior in addition to the time statements.
There are two kinds of such statements:

 - The `wait` statements: such a statement blocks the execution of the behavior for the time given in the argument. For example, the following code waits for 10ns before proceeding:

   ```ruby
      wait(10.ns)
   ```

   This statement can also be abbreviated using the `!` operator as follows:
   
   ```ruby
      !10.ns
   ```

 - The `repeat` statements: such a statement takes as argument a number of iteration and a block. The execution of the block is repeated the given number times.  For example, the following code executes 10 times the inversion of the `clk` signal every 10 nanoseconds:

   ```ruby
      repeat(10) do 
         !10.ns
         clk <= ~clk
      end
   ```

__Note:__

   This statement is not synthesizable and therefore can only be used in timed behaviors.

### Parallel and sequential execution

Time behaviors are by default sequential, but they can include both parallel and
sequential blocks. The execution semantic is the following:

 - A sequential block in a time behavior is executed sequentially.

 - A parallel block in a time behavior is executed in a semi-parallel fashion as follows:

   1. Statements are grouped in sequence until a time statement is met.

   2. The grouped sequence are executed in parallel.

   3. The time statement is executed.

   4. The subsequent statements are processed the same way.



## High-level programming features

### Using Ruby in HDLRuby

Since HDLRuby is pure Ruby code, the constructs of Ruby can be freely used without any compatibility issues. Moreover, this Ruby code will not interfere with the synthesizability of the design. It is then possible to define Ruby classes, methods, or modules whose execution generates constructs of
HDLRuby.


### Generic programming

#### Declaring

##### Declaring generic systems

Systems can be declared with generic parameters as follows:

```ruby
system :<system name> do |<list of generic parameters>|
   ...
end
```

For example, the following code describes an empty system with two generic parameters named respectively `a` and `b`:

```ruby
system(:nothing) { |a,b| }
```

The generic parameters can be anything: values, data types, signals, systems, Ruby variables, and so on.  For example, the following system uses generic argument `t` as a type for an input signal, generic argument `w` as a bit range for an output signal, and generic argument `s` as a system used for creating instance `sI` whose input and output signals `i` and `o` are connected respectively to signals `isig` and `osig`.

```ruby
system :something do |t,w,s|
   t.input isig
   [w].output osig

   s :sI.(i: isig, o: osig)
end
```

It is also possible to use a variable number of generic parameters using the variadic operator `*` like in the following example. In this example, `args` is an array containing an indefinite number of parameters.

```ruby
system(:variadic) { |*args| }
```

##### Declaring generic types

Data types can be declared with generic parameters as follows:

```ruby
typedef :<type name> do |<list of generic parameters>|
   ...
end
```

For example, the following code describes a bit-vector type with a generic number of bits `width`:

```ruby
type(:bitvec) { |width| bit[width] }
```

Like with the systems, the generic parameters of types can be any kind of object, and it is also possible to use variadic arguments.



#### Specializing

##### Specializing generic systems

A generic system is specialized by invoking its name and passing as an argument the values corresponding to the generic arguments as follows:

```ruby
<system name>(<generic argument value's list>)
```

If fewer values are provided than the number of generic arguments, the system is partially specialized. However, only a fully specialized system can be instantiated.

A specialized system can also be used for inheritance. For example, assuming system `sys` has 2 generic arguments, it can be specialized and used for building system `subsys` as follows:

```ruby
system :subsys, sys(1,2) do
   ...
end
```

This way of inheriting can only be done with fully specialized systems though. For partially specialized systems, `include` must be used instead. For example, if `sys` is specialized with only one value, can be used in generic `subsys_gen` as follows:

```ruby
system :subsys_gen do |param|
   include sys(1,param)
   ...
end
```

__Note:__

- In the example above, the generic parameter `param` of `subsys_gen` is used for specializing system `sys`.


##### Specializing generic types

A generic type is specialized by invoking its name and passing as an argument the values corresponding to the generic arguments as follows:

```ruby
<type name>(<generic argument value's list>)
```

If fewer values are provided than the number of generic arguments, the type is partially specialized. However, only a fully specialized type can be used for declaring signals.


##### Use of signals as generic parameters

Signals passed as generic arguments to systems can be used for making generic connections to the instance of the system. For that purpose, the generic argument has to be declared as input, output, or inout port in the body of the system as follows:

```ruby
system :<system_name> do |sig|
   sig.input :my_sig
   ...
end
```

In the code above, `sig` is a generic argument assumed to be a signal. The second line declares the port to which sig will be connected to when instantiating. From there, port `my_sig` can be used like any other port of the system. Such a system is then instantiated as follows:

```ruby
system_name(some_sig) :<instance_name>
```

In the code above, `some_sig` is a signal available in the current context. This instantiation automatically connects `some_sig` to the instance.



### Inheritance
<a name="inherit"></a>

#### Basics

In HDLRuby, a system can inherit from the content of one or several other parent systems using the `include` command as follows: `include <list of
systems>`.  Such an include can be put anywhere in the body of a system, but the resulting content will be accessible only after this command.

For example, the following code describes first a simple D-FF, and then uses it to describe a FF with an additional reversed output (`qb`):

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   par(clk.posedge) { q <= d & ~rst }
end

system :dff_full do
    output :qb

    include dff

    qb <= ~q
end
```

It is also possible to declare inheritance in a more object-oriented fashion by listing the parents of a system just after declaring its name as follows:

```ruby
system :<new system name>, <list of parent systems> do
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

 * As a matter of implementation, HDLRuby systems can be viewed as sets of methods used for accessing various constructs (signals, instances).  Hence inheritance in HDLRuby is closer to the Ruby mixin mechanism than to a true software inheritance.


#### About inner signals and system instances

By default, inner signals and instances of a parent system are not accessible by its child systems.  They can be made accessible using the `export` keyword as follows: `export <symbol 0>, <symbol 1>, ...` . For example, the following
code exports signals `clk` and `rst` and instance `dff0` of system `exporter` so that they can be accessed in child system `importer`.

```ruby
system :exporter do
   input :d
   inner :clk, :rst

   dff(:dff0).(clk: clk, rst: rst, d: d)

   export :clk, :rst, :dff0 
end

system :importer, exporter do
   input :clk0, :rst0
   output :q

   clk <= clk0
   rst <= rst0
   dff0.q <= q
end
```

__Note__:
 - export takes as arguments the symbols (or the strings) representing the name of the components to export *and not* a reference to them. For instance, the following code is invalid:

   ```ruby
   system :exporter do
      input :d
      inner :clk, :rst

      dff(:dff0).(clk: clk, rst: rst, d: d)

      export clk, rst, dff0 
   end
   ```

#### Conflicts when inheriting

Signals and instances cannot be overridden, this is also the case for signals and instances accessible through inheritance. For example, the following code is invalid since `rst` has already been defined in `dff`:

```ruby
   system :dff_bad, dff do
      input :rst
   end
```

Conflicts among several inherited systems can be avoided by renaming the signals and instances that collide with one another as shown in the next
section.


#### Shadowed signals and instances

It is possible in HDLRuby to declare a signal or an instance whose name is identical to the one used in one of the included systems. In such a case, the corresponding construct of the included system is still present, but it is not directly accessible even if exported, they are said to be shadowed.

To access the shadowed signals or instances, a system must be reinterpreted as the relevant parent system using the `as` operator as follows: `as(system)`.

For example, in the following code signal, `db` of system `dff_db` is shadowed by signal `db` of system `dff_shadow`, but it is accessed using the `as` operator.

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



### Opening a system
<a name="system_open"></a>

It is possible to pursue the definition of a system after it has been declared using the `open` methods as follows:

```ruby
<system>.open do
   <additional system description>
end
```

For example, `dff`, a system describing a D-FF, can be modified to have an inverted output as follows:

```ruby
dff.open do
   output :qb

   qb <= ~q
end
```


### Opening an instance
<a name="instance_open"></a>

When there is a modification to apply to an instance, it is sometimes preferable to modify this sole instance rather than declaring a new system to derivate the instance from. For that purpose, it is possible to open an instance for modification as follows:

```ruby
<instance name>.open do
   <additional description for the instance>
end
```

For example, an instance of the previous `dff` system can be extended with an inverted output as follows:
```ruby
system :some_system do
   ...
   dff :dff0
   dff0.open do
      output :qb
      qb <= ~q
   end
   ...
end
```



### Overloading of operators

Operators can be overloaded for specific types. This allows for instance to support seamlessly fixed-point computations without requiring explicit readjustment of the position of the decimal point.

An operator is redefined as follows:

```ruby
<type>.define_operator(:<op>) do |<args>|
   <operation description>
end
```

Where:

 * `type` is the type from which the operation is overloaded.
 * `op` is the operator that is overloaded (e.g., `+`)
 * `args` are the arguments of the operation.
 * `operation description` is an HDLRuby expression of the new operation.

For example, for `fix32` a 32-bit (decimal point at 16-bit) fixed-point type defined as follows:

```ruby
signed[31..0].typedef(:fix32)
```

The multiplication operator can be overloaded as follows to ensure the decimal point have always the right position:

```ruby
fix32.define_operator(:*) do |left,right|
   (left.as(signed[31..0]) * right) >> 16
end
```

Please notice, that in the code above, the left value has been cast to a plain bit-vector to avoid the infinite recursive call of the `*` operator.

Operators can also be overloaded with generic types. However, in such a case, the generic argument must also be present in the list of arguments of the overloaded operators.
For instance, let us consider the following fixed-point type of variable width (and whose decimal point is set at half of its bit range):

```ruby
typedef(:fixed) do |width|
   signed[(width-1)..0]
end
```

The multiplication operator would be overloaded as follows:

```ruby
fixed.define_operator do |width,left,right|
   (left.as(signed[(width-1)..0]) * right) >> width/2
end
```

### Predicate and access methods

To get information about the current state of the hardware description HDLRuby provides the following predicates:

| predicate name | predicate type | predicate meaning                          |
| :---           | :---           | :---                                       |
| `is_block?`    | bit            | tells if in execution block                |
| `is_par?`      | bit            | tells if current parallel block is parallel|
| `is_seq?`      | bit            | tells if current parallel block is sequential|
| `is_clocked?`  | bit            | tells if current behavior is clocked (activated on a sole rising or falling edge of a signal) |
| `cur_block`    | block          | gets the current block                     |
| `cur_behavior` | behavior       | gets the current behavior              |
| `cur_systemT`  | system         | gets the current system                |
| `top_block  `  | block          | gets the top block of the current behavior |
| `one_up`       | block/system   | gets the upper construct (block or system) |
| `last_one`     | any            | last declared construct                    |

Several enumerators are also provided for accessing the internals of the current construct (in the current state):

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

### Global signals

HDLRuby allows the declaration of global signals the same way system's signals are declared but outside the scope of any system.  After being declared, these signals are accessible directly from within any hardware construct.

To ease the design of standardized libraries, the following global signals are defined by default:

| signal name | signal type | signal function                       |
| :---        | :---        | :---                                  |
| `$reset`    | bit         | global reset                          |
| `$resetb`   | bit         | global reset complement               |
| `$clk`      | bit         | global clock                          |

__Note__:
 
 - When not used, the global signals are discarded.



### Defining and executing Ruby methods within HDLRuby constructs
<a name="method"></a>

Like with any Ruby program, it is possible to define and execute methods anywhere in HDLRuby using the standard Ruby syntax. When defined, a method is attached to the enclosing HDLRuby construct. For instance, when defining a method when declaring a system, it can be used within this system only, while when defining a method outside any construct, it can be used everywhere in the HDLRuby description.

A method can include HDLRuby code in which case the resulting hardware is appended to the current construct. For example, the following code adds a connection between `sig0` and `sig1` in the system `sys0`, and transmission between `sig0` and `sig1` in the behavior of `sys1`.

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

   par(clk.posedge) do
      some_arrow
   end
end
```

__Warning__:

- In the above example, the semantic of `some_arrow` changes depending on where it is invoked from, e.g., within a system, it is a connection, within a behavior, it is a transmission.

- Using Ruby methods for describing hardware might lead to weak code, for example, in the following code, the method declares `in0` as an input signal.  Hence, while used in `sys0` no problem happens, an exception will be raised for `sys1` because a signal `in0` is already declared and will also be raised for `sys2` because it is not possible to declare an input from within a behavior.

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
     par do
        in_decl
     end
  end
  ```

Like any other Ruby method, methods defined in HDLRuby support variadic arguments named arguments, and block arguments.  For example, the following method can be used to connect a driver to multiple signals:

```ruby
def mconnect(driver, *signals)
   signals.each do |signal|
      signal <= driver
   end
end

system :sys0 do
   input :i0
   input :o0, :o1, :o2, :o3

   mconnect(i0,o0,o1,o2,o3)
end
```


While requiring caution, a properly designed method can be very useful for clean code reuse. For example, the following method allows to start the execution of a block after a given number of cycles:

```ruby
def after(cycles,rst = $rst, &code)
   sub do
      inner :count
      hif rst == 1 do
         count <= 0
      end
      helse do
         hif count < cycles do
            count <= count + 1
         end
         helse do
            instance_eval(&code)
         end
      end
   end
end
```

In the code above: 
 
 - the default initialization of `rst` to `$rst` allows resetting the counter even if no such signal is provided as an argument.

 - `sub` ensures that the `count` signal does not conflict with another signal with the same name.

 - the `instance_eval` keyword is a standard Ruby method that executes the block passed as an argument in context.

The following is an example that switches a LED on after 1000000 clock cycles using the previously defined `after` ruby method:

```ruby
system :led_after do
   output :led
   input :clk

   par(clk.posedge) do
      (led <= 0).hif($rst)
      after(100000) { led <= 1 }
   end
end
```

__Note__:

 - Ruby's closure still applies in HDLRuby, hence, the block sent to `after` can use the signals and instances of the current block. Moreover, the signal declared in this method will not collide with them.


### Dynamic description

When describing a system, it is possible to disconnect or completely undefine a signal or an instance.


## Extending HDLRuby

Like any Ruby class, the constructs of HDLRuby can be dynamically extended. If it is not recommended to change their internal structure, it is possible to add methods to them for an extension.

### Extending HDLRuby constructs globally

By global extension of hardware constructs, we mean the classical extension of Ruby classes by monkey patching the corresponding class. For example, it is possible to add a method giving the number of signals in the interface of a system instance as follows:

```ruby
class SystemI
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

From there, the method `interface_size` can be used on any system instance as follows: `<system instance>.interface_size`.

The following table gives the class of each construct of HDLRuby.

| construct       | class        |
| :---            | :---         |
| data type       | Type         |
| system          | SystemT      |
| scope           | Scope        |
| system instance | SystemI      |
| signal          | Signal       |
| connection      | Connection   |
| par/seq         | Behavior     |
| timed           | TimeBehavior |
| event           | Event        |
| par/seq/sub     | Block        |
| transmit        | Transmit     |
| hif             | If           |
| hcase           | Case         |


### Extending HDLRuby constructs locally

By local extension of a hardware construct, we mean that while the construct will be changed, all the other constructs will remain unchanged. This is achieved like in Ruby by accessing the Eigen class using the `singleton_class` method and extending it using the `class_eval` method.  For example, with the following code, only system `dff` will respond to method `interface_size`:

```ruby
dff.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

It is also possible to extend locally an instance using the same methods.
For example, with the following code, only instance `dff0` will respond to method `interface_size`:

```ruby
dff :dff0

dff0.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

Finally, it is possible to extend locally all the instances of a system using method `singleton_instance` in place of method `singleton_class`.
For example, with the following code, all the instances of system `dff` will respond to method `interface_size`:

```ruby
dff.singleton_instance.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

### Modifying the generation behavior

The main purpose of allowing global and local extensions for hardware constructs is to give the user the possibility to implement its synthesis methods. For example, one may want to implement some algorithm for a given kind of system. For that purpose, the user can define an abstract system (without any hardware content), that holds the specific algorithm as follows:

```ruby
system(:my_base) {}

my_base.singleton_instance.class_eval do
   def my_generation
      <some code>
   end
end
```

Then, when this system named `my_base` is included in another system, this latter will inherit from the algorithms implemented inside method `my_generation` as shown in the following code:

```ruby
system :some_system, my_base do
   <some system description>
end
```

However, when generation the low-level description of this system, code like the following will have to be written for applying `my_generation`:

```ruby
some_system :instance0
instance0.my_generation
low = instance0.to_low
```

This can be avoided by redefining the `to_low` method as follows:

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






# Standard libraries

The standard libraries are included in the module `Std`.
They can be loaded as follows, where `<library name>` is the name of the
library:

```ruby
require 'std/<library name>' 
```

After the libraries are loaded, the module `Std` must be included as follows:

```ruby
include HDLRuby::High::Std
```

> However, `hdrcc` loads the stable components of the standard library by default, so you do not need to require nor include anything more to use them. In the current version, the stable components are the followings:  
  
  - `std/clocks.rb`  

  - `std/fixpoint.rb`  

  - `std/decoder.rb`  

  - `std/fsm.rb`  

  - `std/sequencer.rb`  

  - `std/sequencer_sync.rb`



## Clocks: `std/clocks.rb`
<a name="clocks"></a>

The `clocks` library provides utilities for easier handling of clock synchronizations.

It adds the possibility to multiply events by an integer. The result is a new event whose frequency is divided by the integer multiplicand. For example, the following code describes a D-FF that memorizes each three clock cycles.

```ruby
require 'std/clocks'
include HDLRuby::High::Std

system :dff_slow do
   input :clk, :rst
   input :d
   output :q

   ( q <= d & ~rst ).at(clk.posedge * 3)
end
```

__Note__: this library generates all the RTL code for the circuit handling the frequency division. 

## Counters: `std/counters.rb`
<a name="counters"></a>

This library provides two new constructs for implementing synthesizable wait statements.

The first construct is the `after` statement that activates a block after a given number of clock cycles is passed. Its syntax is the following:

```ruby
after(<number>,<clock>,<reset>)
```

Where:

 * `<number>` is the number of cycles to wait.
 * `<clock>` is the clock to use, this argument can be omitted.
 * `<reset>` is the signal used to reset the counter used for waiting, this argument can be omitted.

This statement can be used either inside or outside a clocked behavior. When used within a clocked behavior, the clock event of the behavior is used for the counter unless specified otherwise. When used outside such behavior, the clock is the global default clock `$clk`. In both cases, the reset is the global reset `$rst` unless specified otherwise.

The second construct is the `before` statement that activates a block until a given number of clock cycles is passed. Its syntax and usage are identical to the `after` statement.


## Decoder: `std/decoder.rb`
<a name="decoder"></a>

This library provides a new set of control statements for easily describing an instruction decoder.

A decoder can be declared anywhere in the code describing a system using the `decoder` keyword as follows:

```ruby
decoder(<signal>) <block>
```

Where `signal` is the signal to decode and `block` is a procedure block (i.e., Ruby `proc`) describing the decoding procedure. This procedure block can contain any code supported by a standard behavior but also supports the `entry` statement that describes a pattern of a bit vector to decode and the corresponding action to perform when the signal matches this pattern. The syntax of the `entry` statement is the following:

```ruby
entry(<pattern>) <block>
```

Where `pattern` is a string describing the pattern to match the entry, and `block` is a procedure block describing the actions (some HDLRuby code) that are performed when the entry matches. The string describing the pattern can include `0` and `1` characters for specifying a specific value for the corresponding bit, or any alphabetical character for specifying a field in the pattern. The fields in the pattern can then be used by name in the block describing the action. When a letter is used several times within a pattern, the corresponding bits are concatenated and used as a multi-bit signal in the block.

For example, the following code describes a decoder for signal `ir` with two entries, the first one computing the sum of fields `x` and `y` and assigning the result to signal `s` and the second one computing the sum of fields `x` `y` and `z` and assigning the result to signal `s`:

```ruby
decoder(ir) do
   entry("000xx0yy") { s <= x + y }
   entry("10zxxzyy") { s <= x + y + z }
end
```

It can be noticed for field `z` in the example above that the bits are not required to be contiguous.

## FSM: `std/fsm.rb`
<a name="fsm"></a>

This library provides a new set of control statements for easily describing a finite state machine (FSM).

A finite state machine can be declared anywhere in a system provided it is outside a behavior using the `fsm` keyword as follows:

```ruby
fsm(<event>,<reset>,<mode>) <block>
```

Where `event` is the event (rising or falling edge of a signal) activating the state transitions, `rst` is the reset signal, and `mode` is the default execution mode and `block` is the execution block describing the states of the FSM. This last parameter can be either `:sync` for synchronous (Moore type) or `:async` for asynchronous (Mealy type).

The states of an FSM are described as follows:

```ruby
<kind>(<name>) <block>
```

Where `kind` is the kind of state, `name` is the name of the state, and `block` is the actions to execute for the corresponding state. The kinds of states are the followings:

 * reset: the state reached when resetting the FSM. This state can be forced to be asynchronous by setting the `name` argument to `:async` and forced to be synchronous by setting the `name` argument to `:sync`. By default, the `name` argument is to be omitted.
 * state: the default kind of state, it will be synchronous if the FSM is synchronous or asynchronous otherwise.
 * sync:  the synchronous kind of state, it will be synchronous whatever the kind of FSM is used.
 * async: the asynchronous kind of state, it will be asynchronous whatever the kind of FSM is used.

In addition, it is possible to define a default action that will be executed whatever the state is using the following statement:

```ruby
default <block>
```

Where `block` is the action to execute.

State transitions are by default set to be from one state to the following in the description order. If no more transition is declared the next one is the first declared transition. A specific transition is defined using the `goto` statement as the last statement of the action block as follows:

```ruby
goto(<condition>,<names>)
```

Where `condition` is a signal whose value is used as an index for selecting the target state among the ones specified in the `names` list. For example, the following statement indicates to go to the state named `st_a` if the `cond` is 0, `st_b` if the condition is 1, and `st_c` if the condition is 2, otherwise this specific transition is ignored:

```ruby
goto(cond,:st_a,:st_b,:st_c)
```

Several goto statements can be used, the last one having priority provided it is taken (i.e., its condition corresponds to one of the target states). If no goto is taken, the next transition is the next declared one.

For example, the following code describes an FSM describing a circuit that checks if two buttons (`but_a` and `but_b`) are pressed and released in sequence for activating an output signal (`ok`):

```ruby
fsm(clk.posedge,rst,:sync) do
   default { ok <= 0 }
   reset do
      goto(but_a, :reset, but_a_on)
   end
   state(:but_a_on) do
      goto(but_a, :but_a_off, :but_a_on)
   end
   state(:but_a_off) do
      goto(but_b, :but_a_off, :but_b_on)
   end
   state(:but_b_on) do
      goto(but_b, :but_b_off, :but_b_on)
   end
   state(:but_b_off) do
      ok <= 1
      goto(:but_b_off)
   end
end
```

__Note__: the goto statements act globally, i.e., they are independent of the place where they are declared within the state. For example for both following statements, the next state will always be `st_a` whatever `cond` maybe:

```ruby
   state(:st_0) do
      goto(:st_a)
   end
   state(:st_1) do
      hif(cond) { goto(:st_a) }
   end
```

That is to say, for a conditional `goto` for `st_1` the code should have been written as follows:

```ruby
   state(:st_1) do
      goto(cond,:st_a)
   end
```

The use of `goto` makes the design of FSM shorter for a majority of the cases, be sometimes, a finer control is required. For that purpose, it is also possible to configure the FSM in `static` mode where the `next_state` statement indicates implicitly the next state. Putting in static mode is done by passing `:static` as an argument when declaring the FSM. For example, the following FSM uses `next_state` to specify explicitly the next states depending on some condition signals `cond0` and `cond1`:

```ruby
fsm(clk.posedge,rst,:static)
   state(:st_0) do
      next_state(:st_1)
   state(:st_1) do
      hif(cond) { next_state(:st_1) }
      helse { next_state(:st_0) }
   end
end
```

## Sequencer (software-like hardware coding):: `std/sequencer.rb`
<a name="sequencer"></a>

This library provides a new set of control statements for describing the behavior of a circuit. Behind the curtain, these constructs build a finite state machine where states are deduced from the control points within the description.

A sequencer can be declared anywhere in a system provided it is outside a behavior using the `sequencer` keyword as follows:

```ruby
sequencer(<clock>,<start>) <block>
```

Where `clock` is the clock signal advancing the execution of the sequence, `start` is the signal starting the execution, and `block` is the description of the sequence to be executed. Both `clock` and `start` can also be events (i.e., `posedge` or `negedge`).

A sequence is a specific case of a `seq` block that includes the following software-like additional constructs:

 - `step`: wait until the next event (given argument `event` of the sequencer).

 - `steps(<num>)`: perform `num` times `step` (`num` can be any expression).

 - `sif(<condition>) <block>`: executes `block` if `condition` is met.

 - `selsif(<condition>) <block>`: executes `block` if the previous `sif` or `selsif` condition is not met and if the current `condition` is met.

 - `selse <block>`: executes `block` if the condition of the previous `sif` statement is not met.

 - `swait(<condition>)`: waits until that `condition` is met.

 - `swhile(<condition>) <block>`: executes `block` while `condition` is met.

 - `sfor(<enumerable>) <block>`: executes `block` on each element of `enumerable`. This latter can be any enumerable Ruby object or any signal. If the signal is not hierarchical (e.g., bit vector), the iteration will be over each bit.

 - `sbreak`: ends current iteration.

 - `scontinue`: goes to the next step of the iteration.

 - `sterminate`: ends the execution of the sequence.

It is also possible to use enumerators (iterators) similar to the Ruby `each` using the following methods within sequences:

 - `<object>.seach`: `object` any enumerable Ruby object or any signal. If a block is given, it works like `sfor`, otherwise, it returns a HDLRuby enumerator (please see [enumerator](#hdlruby-enumerators-and-enumerable-objects-stdsequencerrb) for details about them).

 - `<object>.stimes`: can be used on integers and is equivalent to `seach` on each integer from 0 up to `object-1`.

 - `<object>.supto(<last>)`: can be used on integers and is equivalent to `seach` on each integer from `object` up to `last`.

 - `<object>.sdownto(<last>)`: can be used on an integer and is equivalent to `seach` on each integer from `object` down to `last`.

The objects that support these methods are called _enumerable_ objects. They include the HDLRuby signals, the HDLRuby enumerators, and all the Ruby enumerable objects (e.g., ranges, arrays).


Here are a few examples of sequencers synchronized in the positive edge of `clk` and starting when `start` becomes one. The first one computes the Fibonacci series until 100, producing a new term in signal `v` at each cycle:

```ruby
require 'std/sequencer.rb'
include HDLRuby::High::Std

system :a_circuit do
   inner :clk, :start
   [16].inner :a, :b
   
   sequencer(clk.posedge,start) do
      a <= 0
      b <= 1
      swhile(v < 100) do
         b <= a + b
         a <= b - a
      end
   end
end
```

The second one computes the square of the integers from 10 to 100, producing one result per cycle in signal `a`:

```ruby
inner :clk, :start
[16].inner :a

sequencer(clk.posedge,start) do
   10.supto(100) { |i| a <= i*i }
end
```

The third one reverses the content of memory `mem` (the result will be "!dlrow olleH"):

```ruby
inner :clk, :start
bit[8][-12].inner mem: "Hello world!"

sequencer(clk.posedge,start) do
   mem.size.stimes do |i|
      [8].inner :tmp
      tmp       <= mem[i]
      mem[i]    <= mem[-i-1]
      mem[-i-1] <= tmp
   end
end
```

The fourth one computes the sum of all the elements of memory `mem` but stops if the sum is larger than 16:

```ruby
inner :clk, :start
bit[8][-8].inner mem: [ _h02, _h04, _h06, _h08, _h0A, _h0C, _h0E ]
bit[8] :sum

sequencer(clk.posedge,start) do
   sum <= 0
   sfor(mem) do |elem|
      sum <= sum + elem
      sif(sum > 16) { sterminate }
   end
end
```


### HDLRuby enumerators and enumerable objects: `std/sequencer.rb`

HDLRuby enumerators are objects for generating iterations within sequencers. They are created using the method `seach` on enumerable objects as presented in the previous section.

The enumerators can be controlled using the following methods:

 - `size`: returns the number of elements the enumerator can access.

 - `type`: returns the type of the elements accessed by the enumerator.

 - `seach`: returns the current enumerator. If a block is given, performs the iteration instead of returning an enumerator.

 - `seach_with_index`: returns an enumerator over the elements of the current enumerator associated with their index position. If a block is given, performs the iteration instead of returning an enumerator.

 - `seach_with_object(<obj>)`: returns an enumerator over the elements of the current enumerator associated with object `obj` (any object, HDLRuby or not, can be used). If a block is given, performs the iteration instead of returning an enumerator.

 - `with_index`: identical to `seach_with_index`.

 - `with_object(<obj>)`: identical to `seach_with_object`.

 - `clone`: create a new enumerator on the same elements.

 - `speek`: returns the current element pointed by the enumerator without advancing it.

 - `snext`: returns the current element pointed by the enumerator and goes to the next one.

 - `srewind`: restart the enumeration.

 - `+`: concatenation of enumerators.

It is also possible to define a custom enumerator using the following command:

```ruby
<enum> = senumerator(<typ>,<size>) <block>
```

Where `enum` is a Ruby variable referring to the enumerator, `typ` is the data type and `size` is the number of the elements to enumerate, and `block` is the block that implements the access to an element by index. For example, an enumerator on a memory could be defined as follows:

```ruby
    bit[8][-8].inner mem: [ _h01, _h02, _h03, _h04, _h30, _h30, _h30, _h30 ]
    [3].inner :addr
    [8].inner :data

    data <= mem[addr]

    mem_enum = senumerator(bit[8],8) do |i|
        addr <= i
        step
        data
    end
```

In the code above, `mem_enum` is the variable referring to the resulting enumerator built for accessing memory `mem`. For the access, it is assumed that one cycle must be waited for after the address is set, and therefore a `step` command is added in the access procedure before `data` can be returned.

With this basis, several algorithms have been implemented using enumerators and are usable for all the enumerable objects. All these algorithms are HW implantation of the Ruby Enumerable methods. They are accessible using the corresponding ruby method prefixed by character `s`. For example, the HW implementation of the ruby `all?` method is generated by the `sall?` method. In details:

 - `sall?`: HW implementation of the Ruby `all?` method. Returns a single-bit signal. When 0 this value means false and when 1 it means true.

 - `sany?`: HW implementation of the Ruby `any?` method. Returns a single-bit signal. When 0 this value means false and when 1 it means true.

 - `schain`: HW implementation of the Ruby `chain`.

 - `smap`: HW implementation of the Ruby `map` method. When used with a block returns a vector signal containing each computation result.

 - `scompact`: HW implementation of the Ruby `compact` method. However, since there is no nil value in HW, use 0 instead for compacting. Returns a vector signal containing the compaction result.

 - `scount`: HW implementation of the Ruby `count` method. Returns a signal whose bit width matches the size of the enumerator containing the count result.

 - `scycle`: HW implementation of the Ruby `cycle` method.

 - `sfind`: HW implementation of the Ruby `find` method. Returns a signal containing the found element, or 0 if not found.

 - `sdrop`: HW implementation of the Ruby `drop` method. Returns a vector signal containing the remaining elements.

 - `sdrop_while`: HW implementation of the Ruby `drop_while` method. Returns a vector signal containing the remaining elements.

 - `seach_cons`: HW implementation of the Ruby `each_cons` method.

 - `seach_slice`: HW implementation of the Ruby `each_slice` method.

 - `seach_with_index`: HW implementation of the Ruby `each_with_index` method.

 - `seach_with_object`: HW implementation of the Ruby `each_with_object` method.

 - `sto_a`: HW implementation of the Ruby `to_a` method. Returns a vector signal containing all the elements of the enumerator.

 - `sselect`: HW implementation of the Ruby `select` method. Returns a vector signal containing the selected elements.

 - `sfind_index`: HW implementation of the Ruby `find_index` method. Returns the index of the found element or -1 if not.

 - `sfirst`: HW implementation of the Ruby `first` method. Returns a vector signal containing the first elements.

 - `sinclude?`: HW implementation of the Ruby `include?` method. Returns a single-bit signal. When 0 this value means false and when 1 it means true.

 - `sinject`: HW implementation of the Ruby `inject` method. Return a signal of the type of elements containing the computation result.

 - `smax`: HW implementation of the Ruby `max` method. Return a vector signal containing the found max values.

 - `smax_by`: HW implementation of the Ruby `max_by` method. Return a vector signal containing the found max values.

 - `smin`: HW implementation of the Ruby `min` method. Return a vector signal containing the found min values.

 - `smin_by`: HW implementation of the Ruby `min_by` method. Return a vector signal containing the found min values.

 - `sminmax`: HW implementation of the Ruby `minmax` method. Returns a 2-element vector signal containing the resulting min and max values.

 - `sminmax_by`: HW implementation of the Ruby `minmax_by` method. Returns a 2-element vector signal containing the resulting min and max values.

 - `snone?`: HW implementation of the Ruby `none?` method. Returns a single-bit signal. When 0 this value means false and when 1 it means true.

 - `sone?`: HW implementation of the Ruby `one?` method. Returns a single-bit signal. When 0 this value means false and when 1 it means true.

 - `sreject`: HW implementation of the Ruby `reject` method. Returns a vector signal containing the remaining elements.

 - `sreverse_each`: HW implementation of the Ruby `reverse_each` method.

 - `ssort`: HW implementation of the Ruby `sort` method. Returns a vector signal containing the sorted elements.

 - `ssort_by`: HW implementation of the Ruby `sort_by` method. Returns a vector signal containing the sorted elements.

 - `ssum`: HW implementation of the Ruby `sum` method. Returns a signal with the type of elements containing the sum result.

 - `stake`: HW implementation of the Ruby `take` method. Returns a vector signal containing the taken elements.

 - `stake_while`: HW implementation of the Ruby `take_while` method. Returns a vector signal containing the taken elements.

 - `suniq`: HW implementation the Ruby `uniq` method. Returns a vector signal containing the selected elements.



### Shared signals, arbiters, and monitors: `std/sequencer_sync.rb`
<a name="shared"></a>

#### Shared signals

Like any other process, It is not possible for several sequencers to write to the same signal. This is because there would be race competition that may destroy physically the device if such operations were authorized. In standard RTL design, this limitation is overcome by implementing three-state buses, multiplexers, and arbiters. However, HDLRuby sequencers support another kind of signal called the *shared signals* that abstract the implementation details for avoiding race competition.

The shared signals are declared like the other kind of signals from their type. The syntax is the following:

```ruby
<type>.shared <list of names>
```

They can also have an initial (and default) value when declared as follows:

```ruby
<type>.shared <list of names with initialization>
```

For example, the following code declares two 8-bit shared signals `x` and `y` and two signed 16-bit shared signals initialized to 0 `u` and `v`:

```ruby
[8].shared :x, :y
signed[8].shared u: 0, v: 0
```

A shared signal can then be read and written to by any sequencer from anywhere in the subsequent code of the current scope. However, they cannot be written to outside a sequencer. For example, the following code is valid:

```ruby
input :clk, :start
[8].inner :val0, :val1
[8].shared :x, :y

val0 <= x+y
par(clk.posedge) { val1 <= x+y }

sequencer(clk.posedge,start) do
   10.stimes { |i| x <= i }
end

sequencer(clk.posedge,start) do
   5.stimes { |i| x <= i*2 ; y <= i*2 }
end
```

But the following code is not valid:

```ruby
[8].shared w: 0

par(clk.posedge) { w <= w + 1 }
```

By default, a shared signal acknowledges writing from the first sequencer that accesses it in order of declaration, the others are ignored. In the first example given above, that means for signal `x` the value is always the one written by the first sequencer, i.e., from 0 to 9 changing once per clock cycle. However, the value of signal `y` is set by the second sequencer since it is this one only that writes to this signal.

This default behavior of shared signal avoids race competition but is not very useful in practice. For better control, it is possible to select which sequencer is to be acknowledged for writing. This is done by setting the number of the sequencer which can write the signal that controls the sharing accessed as follows:

```ruby
<shared signal>.select
```

The select value starts from 0 for the first sequencer writing to the shared signal, and is increased by one per writing sequencer. For example, in the first example, for selecting the second sequencer for writing to `x` the following code can be added after this signal is declared:

```ruby
   x.select <= 1
```

This value can be changed at runtime too. For example, instead of setting the second sequencer, it is possible to switch the sequencer every clock cycle as follows:

```ruby
   par(clk.posedge) { x.select <= x.select + 1 }
```

__Note__: this select sub signal is a standard RTL signal that has the same properties and limitations as the other ones, i.e., this is not a shared signal itself.


#### Arbiters

Usually, it is not the signals that we want to share, but the resources they drive. For example, in a CPU, it is an ALU that is shared as a whole rather than each of its inputs separately. In order to support such cases and ease the handling of shared signals, the library also provides the *arbiter* components. This component is instantiated like a standard module as follows, where `name` is the name of the arbiter instance:

```ruby
arbiter(:<name>).(<list of shared signal>)
```

When instantiated, an arbiter will take control of the select sub-signals of the shared signals (hence, you cannot control the selection yourself for them any longer). In return, it provides the possibility of requiring or releasing access to the shared signals. Requiring access is done by sending the value 1 to the arbiter, and releasing is done by sending the value 0. If a sequencer writes to a shared signal under arbitration without requiring access first, the write will simply be ignored.

The following is an example of an arbiter that controls access to shared signals `x` and `y` and two sequencers acquiring and releasing accesses to them:

```ruby
input :clk, :start
[8].shared x, y
arbiter(:ctrl_xy).(x,y)

sequencer(clk.posedge,start) do
   ctrl_xy <= 1
   x <= 0 ; y <= 0
   5.stime do |i|
      x <= x + 1
      y <= y + 2
   end
   ctrl_xy <= 0
end

sequencer(clk.posedge,start) do
   ctrl_xy <= 1
   x <= 2; y <= 1
   10.stime do |i|
      x <= x + 2
      y <= y + 1
   end
   ctrl_xy <= 0
end
```

In the example, both sequencers require access to signals `x` and `y` before accessing them and then releasing the access. 

Requiring access does not guarantee that the access will be granted by the arbiter though. In the access is not granted, the write access will be ignored.
The default access granting policy of an arbiter is the priority in the order of sequencer declaration. I.e., if several sequencers are requiring one at the same time, then the one declared the earliest in the code gains write access. For example, with the code given above, the first sequencer has to write access to `x` and `y`, and since after five write cycles it releases access, the second sequencer can then write to these signals. However, not obtaining write access does not block the execution of the sequencer, simply, its write access to the corresponding shared signals is simply ignored. In the example, the second sequencer will do its first five loop cycles without any effect and have only its five last ones that change the shared signals. To avoid such a behavior, it is possible to check if the write access is granted using arbiter sub signal `acquired`: if this signal is one in the current sequencer, that means the access is granted, otherwise it is 0. For example the following will increase signal `x` only if write access is granted:

```ruby
hif(ctrl_xy.acquired) { x <= x + 1 }
```

The policy of an arbiter can be changed using command policy. You can either provide a new priority table, containing the number of the sequencers in order of priority (the first one having higher priority. The number of a sequencer is assigned in order of declaration provided it uses the arbiter. For example, in the previous code, the second sequencer can be given higher priority by adding the following code after having declared the arbiter:

```ruby
ctrl_xy.policy([1,0])
```

It is also possible to set a more complex policy by providing to the policy method a block of code whose argument is a vector indicating which sequencer is currently requiring write access to the shared signals and whose result will be the number of the sequencer to grant the access. This code will be executed each time write access is actually performed. For example, in the previous code, a policy switch priorities at each access can be implemented as follows:

```ruby
inner priority_xy: 0
inner grant_xy
ctrl_xy.policy do |acq|
   hcase(acq)
   hwhen(_b01) do
      grant_xy <= 0
      priority_xy <= ~priority_xy
   end
   hwhen(_b10) do
      grant_xy <= 1
      priority_xy <= ~priority_xy
   end
   hwhen(_b11) do
      grant_xy <= priority_xy
      priority_xy <= ~priority_xy
   end
   grant_xy
end
```

As seen in the code above, each bit of the `acq` vector is one when the corresponding sequencer required an access or 0 otherwise, bit 0 corresponds to sequencer 0, bit 1 to sequencer 1 and so on.


#### Monitors

Arbiters are especially useful when we can ensure that the sequencers accessing the same resource do not overlap or when they do not need to synchronize with each other. If such synchronizations are required, instead of arbiters, it is possible to use the *monitor* components.

The monitor component is instantiated like the arbiters as follows:

```ruby
monitor(:<name>).(<list of shared signals>)
```

Monitors are used exactly the same ways as arbiters (including the write access granting policies) but block the execution of the sequencers that require write access until the access is granted. If we take the example of code with two sequencers given as an illustration of arbiter usage, replacing the arbiter with a monitor as follows will lock the second sequencer until it can write to shared variables `x` and `y` ensuring that all its loop cycles have the specified result:

```ruby
monitor(:ctrl_xy).(x,y)
```

Since monitors lock processes, they automatically insert a step. Hence to avoid confusion, acquiring access to a monitor is done by using the method `lock` instead of assigning 1, and releasing is done by using the method `unlock` instead of assigning 0. Hence, when using a monitor, the previous arbiter-based code should be rewritten as follows:

```ruby
input :clk, :start
[8].shared x, y
monitor(:ctrl_xy).(x,y)

sequencer(clk.posedge,start) do
   ctrl_xy.lock
   x <= 0 ; y <= 0
   5.stime do |i|
      x <= x + 1
      y <= y + 2
   end
   ctrl_xy.unlock
end

sequencer(clk.posedge,start) do
   ctrl_xy.lock
   x <= 2; y <= 1
   10.stime do |i|
      x <= x + 2
      y <= y + 1
   end
   ctrl_xy.unlock
end
```

### Sequencer-specific function: `std/sequencer_func.rb`

HDLRuby function defined by `hdef` can be used in sequencer like any other HDLRuyby construct. But like the process constructs `hif` and so on, the body of these functions cannot include any sequencer-specific constructs.

However, it is possible to define functions that do support the sequencer constructs using `sdef` instead of `hdef` as follows:

```ruby
   sdef :<function name> do |<arguments>|
   <sequencer code>
   end
```

Such functions can be defined anywhere in a HDLRuby description, but can only be called within a sequencer.

As additional features, since the `sdef` function is made to support the software-like code description of the sequencers, it also supports recursion. For example, a function describing a factorial can be described as follows:

```ruby
sdef(:fact) do |n|
    sif(n > 1) { sreturn(n*fact(n-1)) }
    selse      { sreturn(1) }
end
```

As seen in the code above, a new construct `sreturn` can be used for returning a value from anywhere inside the function.

When a recursion is present, HDLRuby automatically defines a stack for storing the return state and the arguments of the function. The size of the stack is heuristically set to the maximum number of bits of the arguments of the function when it is recursively called. For example, for the previous `fact` function, if when called, `n` is 16-bit, the stack will be able to hold 16 recursions. If this heuristic does not match the circuit's needs, the size can be forced as a second argument when defining the function. For example, the following code set the size to 32 whatever the arguments are:

```ruby
sdef(:fact,32) do |n|
    sif(n > 1) { sreturn(n*fact(n-1)) }
    selse      { sreturn(1) }
end
```

__Notes__:

 * A call to such a function and a return take respectively one and two cycles of the sequencer.

 * For now, there is no tail call optimization.

 * In case of stack overflow (the number of recursive calls exceeds the size of the sack), the current recursion is terminated and the sequencer goes on its execution. It is possible to add a process that is to be executed in such a case as follows:
  
    ```ruby
       sdef(:<name>,<depth>, proc <block>) do
          <function code>
       end
    ```

    Where `block` contains the code of the stack overflow process. For now, this process cannot contain a sequencer construct. For example, the previous factorial function can be modified as follows so that signal `stack_overflow` is set to 1 in case of overflow:

    ```ruby
    sdef(:fact,32, proc { stack_overflow <= 1 }) do |n|
        sif(n > 1) { sreturn(n*fact(n-1)) }
        selse      { sreturn(1) }
    end
    ```

    With the code above, the only restriction is that the signal `stack_overflow` is declared before the function `fact` is called.


## Fixed-point (fixpoint): `std/fixpoint.rb`
<a name="fixpoint"></a>

This library provides a new fixed point set of data types. These new data types can be bit vectors, unsigned or signed values and are declared respectively as follows:

```ruby
bit[<integer part range>,<fractional part range>]
unsigned[<integer part range>,<fractional part range>]
signed[<integer part range>,<fractional part range>]
```

For example, a signed 4-bit integer part 4-bit fractional part fixed point inner signal named `sig` can be declared as follows:

```ruby
bit[4,4].inner :sig
```

When performing computation with fixed-point types, HDLRuby ensures that the result's decimal point position is correct.

In addition to the fixed point data type, a method is added to the literal objects (Numeric) to convert them to fixed-point representation:

```ruby
<litteral>.to_fix(<number of bits after the decimal point>)
```

For example, the following code converts a floating-point value to a fixed-point value with 16 bits after the decimal point:

```
3.178.to_fix(16)
```


## Channel: `std/channel.rb`
<a name="channel"></a>

This library provides a unified interface to complex communication protocols through a new kind of component called the channels that abstract the details of communication protocols. The channels can be used similarly to the ports of a system and are used through a unified interface so that changing the kind of channel, i.e., the communication protocol, does not require any modification of the code.

### Using a channel

A channel is used similarly to a pipe: it has an input where data can be written and an output where data can be read. The ordering of the data and the synchronization depend on the internals of the channel, e.g., a channel can be FIFO or LIFO. The interaction with the channel is done using the following methods:

 * `write(<args>) <block>`: write to the channel and execute `block` when `write` completes. `args` is a list of arguments required for performing the write that depends on the channel.
 * `read(<args>) <block>`: read the channel and execute `block` when the read completes. `args` is a list of arguments required for performing the write that depends on the channel.


For example, a system sending successive 8-bit values through a channel can be described as follows:

```ruby
system :producer8 do |channel|
    # Inputs of the producer: clock and reset.
    input :clk, :rst
    # Inner 8-bit counter for generating values.
    [8].inner :counter

    # The value production process
    par(clk.posedge) do
        hif(rst) { counter <= 0 }
        helse do
            channel.write(counter) { counter <= counter + 1 }
        end
    end
end
```

__Note__: In the code above, the channel is passed as a generic argument of the system.

The access points to a channel can also be handled individually by declaring ports using the following methods:
 
 * `input <name>`: declares a port for reading from the channel and associates them to `name` if any
 * `output <name>`: declares a port for writing to the channel and associates them to `name` if any
 * `inout <name>`: declares a port for reading and writing to the channel and associates them to `name` if any

Such a port can then be accessed using the same `read` and `write` method of a channel, the difference being that they can also be configured for new access procedures using the `wrap` method:

 * `wrap(<args>) <code>`: creates a new port whose read or write procedure has the elements of `<args>` and the ones produced by `<code>` assigned to the arguments of the read or write procedure.

For example, assuming `mem` is a channel whose read and write access have as argument the target address and data signals, the following code creates a port for always accessing at address 0:

```ruby
  addr0 = channel.input.wrap(0) 
```

### Channel branches

Some channels may include several branches, they are accessed by name using the following method:
 
 * `branch(<name>)`: gets branch named `name` from the channel. This name can be any ruby object (e.g., a number) but it will be converted internally to a ruby symbol.

A branch is a full-fledged channel and is used identically. For instance, the following code gets access to branch number 0 of channel `ch`, gets its inputs port, reads it, and put the result in signal `val` on the rising edges of signal `clk`:

```ruby
br = ch.branch(0)
br.input
par(clk.posedge) { br.read(val) }
```

### Declaring a channel

A new channel is declared using the keyword `channel` as follows:

```ruby
channel <name> <block>
```

Where `name` is the name of the channel and `block` is a procedure block describing the channel. This block can contain any HDLRuby code, and is comparable to the content of a block describing a system with the difference that it does not have standard input, output, and inout ports are declared differently, and that it supports the following additional keywords:

 * `reader_input <list of names>`: declares the input ports on the reader side. The list must give the names of the inner signals of the channel that can be read using the reader procedure.
 * `reader_output <list of names>`: declares the output ports on the reader side. The list must give the names of the inner signals of the channel that can be written using the reader procedure.
 * `reader_inout <list of names>`: declares the inout ports on the reader side. The list must give the names of the inner signals of the channel that can be written using the reader procedure.
 * `writer_input <list of names>`: declares the input ports on the writer side. The list must give the names of the inner signals of the channel that can be read using the writer procedure.
 * `writer_output <list of names>`: declares the output ports on the writer side. The list must give the names of the inner signals of the channel that can be written using the writer procedure.
 * `writer_inout <list of names>`: declares the inout ports on the writer side. The list must give the names of the inner signals of the channel that can be written using the writer procedure.
 * `accesser_input <list of names>`: declares the input ports on both the reader and writer sides. The list must give the names of the inner signals of the channel that can be read using the writer procedure.
 * `accesser_output <list of names>`: declares the output ports on both the reader and writer sides. The list must give the names of the inner signals of the channel that can be written using the writer procedure.
 * `accesser_inout <list of names>`: declares the inout ports on both the reader and writer sides. The list must give the names of the inner signals of the channel that can be written using the writer procedure.
 * `reader <block>`: defines the reader's access procedure.
   This procedure is invoked by the method `read` of the channel (please refer to the previous example).
 The first argument of the block must be the following:
   - `blk`: the block to execute when the read completes.
 Other arguments can be freely defined and will be required by the `read` method.
 * `writer < block>`: defines the writer's access procedure.
   This procedure is invoked by the method `write` of the channel (please refer to the previous example).
 The first argument of the block must be the following:
   - `blk`: the block to execute when the write completes.
 Other arguments can be freely defined and will be required by the `write` command.
 * `brancher(name) <block>`: defines branch named +name+ described in `block`. The content of the block can be any content valid for a channel, with the additional possibility to access the internals of the upper channel.

For example, a channel implemented by a simple register of generic type `typ`, that can be set to 0 using the `reset` command can be described as follows:

```ruby
channel :regch do |typ|
   # The register.
   typ.inner :reg

   # The reader procedure can read reg
   reader_input :reg
   # The writer procedure can write reg
   writer_output :reg

   # Declares a reset
   command(:reset) { reg <= 0 }

   # Defines the reader procedure.
   reader do |blk,target|
      target <= reg
      blk.call if blk
   end

   # Defines the writer procedure.
   writer do |blk,target|
      reg <= target
      blk.call if blk
   end
end
```

__Notes__:

 * The described channel assumes that the `write` method of the channel is invoked within a clocked process (otherwise, the register will become a latch).
 * The described channel supports the `read` and `write` methods to be invoked with or without a block.


Like systems, a channel must be instantiated for being used, and the instantiation procedure is identical: 

```ruby
<channel name> :<instance name>
```

And in case there is a generic parameter, the instantiation procedure is as follows:

```ruby
<channel name>(:<instance name>).(<generic parameters>)
```

After a channel is instantiated, it must be linked to the circuits that will communicate through it. This is done when instantiating these circuits. If a circuit reads or writes on the channel, it will be instantiated as follows:

```ruby
<system name>(<channel instance>).(:<instance name>).(<circuit standard connections>)
```


__Notes__:

 * It is possible for a circuit to access several channels. For that purpose, each channel must be passed as generic arguments, and their corresponding `reader_signals` and `writer_signals` are to be put in the order of declaration.
 * It is also possible for a circuit to read and write on the same channel. For that purpose, the channel will be passed several times as generic arguments, and the corresponding `reader_signals` and `writer_signals` are to be put in the order of declaration.

The following code is an example instantiating the register channel presented above for connecting an instance of `producer8` and another circuit called `consumer8`:

```ruby
# System wrapping the producer and the consumer circuits.
system :producer_consumer8 do
   # The clock and reset of the circuits
   input :clk, :rst

   # Instance of the channel (using 8-bit data).
   regch([8]).(:regchI)

   # Reset the channel on positive edges of signal rst.
   regchI.reset.at(rst.posedge)

   # Instantiate the producer.
   producer8(regch).(:producerI).(clk,rst)

   # Instantiate the consumer.
   consumer8(regch).(:consumerI).(clk.rst)
end
```

__Note__:

 * The code of the circuits, in the examples `producer8`, `consumer8`, and `producer_consummer8` is independent of the content of the channel. For example, the sample `with_channel.rb` (please see [samples](#sample-hdlruby-descriptions)) uses the same circuits with a channel implementing handshaking.

<!---

## Pipeline
<a name="pipeline"></a>

This library provides a construct for an easy description of pipeline architectures.

-->

# Sample HDLRuby descriptions

Several samples HDLRuby descriptions are available in the following directory:

path/to/HDLRuby/lib/HDLRuby/hdr\_samples

For the gem install, the path to HDLRuby can be found using the following:

```bash
gem which HDLRuby
```

But you can also import the samples to your local directory with the following command (recommended):

```bash
hdrcc --get-samples
```

The naming convention of the samples is the following:

* `<name>.rb`:       default type of sample.
* `<name>_gen.rb`:   generic parameters are required for processing the sample.
* `<name>_bench.rb`: sample including a simulation benchmark, these are the only samples that can be simulated using `hdrcc -S`. Please notice that such a sample cannot be converted to VHDL or Verilog HDL yet.
* `with_<name>.rb`: sample illustrating a single aspect of HDLRuby or one of its library, usually includes a benchmark.


# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/civol/HDLRuby.


# To do

 * Find and fix the (maybe) terrifying number of bugs.
 * Add a GUI (any volunteer to do it?).


# License

The gem is available as open-source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

