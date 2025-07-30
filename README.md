# About HDLRuby

HDLRuby is a library for describing and simulating digital electronic
systems.

__Note__:

If you want to learn how to describe a circuit with HDLRuby, please jump to the following section:

* [HDLRuby Programming Guide](#hdlruby-programming-guide)

  * [Introduction](#introduction)

  * [How HDLRuby Works](#how-hdlruby-works)

  * [Naming rules](#naming-rules)

  * [Systems and Signals](#systems-and-signals)

  * [Events](#events)

  * [Statements](#statements)

  * [Types](#types)

  * [Expressions](#expressions)

  * [Functions](#functions)

  * [Software code](#software-code)

  * [Time](#time)

  * [High-Level Programming Features](#high-level-programming-features)

  * [Extending HDLRuby](#extending-hdlruby)

Many of HDLRuby's features are available through its standard libraries.
We strongly recommend consulting the corresponding section:

* [Standard Libraries](#standard-libraries)

  * [Clocks](#clocks)

  * [Decoder](#decoder)

  * [FSM](#fsm)

  * [Parallel Enumerators](#parallel-enumerators)

  * [Sequencer (Software-like Hardware Coding)](#sequencer-software-like-hardware-coding)

  * [Fixed-Point](#fixed-point)

Samples are also available: [Sample HDLRuby descriptions](#sample-hdlruby-descriptions)

Finally, HDLRuby can also process Verilog HDL files: [Converting Verilog HDL to HDLRuby](#converting-verilog-hdl-to-hdlruby).

If you are new to HDLRuby, we recommend starting with the following
tutorial even if you have a hardware background:

* [HDLRuby Tutorial for Software People](https://github.com/civol/HDLRuby/blob/master/tuto/tutorial_sw.md) [md]

If you would prefer an HTML version, you can generate it by running the
following command. This will create a `tuto` folder containing all the
necessary files. Then, simply open `tuto/tutorial_sw.html`:

```
hdrcc --get-tuto
```

__What's New__

For HDLRuby version 3.9.0:

* Added the parallel enumerators to the software sequencers.

* Added experimental TensorFlow code generation from the software sequencers.

* Added the possibility to declare vectors of instances.

* Added the possibility to fix the data type for the accumulation with the hinject and sinject enumerators.

* Fixed various bugs.

* Made an overhaul of the documentation.


For HDLRuby version 3.8.3:

* Fixed various bugs including some in interactive mode.

* Updated the documentation: 

  * Rewrote the beginning of the [HDLRuby Programming Guide](#hdlruby-programming-guide).

  * Updated the documentation for interactive mode.

  * Updated the [High-Level Programming Features](#high-level-programming-features) chapter.

For HDLRuby version 3.8.0:

* Added parallel enumerators (e.g., heach), allowing Ruby-like iteration for describing parallel hardware.

* Added genererive programming using standard HDLRuby constructs (e.g., hif) -- there is no need to use Ruby code directly any more.

* Fixed compile bugs for windows.


For HDLRuby version 3.7.9:

* Added Python code generation from software sequencers.

* Added [Parallel Enumerators](#parallel-enumerators). 

For HDLRuby versions 3.7.7/3.7.8:

* Various fixes related to software sequencers.

For HDLRuby version 3.7.6:

* Added initial value support for signals in software sequencers.

* Fixed `hprint` in software sequencers.

For HDLRuby versions 3.7.4/3.7.5:

* Various bug fixes.

For HDLRuby version 3.7.3:

* Enabled use of software sequencers within HDLRuby's `program` construct, including use of program ports as if they were input or output signals.

For HDLRuby version 3.7.2:

* Added the `text` command for software sequencers.

* Added the `value_text` method to software sequencers signal, generating Ruby/C code with correct typing.

* Added the `alive?` and `reset!` commands for HDLRuby sequencers.

* Added the `require_ruby` method for loading Ruby (i.e., non-HDLRuby) libraries.

For HDLRuby version 3.7.x:

* Added the possibility to run [Sequencers in Software](#sequencers-as-software-code). (WIP)
This enables significantly faster simulation and allows reusing the same code for both hardware and software design.


For HDLRuby version 3.6.x:

* Added a new GUI board element allowing assignment of expressions to signals during simulation.

* Added a new slider element for the GUI board (from 3.6.1).

For HDLRuby version 3.5.0:

* Added direct support for Verilog HDL files as input to 'hdrcc'.

* Added the ability to generate a graphical representation of the RTL code in SVG format using the '--svg' option for 'hdrcc'.


For HDLRuby version 3.4.0:

* Improved synchronization between the browser-based graphical interface and the HDLRuby simulator.

* Added a Verilog HDL parsing library for Ruby (to be released separately once stabilized).

* Added a library for generating HDLRuby code from a Verilog HDL AST (produced by the parsing library).

* Added [v2hdr](#converting-verilog-hdl-to-hdlruby), a standalone tool for converting Verilog HDL files to HDLRuby (experimental).

* Added a HDLRuby command for [loading a Verilog HDL file from a HDLRuby description](#converting-verilog-hdl-to-hdlruby).


For HDLRuby version 3.3.0:
 
* Redesigned the description of software components using the program construct.
   The `Code` objects are now deprecated.

* Added HW/SW co-simulation capability for Ruby and compiled C-compatible
   software programs.

* Added a browser-based graphical interface simulating a development board that interacts with the HDLRuby simulator.

* Updated the documentation and tutorial accordingly, and fixed several typos.


For HDLRuby version 3.2.0:

* Added components for declaring BRAM and BRAM-based stacks to enable efficient memory allocation in FPGAs.

* Performed internal code overhaul in preparation for version 4.0.0.

* Multiple bug fixes.


For HDLRuby version 3.1.0:

* Added [functions for sequencers](#sequencer-specific-functions), including support for recursion.

* Replaced the `function` keyword with `hdef` for consistency with sequencer functions (`sdef`).

* Added the `steps` command for waiting multiple steps in a sequencer.

* Improved Verilog HDL code generation to better preserve original signal names.

* Several bug fixes for the sequencers.

For HDLRuby version 3.0.0:

* Intruduced this changelog section.

* Added [Sequencers](#sequencer-software-like-hardware-coding) for software-like hardware design.

* Added a [tutorial](tuto/tutorial_sw.md) for software developers.

* The stable [Standard Libraries](#standard-libraries) are now loaded by
   default.


__Install__:

The recommended method of installation is via RubyGems:

```
gem install HDLRuby
```

Developers who wish to contribute to HDLRuby can install it from source using GitHub:

```
git clone https://github.com/civol/HDLRuby.git
```

__Warning__: 

* HDLRuby is still under active development, and the API may change before a stable release.

* It is highly recommended that users have a basic understanding of both the Ruby programming language and hardware description languages before using HDLRuby.


# Compiling HDLRuby Descriptions

## Using the HDLRuby Compiler

'hdrcc' is the HDLRuby compiler. It takes an HDLRuby file as input, checks it, and can generate one of several outputs: Verilog HDL, VHDL, or a YAML low-level hardware component description. It can also simulate the input design.


__Usage__:

```
hdrcc [options] <input file> <output/working directory>
```

Where:

* `options` is a list of options (see below)

* `<input file>` is the input HDLRuby file to compile (mandatory)

* `<output/working directory>` is the directory where output and temporary files will be stored

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
| `--rcsim`         | Perform the simulation with the Hybrid engine        |
| `--vcd`           | Make the simulator generate a VCD (waveform) file               |
| `--svg`           | Output a graphical representation of the RTL (SVG format) |
| `-d, --directory` | Specify the base directory for loading the HDLRuby files |
| `-D, --debug`     | Set the HDLRuby debug mode |
| `-t, --top system`| Specify the top system describing the circuit to compile |
| `-p, --param x,y,z`     | Specify the generic parameters                 |
| `--get-samples`   | Copy the `hdr_samples` directory to the current directory, then exit |
| `--version`       | Show the version number, then exit                  |
| `-h, --help`      | Show the help message                                    |

__Notes__:

* If no top system is specified, it will be automatically inferred from the input file.

* If no options are provided, the compiler will only check the input file for correctness.

* If you're new to HDLRuby, or want to see working examples of new features, we strongly recommend downloading the sample files:
    
  ```bash
  hdrcc --get-samples
  ```  
    
  This will create a `hdr_samples` subdirectory in your current folder, containing various HDLRuby example files. For more details, see the [samples](#sample-hdlruby-descriptions).


__Examples__:

* Compile `adder.rb` and generate a low-level Verilog HDL description in the `adder` directory:

```bash
hdrcc -v adder.rb adder
```

* Compile the Verilog HDL file `adder8.v`, using `adder8` as the top module, and generate a graphical RTL diagram in the `view` directory:

```bash
hdrcc adder8.v -t adder8 --svg view
```
  
* Compile a parameterized system `multer` from `multer_gen.rb`, generating a 16x16->32-bit YAML hardware description into the `multer` directory:

```bash
hdrcc -V -t adder --param 16 adder_gen.rb adder
```

* Compile system `multer` with inputs and output bit width is generic from `multer_gen.rb` input file to a 16x16->32-bit circuit whose low-level YAML description into directory `multer`:

```bash
hdrcc -y -t multer -p 16,16,32 multer_gen.rb multer
```

* Simulate the circuit described in `counter_bench.rb` using the default simulation engine, outputting files to the `counter` directory:

```bash
hdrcc -S counter_bench.rb counter
```

  Note: The default simulation engine is set to the fastest available engine (currently, the hybrid engine).

* Run in interactive mode.

```bash
hdrcc -I
```

* Run in interactive mode using pry as UI.

```bash
hdrcc -I pry
```

## Using HDLRuby in Interactive Mode

When run in interactive mode, the HDLRuby framework launches a REPL (Read-Eval-Print Loop) environment and creates a working directory named HDLRubyWorkspace. By default, the REPL is irb, but it can also be set to pry.

Within the interactive prompt, you can write HDLRuby code just as you would in a standard HDLRuby source file. In addition, a set of special commands is available to compile, inspect, and simulate your design interactively:


#### Available Commands

* Compile an HDLRuby module (with optional parameters):

```ruby
hdr_make(<module>[,<parameters])
```

* Display the internal representation (IR) of the compiled module in YAML format:

```ruby
hdr_yaml
```

* Reconstruct and display the HDLRuby source description of the compiled module:

```ruby
hdr_hdr
```

* Generate and save Verilog HDL output to the `HDLRubyWorkspace` directory:

```ruby
hdr_verilog
```

* Generate and save VHDL output to the HDLRubyWorkspace directory:

```ruby
hdr_vhdl
```

* Simulate the compiled module:

```ruby
hdr_sim
```

* Simulate the compiled module and save the VCD trace (waveform output) to  the directory `HDLRubyWorkspace`:

```
hdr_sim_vcd
```

* Simulate the compiled module in mute mode:

```
hdr_sim_mute
```



## HDLRuby files.

Since HDLRuby is built on top of the Ruby language, it is standard convention to name HDLRuby files with the `.rb` extension.

For the same reason, including external HDLRuby files is done using the Ruby `methods require` or `require_relative`, which behave the same way as in standard Ruby. However, these methods can only be used to include HDLRuby description files, not plain Ruby files.

To include standard Ruby code (e.g., helper libraries or tools), you must use the methods `require_ruby` or `require_relative_ruby`.


# HDLRuby programming guide

HDLRuby is designed to bring the flexibility and expressiveness of the Ruby language to hardware description, while ensuring that the resulting designs remain synthesizable. The abstractions provided by HDLRuby are meant to aid in describing hardwareÑbut they do not alter the underlying execution model, which is RTL (Register Transfer Level) by construction.

Another key feature of HDLRuby is its native support for all features of the Ruby language.

__Notes__:

* It is possible to extend HDLRuby to support hardware descriptions at a higher level of abstraction than RTL. See [Extending HDLRuby](#extending-hdlruby) for more details.
* Throughout this guide, HDLRuby constructs are often compared to their Verilog HDL or VHDL equivalents to aid understanding.

## Introduction

This introduction gives a glimpse of what HDLRuby makes possible.

At first glance, HDLRuby resembles other hardware description languages such as Verilog HDL or VHDL. For example, the following code describes a simple D flip-flop:

```ruby
system :dff do
   bit.input :clk, :rst, :d
   bit.output :q

   par(clk.posedge) do
      q <= d & ~rst
   end
end
```

In this example, `system` is the keyword used to define a hardware component, similar to the `module` construct in Verilog HDL. Signals are declared using a `<type>.<direction>` format, where `type` is the data type (e.g., `bit`) and direction indicates the signal's role (`input`, `output`, `inout`, or `inner`). Processes, like Verilog's `always` blocks, are described using the `par` keyword for non-blocking assignments and `seq` for blocking assignments.

Here is a second example: an 8-bit adder.

```ruby
system :adder8 do
   bit[7..0].input :x, :y
   bit[7..0].output :z
   bit.output :cout

   [cout,z] <= x.as(bit[8..0]) + y
end
```

This example demonstrates how to declare vector types. The signals `x`, `y`, and `z` are 8-bit unsigned vectors. If signed values are needed, you would use `signed` instead of `bit`.

Line 6 illustrates a connection (similar to the `assign` statement in Verilog HDL), where `cout` and `z` are concatenated and connected to the result of an addition. Note that `x` is explicitly cast to a 9-bit value to preserve the carry-out. In HDLRuby, unlike Verilog HDL, operand types are strictly preserved. This means that adding two 8-bit values yields an 8-bit result unless explicitly extended. The goal is to avoid the type-related ambiguities found in Verilog, while keeping syntax lighter than VHDL.

Conditional statements, common in RTL languages, are also supported in HDLRuby. However, unlike in Verilog or VHDL, HDLRuby conditionals can appear anywhere in a system bodyânot just within processes.

These include:

* `hif` / `helsif` / `helse` for `if`-like conditionals

* `hcase` / `hwhen` / `helse` for `case`-like conditionals

* `mux`, an expression-level construct for multiplexers, which supports multiple inputs, unlike the ?: ternary operator in Verilog, which only handles two

__Note__:  These statements are also called "parallel conditionals" in HDLRuby, to contrast with the ones used in the `sequencer` constructs (see [Sequencer](#sequencer-software-like-Hardware-coding)).

For example, we can upgrade the 8-bit adder to an adder-subtractor:

```ruby
system :adder_suber8 do
   bit.input :addbsub
   bit[7..0].input :x, :y
   bit[7..0].output :z
   bit.output :cout

   hif(addbsub) { [cout,z] <= x.as(bit[8..0]) + ~y + 1 }
   helse        { [cout,z] <= x.as(bit[8..0]) + y }
end
```

The conditional logic above can also be written more compactly using the `mux` expression:

```ruby
  [cout,z] <= x.as(bit[8..0]) + mux(addbsub, y, ~y + 1)
```


---

Once a module has been described, it can be instantiated. For example, a single instance of the `dff` module named `dff0` can be declared as follows:

```ruby
dff :dff0
```

The ports of the instance can be accessed like regular signals. For example, `dff0.d` refers to the d input of the flip-flop.

You can also connect the ports of an instance at the time of declaration. The example above can be extended as follows:

```ruby
system :counter2 do
   bit.input :clk, :rst
   bit.output :q

   dff(:dff0).(clk: clk, rst: rst, d: ~dff0.q)
   dff(:dff1).(~dff0.q, rst, ~dff1.q, q)
end
```

In this example:

* `dff0` uses named connections for its ports (e.g., `clk: clk`).

* `dff1` uses positional connections, in the order the ports were declared in the module.

It is also possible to connect only a subset of the ports at instantiation time, and to reconnect or override ports later in the code.

---

To simulate a circuit, you must write a test bench using `timed` constructs, which describe how signals evolve over time.

Here is an example that simulates the D flip-flop `dff` using a 20 ns clock, and toggles the input `d` every two clock cycles for ten iterations:

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
      repeat(10) do
         repeat(4) { !10.ns ; dff0.clk <= ~dff0.clk }
         dff0.d   <= ~dff0.d
      end
   end
end
```

In this code:

* `!<time>.<unit>` pauses execution for the specified physical time. Units can range from picoseconds (`ps`) to seconds (`s`).

* `repeat(n)` repeats the block `n` times.

* `~dff0.clk` inverts the clock value.

This test bench models both the reset behavior and a clock-driven sequence, demonstrating how to simulate sequential logic in HDLRuby.


---

The `dff` example shown earlier is quite similar to what you would write in other HDLs. However, HDLRuby offers several features to increase productivity and reduce boilerplate in hardware descriptions. Below are a few of these conveniences.

First, HDLRuby supports syntactic sugar that allows for more concise code. For example, the following version of the `dff` module is functionally identical to the earlier version:

```ruby
system :dff do
   input :clk, :rst, :d
   output :q

   (q <= d & ~rst).at(clk.posedge)
end
```

In this example:

* The `bit` type is omitted for signal declarations (it is the default type).

* Since the process contains only a single statement, it is expressed more compactly using the `at` method.

Similarly, the `adder8` module can be written more concisely:

```ruby
system :adder8 do
   [8].input :x, :y
   [8].output :z
   output :cout

   [cout,z] <= x.as(bit[9]) + y
end
```

In this example:

* The vector range `[7..0]` is abbreviated to `[8]`, which implies an 8-bit width.

* The `bit` type is omitted for signal declarations (again, because it is the default).

* __Note__: when casting a signal or using it in expressions where type precision matters, the bit type must still be explicitly specified, as seen in `bit[9]`.


---

Second, HDLRuby also provides high-level constructs that make it easier to describe complex structures and behaviors in hardware.

For example, the `sequencer` construct allows to describe finite state
machines using software code-like statements, including conditionals,
loops and function calls. For example the following module describes a 
simple 8-bit serializing circuit that emmits bit every 10 clock cycle.

```ruby
system :serial do
  [8].input :din
  input :clk, :rst, :req
  output :ack, :bout

  [8].inner :buf

  bout <= buf[0]

  sequencer(clk,rst) do
    sloop do
      ack <= 0 ; buf <= 0
      swhile(~req)
      buf <= din ; ack <= 1
      8.stimes do
        buf <= buf >> 1
        9.stimes
      end
    end
  end
end
```

In this example:

* `sequencer(clk, rst)` creates a clocked finite-state machine initialized on reset `(rst = 1)`.

* `sloop` is an infinite loop.

* `swhile(condition)` loops until the condition becomes false; if it has no body, it waits passively.

* `stimes(n)` is a shorthand for looping a block `n` times.

* Each control-flow step in a sequencer (even inside loops) corresponds to one clock cycle, making timing behavior explicit and predictable.

This example uses `buf` to hold the 8-bit input and shift it right each cycle to serialize it bit by bit onto the `bout` output.

Other HDLRuby high-level contructs includes:

* Iterators (both parallel and sequential)

* Decoders

* Fixed-point arithmetic

* And more...

These high-level abstractions are built on synthesizable foundations, and help keep hardware descriptions clear, maintainable, and concise, especially for complex control logic.

---

Third, HDLRuby supports generic parameters that can be used flexibly to define reusable hardware modules. These parameters can represent sizes, types, or any other construct needed to generalize a design.

For instance, the following example defines a simple, fixed-size 8-bit register:

```ruby
system :reg8 do
   input :clk, :rst
   [8].input :d
   [8].output :q

   (q <= d & [~rst]*8).at(clk.posedge)
end
```

To make this register size configurable, you can introduce a parameter. In this version, `n` defines the bit width of the register:

```ruby
system :regn do |n|
   input :clk, :rst
   [n].input :d
   [n].output :q

   (q <= d & [~rst]*n).at(clk.posedge)
end
```

Going further, you can define a fully generic register by parameterizing not just the size, but the data type itself (e.g., signed, fixed-point, structs, etc.):

```ruby
system :reg do |typ|
   input :clk, :rst
   typ.input :d
   typ.output :q

   (q <= d & [~rst]*typ.width).at(clk.posedge)
end
```

In this example:

* `typ` is used as a type object (e.g., `bit[8]`, `signed[16]`, etc.).

* `typ.width` returns the number of bits associated with the type, allowing the reset mask (`[~rst] * typ.width`) to scale automatically.


---

Fourth, HDLRuby allows you to extend modules and instances after their declaration. This makes it easy to add new features without duplicating code.

Let us say you want to extend an existing `dff` module to include an inverted output (`qb`). There are three ways to do this:

1. Inheriting from a Module.

  You can define a new system that inherits from the existing `dff`:

  ```ruby
  system :dff_full, dff do
     output :qb
     qb <= ~q
  end
  ```

  This creates a new module `dff_full` that includes all the functionality of `dff`, with the additional inverted output.

2. Reopening a Module.

  You can modify the original `dff` module after its declaration using the open method:

  ```ruby
  dff.open do
     output :qb
     qb <= ~q
  end
  ```

  This approach modifies `dff` itself, and the added behavior (`qb <= ~q`) will apply to all future instances of `dff`.

 3. Reopening a Specific Instance.

  You can also modify a single instance of a module without affecting the others:

  ```ruby
  # Declare dff0 as an instance of dff
  dff :dff0
  
  # Modify it
  dff0.open do
     output :qb
     qb <= ~q
  end
  ```

  In this case, only `dff0` will have the qb inverted output. Other instances of `dff` remain unchanged.

In summary, HDLRuby supports:

* Inheritance: for creating extended modules from existing ones

* Module reopening: to modify a module after declaration

* Instance reopening: to customize individual instances

---

Fifth, HDLRuby allows you to instantiate components in groups, similar to how signals are grouped in arrays. This enables scalable and readable hardware descriptions using familiar Ruby-style iteration.


```ruby
system :shifter do |n|
   input :clk, :rst
   input :i0
   output :o0, :o0b

   dff_full :dffr

   dffr.clk <= clk

   # Instantiating n D-FF
   dff_full[n,:dffIs]

   # Connect the clock and the reset.
   dffIs.heach { |ff| ff.clk <= clk ; ff.rst <= rst }

   # Interconnect them as a shift register
   dffIs[0..-1].heach_cons(2) { |ff0,ff1| ff1.d <= ff0.q }

   # Connects the input and output of the circuit
   dffIs[0].d <= i0
   o0 <= dffIs[-1].q
   o0b <= dffIs[-1].qb
end
```

In this example:
 
* `dff_full[n, :dffIs]` creates an array of `n` instances named `dffIs`.

* `heach` iterates over each instance in parallel.

* `heach_cons(2)` creates overlapping pairs (like a sliding window) to wire the flip-flops together.

If you don¿t need a specific subcomponent like `dff_full`, you can describe the shift register more concisely using a bit vector:

```ruby
system :shifter do |n|
   input :clk, :rst
   input :i0
   output :o0
   [n].inner :sh
   
   par (clk.posedge) do
      hif(rst) { sh <= 0 }
      helse { sh <= ((sh << 1)|i0) }
   end
   
   o0 <= sh[n-1]
end
```

This version:

* Uses a single `n`-bit inner register (`sh`) to store the shift state.

* Updates the register each clock cycle, inserting `i0` at the least significant bit.

* Outputs the most significant bit (`sh[n-1]`).

---

HDLRuby supports many more advanced features that enable concise, flexible, and reusable hardware descriptions. The following examples showcase how you can use generic parameters, functional abstractions, and custom types in practice.

Suppose you want to build a circuit that computes a sum of products between several inputs and constant coefficients. For example, with four signed 16-bit inputs and coefficients 3, 4, 5, 6, a basic HDLRuby implementation looks like this:

```ruby
system :sumprod_16_3456 do
   signed[16].input :i0, :i1, :i2, :i3
   signed[16].output :o
   
   o <= i0*3 + i1*4 + i2*5 + i3*6
end
```

This works, but lacks flexibility. Changing the bit width or coefficients requires rewriting the entire module. It also becomes error-prone with large coefficient sets.

A better approach is to create a generic system:

```ruby
system :sumprod do |typ,coefs|
   typ[-coefs.size].input :ins
   typ.output :o
   
   o <= coefs.hzip(ins).hreduce(0) do |sum,(i,c)|
      sum + i*c
   end
end
```

In this version:

* `typ` defines the data type (e.g., `signed[32]`)

* `coefs` is an array of constant coefficients

* `ins` is an array of inputs with size `coefs.size`

* `[-coefs.size]` is shorthand for declaring an array indexed in the forward direction (`[0..coefs.size - 1]`)

* `hzip` pairs each input with its coefficient (like Ruby¿s `zip`)

* `hreduce` accumulates the products into a final sum (like Ruby¿s `reduce`)

This version supports any number of coefficients and any data type.
Example instantiation (with 16 coefficients):

```ruby
sumprod(signed[32], 
        [3,78,43,246, 3,67,1,8,
         47,82,99,13, 5,77,2,4]).(:my_circuit)  
```

__Note__: when passing generic arguments, the instance name (:my_circuit) goes after the parameters, in parentheses.

While the description `sumprod` is already usable in a wide range of
cases you may want to use specialized operations (e.g., saturated arithmetic) instead of standard `+` and `*`. You can do this by replacing operators with functions:

```ruby
system :sumprod_func do |typ,coefs|
   typ[-coefs.size].input :ins
   typ.output :o
   
   o <= coefs.hzip(ins).hreduce(0) do |sum,(c,i)|
      add(sum, mult(i,c))
   end
end
```

Now you define your custom `add` and `mult` functions. For example, an addition with saturation at 1000:

```ruby
hdef :add do |x,y|
   inner :res
   seq do
      res <= x + y
      hif(res > 1000) { res <= 1000 }
   end
   res
end
```

With HDLRuby functions, the value returned is the result of the last statement, here `res`.

To avoid hardcoding saturation values, functions can accept extra arguments:

```ruby
hdef :add do |max, x, y|
   inner :res
   seq do
      res <= x + y
      hif(res > max) { res <= max }
   end
   res
end
```

You would then call it like:

```ruby
add(1000,sum,mult(...))
```

However, this becomes cumbersome if your functions take inconsistent argument counts. A better approach is to pass code (lambdas or procs) as parameters:

```ruby
system :sumprod_proc do |add,mult,typ,coefs|
   typ[coefs.size].input :ins
   typ.output :o
   
   o <= coefs.hzip(ins).hreduce(0) do |sum,(c,i)|
      add.(sum, mult.(i*c))
   end
end
```

__Note__: When calling a proc in HDLRuby, use `.()` instead of regular parentheses.

Example usage:
 
```ruby
sumprod_proc( 
        proc { |x,y| add_sat(1000,x,y) },
        proc { |x,y| mult_sat(1000,x,y) },
        signed[64], 
        [3,78,43,246, 3,67,1,8,
         47,82,99,13, 5,77,2,4]).(:my_circuit)
```

This lets you reconfigure the arithmetic logic without changing the core circuit.


As second possible approach, HDLRuby also allows you to define custom data types with redefined operators: 

```
signed[16].typedef(:sat16_1000)

sat16_1000.define_operator(:+) do |x,y|
   tmp = x + y
   mux(tmp > 1000,tmp,1000)
end
```

In the code above:

* The first line defines the new type `sat16_1000` to be
16-bit signed, 

* The `define_operator` method overloads (redefines) the `+` operator
for this type.

Then use your original `sumprod` with this type:

```ruby
sumprod(sat16_1000, 
        [3,78,43,246, 3,67,1,8,
        47,82,99,13, 5,77,2,4]).(:my_circuit)
```

You can also define generic types with parameters:

```ruby
typedef :sat do |width, max|
   signed[width]
end

sat.define_operator(:+) do |width,max, x,y|
   tmp = x + y
   mux(tmp > max, tmp, max)
end
```

Now you can instantiate saturated arithmetic with custom precision and bounds:

```ruby
sumprod(sat(16,1000), 
        [3,78,43,246, 3,67,1,8,
         47,82,99,13, 5,77,2,4]).(:my_circuit)
```

__Note__: Any parameters used in a type definition must also be listed when overloading operators.


## How HDLRuby works

Unlike high-level HDLs such as SystemVerilog, VHDL, or SystemC, HDLRuby descriptions are not direct descriptions of hardware. Instead, they are Ruby programs that generate hardware descriptions.

In traditional HDLs, executing the code (e.g., in a simulator) simulates the behavior of the described circuit. In contrast, executing HDLRuby code produces a low-level hardware description, which can then be synthesized or simulated like any standard HDL.

This separation between:

* the user-facing description (written in HDLRuby), and

* the internal hardware representation (handled by `HDLRuby::Low`)

allows HDLRuby to incorporate advanced programming features¿such as iterators, generics, and metaprogramming -- without affecting the synthesizability of the resulting hardware description.

---

In HDLRuby, each construct does not directly describe hardware. Instead, it generates a hardware description. For example, consider the following line:

```ruby
   a <= b
```

This expression creates a connection from signal `b` to signal `a`. When this line is executed (remember, HDLRuby code runs as Ruby code), it generates an instance of `HDLRuby::Low::Connection` -- the internal object representing that hardware connection.

Its execution will produce the actual hardware description of this connection as an object of the `HDLRuby::Low library` in this case, an instance of the `HDLRuby::Low::Connection` class. Concretely, an HDLRuby system is described by a Ruby block, and the instantiation of this system is performed by executing this block. The actual synthesizable description of this hardware is the execution result of this instantiation.

More generally:

* an HDLRuby module (`system`) is defined using a Ruby block.

* When the module is instantiated, the block is executed.

* The result of that execution is a complete, synthesizable hardware description in the internal `HDLRuby::Low` format.

This architecture -- where Ruby is used to dynamically generate HDL constructs -- makes HDLRuby extremely flexible and expressive, while still producing valid, low-level HDL for synthesis or simulation


From here, we will begin to explore HDLRuby’s core constructs in more detail.

## Naming Rules

Several constructs in HDLRuby -- such as modules and signals -- are identified by names. These names must be specified using Ruby symbols that begin with a lowercase letter.

For example:

* `:hello` -> valid

* `:Hello` -> invalid (starts with an uppercase letter)

Once declared, the construct is referred to by the name without the colon (`:`). That is, a construct declared as `:hello` will later be referenced simply as `hello`.


## Systems and Signals

In HDLRuby, a *system* represents a digital module, similar to a module in Verilog HDL. A system includes:

* An interface (comprising `input`, `output`, and `inout` signals),

* as well as structural and behavioral descriptions of the circuit.

A signal represents a piece of state within a system. Each signal has:

* a data type, and

* a value that can change over time.

HDLRuby signals abstract both wires and registers:

* If a signal's value is explicitly assigned at all times, it behaves like a wire.

* If the value is updated conditionally or based on clocked logic, it behaves like a register.


### Declaring an Empty System

A system is declared using the `system` keyword. It must be given a name (as a Ruby symbol or string) and a block that defines its contents.

For example, the following code declares an empty system named `box`:

```ruby
system(:box) {}
```

__Notes__:

* Since this is Ruby code, the block can also be written using `do...end` syntax. In that case, parentheses around the name are optional:
 

  ```ruby
  system :box do
  end
  ```

* Although HDLRuby internally stores names as Ruby symbols, you can also use strings. For example, the following is equally valid:

  ```ruby
  system("box") {}
  ```

### Declaring a system with an interface

A system's interface defines how it communicates with the outside world. It consists of `input`, `output`, and `inout` signals, each of a specified data type.

While interface declarations can appear anywhere in the system body, it is recommended to place them at the beginning for clarity.

Interface signals are declared using the following pattern:

```ruby
<data type>.<direction> :name1, :name2, ...
```

For example, to declare a 1-bit input signal named `clk`:

```ruby
bit.input :clk
```

Since `bit` is the default data type in HDLRuby, it can be omitted:

```ruby
input :clk
```

Here is a more complete example: the following defines a simple memory module. It has:

* a 1-bit clock input (`clk`)

* a 1-bit read/write control input (`rwb`, where 1 = read, 0 = write)

* a 16-bit address input (`addr`)

* an 8-bit bidirectional data bus (`data`)

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

In this example:

* The memory content is declared as an array of `2**16` 8-bit words.

* On each rising edge of `clk`, the module either reads from or writes to memory depending on the value of `rwb`.

### Structural description in a system

In HDLRuby, structural descriptions define how subsystems (i.e., instances of other systems) are instantiated and interconnected.

To instantiate a system, use the following syntax:

```ruby
<system name> :<instance name>
```

For example, to instantiate the `mem8_16` system:

```ruby
mem8_16 :mem8_16I
```

You can also declare multiple instances at once:

```ruby
mem8_16 [:mem8_16I0, :mem8_16I1]
```

Or create an array of instances:

```ruby
mem8_16[5,:mem8_18Is] # Creates an array of 5 instances named mem8_16Is
```

To interconnect subsystems, you'll often need internal signals. These are declared using the inner direction:

```ruby
inner :w1
[1..0].inner :w2
```

If a signal is constant (i.e., its value never changes), use constant instead of inner.

When signals are declared, use the assignment operator <= to define connections:

```ruby
<destination> <= <source>
```

For example:

```ruby
ready <= w1         # Connects internal w1 to ready
w2[0] <= clk        # Assigns clk to the first bit of w2
w2[1] <= clk & rst  # Assigns AND of clk and rst to w2[1]
```

You can also refer to the ports of an instance using the dot operator:

```ruby
<instance name>.<signal name>
```

For example: 

```ruby
mem8_16I.clk <= clk
```

Alternatively, you can connect multiple ports at once using the call operator `.()` with named arguments:

```ruby
mem8_16I.(clk: clk, rwb: rwb)
```

This also allows partial connections (e.g., leaving out addr or data).
But you can also list the connections in order of port decleration:

```
mem8_16I.(clk, rwb, addr, data)
```

You can even connect ports inline at instantiation:

```ruby
mem8_16(:mem8_16I).(clk: clk, rwb: rwb)
```

The following system uses two 8-bit memory modules (mem8_16) to construct a 16-bit wide memory by splitting the data bus:

```ruby
system :mem16_16 do
   input :clk, :rwb
   [15..0].input :addr
   [15..0].inout :data

   mem8_16(:memL).(clk: clk, rwb: rwb, addr: addr, data: data[7..0])
   mem8_16(:memH).(clk: clk, rwb: rwb, addr: addr, data: data[15..8])
end
```

The same can be written using the dot operator and individual assignments:

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

In HDLRuby, output, inner, and constant signals can be initialized at the time of declaration using the following syntax:

```ruby
<signal name>: <intial value>
```

For example, the following declares a 1-bit inner signal named sig initialized to 0:

```ruby
inner sig: 0
```

The following, declares and initialize an 8-word, 8-bit ROM (read-only memory):

```ruby
bit[8][-8] rom: [ _h00,_h01,_h02,_h03,_h04,_h05,_h06,_h07 ]
```

__Notes__: 

* The notation `_hXY` represents an explicit 8-bit hexadecimal value where `X` and `Y` are hex digits (e.g., `_h0A` is an 8-bit 10).

* By default:
   
  * Ruby integers (e.g., `42`) are treated as 64-bit HDLRuby values.

  * HDLRuby literals prefixed with `_` (e.g., `_b1010`, `_h0F`) have a bit-width corresponding to their representation.

* When initializing ROM or arrays of values, make sure that the bit-width of the values matches the declared type -- otherwise, misalignments or synthesis issues may occur.


### Scope in a system

#### General scopes

HDLRuby uses scopes to control the visibility of signals and instances. Understanding scopes helps avoid naming conflicts and improves modularity and readability. As general rule:

* Interface signals (`input`, `output`, `inout`) are globally accessible from anywhere within the system where they are declared.

* Inner signals (`inner`) and instances are local to the scope in which they are declared and cannot be accessed outside of it.

A scope is a region of code where declared objects (signals, instances, etc.) are visible. Each system has its own top-level scope, and scopes can be nested.

For example, the following system has only a top-level scope:

```ruby
system :div2 do
   input :clk
   output :q
   
   inner :d, :qb
   d <= qb
   
   dff_full(:dffI).(clk: clk, d: d, q: q, qb: qb)
   
```

In this example, signals `d` and `qb` and the instance `dffI` are accessible only within system `div2`.

You can define additional inner scopes using the `sub` keyword:

```ruby
sub do
   # Local declarations and code
end
```

This is useful for organizing code or isolating declarations. Objects declared inside a sub block are not accessible outside of it.

For example, the following system includes a one-level nested scope:

```ruby
system :sys do
   ...
   sub
      inner :sig
      # sig is accessible here
   end
   # sig is not accessible here
end
```

And the following system includes two-level nested scopes:

```ruby
system :sys do
   ...
   sub
      inner :sig0
      # sig0 is accessible here
      sub
         inner :sig1
         # sig0 and sig1 are accessible here
      end
      # sig1 is not accessible here
   end
   # Neither sig0 nor sig1 are accessible here
end
```

There rules for name collisions are the following: 

* Within the same scope, you cannot declare two signals or instances with the same name.

* However, inner scopes may reuse names already declared in outer scopes. In such cases, the innermost declaration takes precedence.

#### Named scopes

You can assign a name to a scope:

```ruby
sub :<name> do
   ...
end
```

Signals and instances declared within a named scope can be accessed from outside using dot notation: `<scope_name>.<object_name>`

For example:

```ruby
sub :scop do
   inner :sig
   ...
end
...
# Access sig from outside its scope.
scop.sig <= ...
```


### Behavioral description in a system.

In HDLRuby, behavioral descriptions is done using processes which are declared using either:

* `par` for non-blocking execution (like Verilog `always` with `<=`)

* `seq` for blocking execution (like Verilog `always` with `=`)

A process consists of:

* a sensitivity list (i.e., a list of events that trigger it)

* a block of statements

The general syntax is as follows:

```ruby
par <list of events> do
   <statements>
end

seq <list of events> do
   <statements>
end
```

Each process is activated when any event in its sensitivity list occurs. An event corresponds to a change in a signal, such as:


* `posedge` -- rising edge

* `negedge` -- falling edge

* `anyedge` -- any edge (can be ommitted)

For example:

```ruby
par(clk.posedge) do
   # This block runs on every rising edge of clk
   ...
end
```

The sensitivity list is evaluated at runtime, and processes are executed once per activation.
See [Events](#events) for more details.


Statements include assingments, conditionals and blocks.
You can also declare inner signals within these statements; they will be local to the current process.
Statements are described in more detail in section [statements](#statements). In this section, we focus on assignment statements and block statements.

An assignment statement is declared using the arrow operator `<=` as follows:

```ruby
<destination> <= <source>
```

The `destination` must be a reference to a signal, and the `source` can be any expression.
An assignment has the same structure as a connection. However, its execution model is different: while a connection is continuously executed, an assignment is only executed during the execution of its block.

A block comprises a list of statements and is used to add hierarchy to a process.
Blocks can use either blocking or non-blocking assignments.
By default, a top-level block is created when declaring a process, and it inherits its execution mode. For example, in the following code, the top block uses blocking assignments:

```ruby
system :with_blocking_process do
   seq do
      <list of statements>
   end
end
```

It is possible to declare new blocks within an existing block.
To declare a sub-block with the same execution mode as its parent, use the keyword `sub`. For example, the following code declares a sub-block within a seq block, inheriting the same execution mode:

```ruby
system :with_blocking_process do
   seq do
      <list of statements>
      sub do
         <list of statements>
      end
   end
end
```

A sub-block can also use a different execution mode by explicitly using `seq` (for blocking assignments) or `par` (for non-blocking execution).
For example, the following code declares a `par` sub-block inside a `seq` block:

```ruby
system :with_par_in_seq_process do
   seq do
      <list of statements>
      par do
         <list of statements>
      end
   end
end
```

Sub-blocks have their own scope, so it is possible to declare signals without name collisions.
For example, the following code declares three different inner signals, all named `sig`:

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

To summarize this section, here is a behavioral description of a 16-bit shift register with asynchronous reset (`hif` and `helse` are keywords used for specifying hardware `if` and `else` control statements).

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

In the example above, the order of assignment statements does not matter.
However, this is not the case in the following example, which implements the same register using a `seq` block.

In this second example, placing the statement `reg[0] <= din` last would result in incorrect shift register behavior:

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

__Notes__:

* `helse seq` ensures that the block of the hardware `else` is in blocking assignment mode.

* `hif(rst)` could also have been set to blocking assignment mode as follows:
   
   ```ruby
      hif rst, seq do
         reg <= 0
      end
   ```

* Non-blocking mode can be set the same way using `par`.


### Extra Features for the Description of Processes

#### Single-Statement Processes

It often happens that a process contains only one statement.  In such cases, the description can be shortened using the `at` operator as follows:

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

For the sake of consistency, this operator can also be applied to block statements, as shown below. However, this usage is likely less readable than the standard process declaration:

```ruby
( seq do
     a <= b+1
     c <= d+2
  end ).at(clk.posedge)
```

#### Insertion of Statements at the Beginning of a Block

By default, statements in a block are added in the order in which they appear in the code. However, it is also possible to insert statements at the beginning of the current block using the `unshift` command, as follows:

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

__Note__: While this feature has little practical use for simple circuit descriptions, it can be useful in advanced generic component descriptions.


<!-- ### Reconfiguration

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
-->


## Events

Each process of a system is associated with a list of events, called a sensitivity list, that specifies when the process is to be executed. An event is associated with a signal and represents the instant when the signal reaches a given state.

There are three kinds of events:

* **Positive edge events**, which occur when a signal transitions from 0 to 1.

* **Negative edge events**, which occur when a signal transitions from 1 to 0.

* **Change events**, which occur whenever the signal changes, regardless of direction.

Events are declared directly from the signals, using the `posedge` operator for a positive edge, the `negedge` operator for a negative edge, and the `anyedge` operator for any change. For example, the following code declares 3 processes activated respectively on the positive edge, the negative edge, and any change of the `clk` signal:

```ruby
inner :clk

par(clk.posedge) do
...
end

par(clk.negedge) do
...
end

par(clk.anyedge) do
...
end
```

__Note:__ The `anyedge` keyword can be omitted.


## Statements

Statements are the basic elements of a behavioral description. They are regrouped in blocks that specify their execution mode (non-blocking or blocking assignments).
There are four kinds of statements: the assignment statement which computes expressions and sends the result to the target signals, the control statement which changes the execution flow of the process, the block statement (described earlier), and the inner signal declaration.

Statements are the fundamental elements of a behavioral description. They are grouped into blocks that specify their execution mode—either non-blocking or blocking assignments.

There are four types of statements:

* **Assignment statements**, which compute expressions and assign the results to target signals.

* **Control statements**, which alter the execution flow of a process.

* **Block statements**, which group multiple statements and were described earlier.

* **Inner signal declarations**, which define signals local to a process or block.

__Notes__: 

* A fifth type of statement, called a _time statement_, will be discussed in the [Time](#time) section.

* Unlike in other HDLs such as Verilog or VHDL, statements in this language are not restricted to processes.


### Assignment Statement

An assignment statement is written using the arrow operator `<=` within a process. Its right-hand side is the expression to be computed, and its left-hand side is a reference to the target signals (or parts of signals) -- i.e., the signals (or signal slices) that will receive the result of the computation.

For example, the following code assigns the value `3` to the signal `s0`, and assigns the sum of signals `i0` and `i1` to the first four bits of signal s1:

```ruby
s0 <= 3
s1[3..0] <= i0 + i1
```

The behavior of an assignment statement depends on the execution mode of the enclosing block:

* If the mode is non-blocking, the target signals are updated after all statements in the current block have been processed.

* If the mode is blocking, the target signals are updated immediately after the expression on the right-hand side is evaluated.


### Control Statements

There are two types of control statements in HDLRuby: the hardware if (`hif`) and the hardware case (`hcase`).

#### hif

The `hif` construct consists of a condition and a block that is executed if -- and only if -- the condition is true. It is declared as follows, where the condition can be any expression:

```ruby
hif <condition> do
   <block contents>
end
```

#### hcase

The `hcase` construct consists of an expression and a list of value-block pairs. A block is executed when its corresponding value matches the value of the `hcase` expression. It is declared as follows:

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

You can add a block that is executed when the condition of an `hif` is not met, or when no case in an hcase matches, using the `helse` keyword:

```ruby
<hif or hcase construct>
helse do
   <block contents>
end
```

#### helsif

In addition to `helse`, you can define additional conditions in an `hif` using the `helsif` keyword:

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

Outside of sequencer, HDLRuby -- like other HDLs -- does not support runtime looping constructs. It is important not to confuse constructs like Verilog's generate, which are not actual loops but rather generative code structures. Similarly, HDLRuby supports generative loops through parallel enumerators. See the [Parallel Enumerators](#parallel-enumerators) section for more information.


## Types

Each signal and expression in HDLRuby is associated with a data type that defines the kind of value it can represent. In HDLRuby, data types represent bit vectors, along with the way they should be interpreted -- i.e., as bit strings, unsigned values, signed values, or hierarchical structures.

### Type Construction

There are five basic types, `bit`, `signed`, `unsigned`, `integer`, and `float` that represent respectively single bit logical values, single-bit unsigned values, single-bit signed values, Ruby integer values, and Ruby floating-point values (double precision). The first three types are HW and support four-valued logic, whereas the two last ones are SW (but are compatible with HW) and only support Boolean logic. Ruby integers can represent any element of **Z** (the mathematical integers) and have for that purpose a variable bit-width.

There are five basic types in HDLRuby: `bit`, `signed`, `unsigned`, `integer`, and `float`. These represent, respectively:

* Single-bit logical values (`bit`)

* Single-bit unsigned values (`unsigned`), equivalent to `bit`

* Single-bit signed values (`signed`)

* Ruby integer values (`integer`)

* Ruby floating-point values in double precision (`float`), not supported for simulation or synthesis yet

The first three types are hardware types and support four-valued logic (`0`, `1`, `Z`, and `X`), while the last two are software types. Although software types are compatible with hardware types, they support only Boolean logic.

Additional types can be constructed using a combination of the following two type operators:

__The vector operator__ `[]`

This operator is used to build types that represent vectors of elements, either of a single type or a tuple of multiple types.

* A uniform vector (all elements of the same type) is declared as:

  ```ruby
  <type>[<range>]
  ```

  The `range` specifies the index of the most and least significant bits. A range such as `n..0` can also be written as `n+1`. For example, the following two declarations are equivalent:

  ```ruby
  bit[7..0]
  bit[8]
  ```

* A tuple (vector of different types) is declared using square brackets with a list of types:

  ```ruby
  [<type 0>, <type 1>, ... ]
  ```

  For example, the following defines a tuple containing an 8-bit logical value, a 16-bit signed value, and a 16-bit unsigned value:

  ```ruby
  [ bit[8], signed[16], unsigned[16] ]
  ```

__The structure operator__ `{}`

This operator defines hierarchical types made up of named subtypes. It is used as follows:

```ruby
{ <name 0>: <type 0>, <name 1>: <type 1>, ... }
```

For instance, the following defines a structure with two fields: an 8-bit `header` and a 24-bit `data`:

```ruby
{ header: bit[7..0], data: bit[23..0] }
```


### Type definition

You can assign names to type constructs using the `typedef` method:

```ruby
<type construct>.typedef :<name>
```

For example, the following code defines `char` as a signed 8-bit type:

```ruby
signed[7..0].typedef :char
```

After this, `char` can be used like any other type. For instance, the following declares an input signal `sig` of type `char`:

```ruby
char.input :sig
```

Alternatively, a new type can be defined using a block:

```ruby
typedef :<type name> do
   <code>
end
```

Where:

* `type name` is the name of the type

* `code` is a description of the content of the type

For example, the `char` type could also be defined as:

```ruby
typedef :char do
   signed[7..0]
end 
```

### Type compatibility and conversion

All HDLRuby types are ultimately based on bit vectors, where each bit can hold one of four values: `0`, `1`, `Z`, or `X`. Bit vectors are unsigned by default, but can be explicitly set to signed.

When performing operations involving signals of different bit-vector types, the shorter signal is automatically extended to match the length of the longer one, preserving its sign if it is signed.

Even though all types in HDLRuby are ultimately bit vectors, complex types can be defined. When such types are used in computational expressions or assignments, they are implicitly converted to unsigned bit vectors of equivalent size.


## Expressions

Expressions are constructs that represent values associated with types.
They include [immediate values](#immediate-values), [reference to signals](#references) and operations involving other expressions using [expression operators](#expression-operators).


### Immediate values

mmediate values in HDLRuby can represent vectors of type `bit`, `unsigned`, or `signed`, as well as `integer` or `float` numbers. They are prefixed with an underscore (`_`) and include a header indicating the vector type and the numeric base, followed by the actual number.

By default, the bit width is inferred from the length of the numeral, but it can also be explicitly specified in the header. Underscores (`_`) can be inserted anywhere within the number to improve readability—they are ignored by the parser.

__Vector type specifiers__
 
* `b`: `bit` type (can be omitted)
  
* `u`: `unsigned` type (equivalent to `b`; provided to avoid confusion with the binary base specifier)

* `s`: `signed` type (the last digit is sign-extended if required for binary, octal, or hexadecimal bases, but not for decimal)

__Base specifiers__

* `b`: binary

* `o`: octal
 
* `d`: decimal

* `h`: hexadecimal

__Examples__

All the following immediate values represent the value `100`, using different bases and types, all encoded as 8-bit values:

```ruby
_bb01100100
_b8b110_0100
_u8d100
_s8d100
_uh64
_s8o144
```
You may omit either the type specifier (default: `bit`) or the base specifier (default: binary). For example, all of the following also represent 8-bit unsigned values equal to `100`:

```ruby
_b01100100
_h64
_o144
```

__Notes__:

* The form `_01100100` was previously treated as equivalent to `_b01100100`, but due to compatibility issues with recent versions of Ruby, it is now deprecated.

* You may also use Ruby-style immediate values. Their bit width will be automatically adjusted to match the data type of the expression in which they are used. Note, however, that this adjustment may change the value. For example, in the following code, sig is assigned the value `4` (not `100`):

  ```ruby
  [3..0].inner :sig
  sig <= 100
  ```


### References

References are expressions used to designate signals or a part of signals.

The simplest reference is the name of a signal. It refers to the signal with that name in the current scope. For example, in the following code, the inner signal `sig0` is declared, and the name `sig0` then becomes a reference to that signal:

```ruby
# Declaration of signal sig0.
inner :sig0

# Access to signal sig0 using a name reference.
sig0 <= 0
```

To refer to a signal in another system, or to a sub-signal within a hierarchical signal, use the dot (`.`) operator:

```ruby
<parent name>.<signal name>
```

For instance, in the following code, the input signal `d` of system instance `dff0` is connected to the `sub0` field of the hierarchical signal `sig`:

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

The following table summarizes the operators available in HDLRuby. More details are provided in the subsequent sections for each group of operators.

__Assignment Operators (left-most operator of a statement):__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                             |
| `<=`          | Connection (outside a process)   |
| `<=`          | Assingment (inside a process)    |

__Arithmetic Operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| `+`           | Addition                      |
| `-`           | Subtraction                   |
| `*`           | Multiplication                |
| `/`           | Division                      |
| `%`           | Modulo                        |
| `**`          | Power                         |
| `+@`          | Unary plus (identity)         |
| `-@`          | Negation                      |

__Comparison Operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| `==`          | Equality                      |
| `!=`          | Inequality                    |
| `>`           | Greater than                  |
| `<`           | Less than                     |
| `>=`          | Greater than or equal         |
| `<=`          | Less than or equal            |


__Logic and Shift Operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| `&`           | Bitwise/logical AND           |
| `|`           | Bitwise/logical OR            |
| `~`           | Bitwise/logical NOT           |
| `mux`         | Multiplex                     |
| `<<`/`ls`     | Left shift                    |
| `>>`/`rs`     | Right shift                   |
| `lr`          | Left rotate                   |
| `rr`          | Right rotate                  |

__Conversion Operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| `to_bit`      | Cast to bit vector            |
| `to_unsigned` | Cast to unsigned vector       |
| `to_signed`   | Cast to signed vector         |
| `to_big`      | cast to big-endian            |
| `to_little`   | cast to little endian         |
| `reverse`     | Reverse the bit order         |
| `ljust`       | Increase width from the left, preserving the sign  |
| `rjust`       | increase width from the right, preserving the sign |
| `zext`        | zero extension (converts to unsigned if signed)    |
| `sext`        | sign extension (converts to sign if unsigned)      |

__Selection/Concatenation Operators:__

| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;symbol&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | description&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; |
| :---          | :---                          |
| `[]`          | sub-vector selection          |
| `@[]`         | concatenation operator        |
| `.`           | field selection               |


__Notes__:
 
* Operator precedence in HDLRuby follows Ruby’s operator precedence rules.

* Ruby does not allow overriding of the `&&`, `||`, or `?:` (ternary) operators, so they are not available in HDLRuby.

  - Instead of the `?:` operator, HDLRuby provides the more general mux (multiplexer) operator.

  - HDLRuby does not provide replacements for `&&` and `||`; see the [Logic and Shift Operators](#logic-and-shift-operators) section for an explanation.


#### Assignment Operators

Assignment operators can be used with any type. In HDLRuby, both connection and assignment operations are represented by the `<=` symbol.

__Note__: The first `<=` in a statement is always interpreted as an assignment operator. Any subsequent occurrences of `<=` in the same statement are interpreted as the standard less than or equal to comparison operator.

#### Arithmetic Operators

Arithmetic operators automatically convert operands to vectors of `bit`, `unsigned` or `signed` values, or to `integer`, or `float` values.  The binary arithmetic operators are `+`, `-`, `*`, `%`. The unary arithmetic operators are `+` (indentity) and `-` (negation). All behave the same way as their Ruby equivalents.

#### Comparison operators

Comparison operators return a result of either true or false. In HDLRuby, true is represented by the bit value `1`, and false by the bit value `0`.

Supported operators include: `==`, `!=`, `<`, `>`, `<=`, and `>=`. These have the same meaning as in Ruby.

__Notes__:

* The `<`, `>`, `<=` and `>=` operators automatically converts operands to one of the following types: vectors of `bit`, `unsigned` or `signed`, or `integer` or `float`.

* When comparing values of other types, they are interpreted as `unsigned` bit vectors, unless they are explicitly `signed` or `float`.
 


#### Logic and Shift Operators

__Logic Operators:__

In HDLRuby, all logic operators are bitwise. To perform Boolean logic operations, operands must be single-bit values. The bitwise logic operators are:

* Binary: `&`, `|`, `^`

* Unary: `~`

These behave the same way as their Ruby counterparts.

__Note__: There are no Boolean (`&&`, `||`) operators in HDLRuby for two reasons:

 1. Ruby does not support operator overloading for Boolean operators.

 2. In Ruby, any value other than `false` or `nil` is considered true -- an assumption valid for software, but not for hardware, where values are often bit vectors. Therefore, Boolean logic is supported only through bitwise operators on single-bit values.

__Shift Operators:__

The shift operators are `<<` (left shift) and `>>` (right shift).
These preserve the sign for `signed` types and do not change bit width. Their behavior matches that of Ruby.

The rotation operators are `rl` (left rotate) and `rr` (right rotate).
Like shifts, they preserve sign and bit width. Since Ruby lacks rotation operators, these are implemented as methods and used as follows:

```ruby
<expression>.rl(<other expression>)
<expression>.rr(<other expression>)
```

For example, to rotate the bits of signal `sig` to the left by 3 positions:

```ruby
sig.rl(3)
```

More complex shifts and rotations can also be implemented using selection and concatenation. See the [Concatenation and selection operators](#concatenation-and-selection-operators) for details. 


#### Conversion operators

The conversion operators are used to change the type of an expression.

* **Type puns**, which change the interpretation of a value without modifying its raw bit content.

* **Type casts**, which modify both the type and the underlying bit representation.

__Type Puns:__

The type pun operators include `to_bit`, `to_unsigned`, and `to_signed`. These convert an expression of any type into a vector of `bit`, `unsigned`, or `signed` elements, respectively, without altering the raw value.

For example, the following code converts a hierarchical signal into an 8-bit signed vector:

```ruby
[ up: signed[3..0], down: unsigned[3..0] ].inner :sig
sig.to_bit <= _b01010011
```

__Type Casts:__

Type cast operators change both the type and the bit representation of a value. They are used to change the bit width of vectors of type bit, signed, or unsigned.

The type cast operators include:

* `ljust`

* `rjust`

* `zext`

* `sext`

Each performs a specific form of bit-width extension:

* `ljust` and `rjust`: these operators increase the width of a bit vector by adding bits on the left (`ljust`) or right (`rjust`) side. They take two arguments: the target width and the bit value (`0` or `1`) to be added.

  Example: Extending `sig0` to 12 bits by adding `1`s on the right:

  ```ruby
  [7..0].inner :sig0
  [11..0].inner :sig1
  sig0 <= 25
  sig1 <= sig0.ljust(12,1)
  ```

* `zext`: this operator performs zero extension by adding `0`s to the most significant side, based on the endianness of the value. It takes a single argument: the desired bit width.

  Example: Extending `sig0` to 12 bits by adding `0`s on the left:

  ```ruby
  signed[7..0].inner :sig0
  [11..0].inner :sig1
  sig0 <= -120
  sig1 <= sig0.zext(12)
  ```

* `sext`: this operator performs sign extension by duplicating the most significant bit of the original value. The extension side depends on the endianness. It also takes the target bit width as an argument.

  Example: Extending `sig0` to 12 bits by duplicating the MSB on the right:

  ```ruby
  signed[0..7].inner :sig0
  [0..11].inner :sig1
  sig0 <= -120
  sig1 <= sig0.sext(12)
  ```


#### Concatenation and selection operators

Concatenation and selection in HDLRuby are performed using the `[]` operator. Its behavior depends on the argument it receives:

__Concatenation:__

When the `[]` operator takes multiple expressions as arguments, it concatenates them.

For example, the following code concatenates `sig0` and `sig1` into `sig2`:

```ruby
[3..0].inner :sig0
[7..0].inner :sig1
[11..0].inner :sig2
sig0 <= 5
sig1 <= 6
sig2 <= [sig0, sig1]
```

__Selection:__

When applied to an expression with a range as the argument, it selects the corresponding slice of bits.

If only a single bit is to be selected, a single index can be used instead.

For example, the following code selects bits 3 down to 1 from `sig0`, and bit 4 from `sig1`:

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

When there is no ambiguity, HDLRuby automatically inserts conversion operators when two types are not directly compatible. The following rules apply:

1. The bit width is adjusted to match that of the larger operand.

2. If one operand is signed, the computation is performed as signed; otherwise, it is unsigned.



## Functions

### HDLRuby Functions

Like Verilog HDL, HDLRuby provides function constructs for reusing code. Functions in HDLRuby are declared as follows:

```ruby
hdef :<function_name> do |<arguments>|
<code>
end
```

Where:

* `function_name` is the name of the function.

* `arguments` is the list of function parameters.
 
* `code` is the body of the function.

__Notes__:

* Functions have their scope, so any declaration within a function is local. It is also forbidden to declare interface signals (`input`, `output`, or `inout`) within a function.

* Like Ruby `Proc` objects, the last statement in a function is treated as its return value. For example, the following function returns `1` (and takes no arguments):

  ```ruby
  function :one { 1 }
  ```
   
* Functions can accept any type of object as an argument, including variadic arguments and code blocks. For example, the following function applies a block of code passed via `&code` to each argument passed via `*args`:

  ```ruby
  function :apply do |*args, &code|
     args.each { |arg| code.call(args) }
  end
  ```
  
  This function can be used to connect a signal to multiple others. For example, the following connects sig to `x`, `y`, and `z`:

  ```ruby
   apply(x,y,z) { |v| v <= sig }
  ```

You can invoke a function anywhere in your code using its name and passing arguments in parentheses:

```ruby
<function name>(<list of values>)
```


### Ruby functions

While HDLRuby functions are useful for reusing code, they cannot interact with the context in which they are called. For example, they cannot add interface signals or modify control structures such as `hif`. For these kinds of high-level, generic operations, you can use standard Ruby functions, which are declared as follows:

```ruby
def <function_name>(<arguments>)
   <code>
end
```
Where:

* `function_name` is the name of the function.

* `arguments` is the list of function parameters.

* `code` is the body of the function.

Ruby functions are invoked in the same way as HDLRuby functions, but they behave differently: their code is inlined directly into the location where they are called.

In addition:

* Ruby functions do not have their own scope, so any inner signals or instances declared within them are added to the enclosing object or scope where they are invoked.

For example, the following function adds an input signal `in0` to any system in which it is used:

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

As another example, the following Ruby function appends a `helse` clause of with a reset assignment to a control structure like `hif` or `hcase`:

```ruby
def too_bad
   helse { rst <= 1 }
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

__Caution:__

Ruby functions behave similarly to C macros: they offer flexibility by modifying the code in which they are invoked, but they can also introduce unexpected behavior and hard-to-debug issues if used improperly.
As a rule, **Ruby functions should be avoided unless you are building a generic library for HDLRuby**.



## Software Code

HDLRuby allows the description of hardware-software components using the program construct, which encapsulates software code and provides an interface for communication with the hardware. This interface consists of three types of components:

* **Activation events**: 1-bit signals that trigger the execution of a specific software function when they transition from `0` to `1` (for positive events) or from `1` to `0` (for negative events).

* **Read ports**: Bit-vector signals that can be read from within a software function.

* **Write ports**: Bit-vector signals that can be written from within a software function.

__Note:__ A single signal can be used simultaneously as both a read and a write port in multiple contexts. However, from the software perspective, it will appear as two separate ports—one for reading and one for writing.


### Declaring a Software Component

A software component is declared similarly to a hardware process, within a system block. The syntax is as follows:

```ruby
program(<programming_language>, <function_name>) do
   # location of the software files and description of its interface
end
```

In this declaration:

* `programming_language` is a symbol indicating the language used for the software. Currently supported options are:

  * `:ruby` -- for programs written in Ruby.

  * `:c` --  for programs written in C. (In fact, any language that can be compiled into a shared library linkable with C is supported.)

* `function_name` is the name of the software function that is executed when an activation event occurs. Only one such function can be specified per program, but multiple programs can be declared within the same module.

* `location of the software files and description of its interface` may include the following declarations:

  * `actport <list of events>` -- Declares the events that activate the program (i.e., trigger execution of the program’s start function).

  * `inport <port_name: signal>` -- Declares input ports that can be read by the software.

  * `outport <port_name: signal>` -- Declares output ports that the software can write to.

  * `code <list_of_filenames>` -- Specifies the software source file(s).

__Example:__

The following example declares a program in Ruby with a start function named `echo`. The program is triggered on the positive edge of signal `req`, reads from signal `count` through port `inP`, and writes to signal `val` through port `outP`. The software code is located in the file `echo.rb`:

```ruby
system :my_system do
   inner :req
   [8].inner :count, :val
 
   ...

   program(:ruby,'echo') do
      actport req.posedge
      inport  inP:  count
      outport outP: val
      code "echo.rb"
   end
end
```


__Notes:__ 

* The bit width of an input or output port matches that of the signal it is connected to. From the software perspective, however, all port values are converted to the C type `long long`.

* If the language is Ruby, the `code` section can use a Ruby `Proc` objecct in place of a file name.



### About the Software Code Used in HDLRuby Programs

#### Location and Format of the Files

The filenames specified in the `code` declaration must indicate paths relative to the directory where the HDLRuby tools are run.

In the earlier example, this means that the `echo.rb` file must be located in the same directory as the HDLRuby description. If the source file were placed in a `ruby/` subdirectory instead, the declaration would be:

```ruby
   code "ruby/echo.rb"
```

For Ruby programs, you may declare multiple source files, and plain Ruby code can be used as-is without any compilation.

For C programs, however, the code must first be compiled, and the code declaration must refer to the resulting compiled file (not the source). For instance, if the echo function were implemented in C, the declaration would be:

```ruby
   program(:c, :echo) do
      actport req.posedge
      inport  inP:  count
      outport outP: val
      code "echo"
   end
```

To make this work, you must compile the C code into a file named echo.

__Note__: The file extension is intentionally omitted so that the system can automatically detect the appropriate format (e.g., .so for a shared library on Linux).


#### The hardware Interface

From the software point of view, the hardware interface consists only of a list of ports that can either be read or written. However, the implementation of this interface depends on the language.

##### For Ruby

In Ruby, the hardware interface is accessed by requiring the rubyHDL library. This library provides the RubyHDL module, which exposes the program's ports as module-level accessors.

For example, the following Ruby function reads from the `inP` port and writes the result to the `outP` port:

```ruby
require 'rubyHDL'

def echo
   val = RubyHDL.inP
   RubyHDL.outP = val
end
```

__Note:__ As long as a port has been declared in the HDLRuby description of the program, it will automatically be accessible in the software via the `RubyHDL` module. No additional declarations or configuration are required.


##### For C

In C (and other C-compatible compiled languages), the interface is accessed by including the `cHDL.h` header file. This file must be generated using the following command:

```bash
hdrcc --ch <destination_project>
```

Here, `destination_project` is the folder where the C source code is located.

The generated header provides the following interface functions:

* `void* c_get_port(const char* name)`: Returns a pointer to the port with the specified name.

* `int c_read_port(void* port)`: Reads the value from the given port pointer.

* `int c_write_port(void* port, int val)`: Writes the value `val` to the specified port pointer.

Here is an example program that reads from port `inP` and writes the result to port `outP`:

```c
#include "cHDL.h"

void echo() {
   void* inP = c_get_port("inP");
   void* outP = c_get_port("outP");
   int val;
   
   val = c_read_port(inP);
   c_write_port(outP,val);
}
```

__Notes:__

* The hdrcc command not only generates the C header (cHDL.h) but also creates additional files to assist in compiling the C source code. See [compile for simulation](#compiling-the-c-code) for details.

* **Important for Windows:** Functions used as HDLRuby entry points must be declared with the `__declspec(dllexport)` prefix. If this is missing, the simulation will not work properly. For example, the echo function on Windows must be declared as:

  ```c
  #include "cHDL.h"
  
  __declspec(dllexport) void echo() {
     void* inP = c_get_port("inP");
     void* outP = c_get_port("outP");
     int val;
     
     val = c_read_port(inP);
     c_write_port(outP,val);
  }
  ```


#### Hardware-software co-simulation

As long as your programs a correctly described and the software files provided (and compiled in the case of C), the hardware-software co-simulation will be automatically performed when executing the HDLRuby simulator.

##### Compiling the C code

While Ruby programs can be used directly, C programs must be compiled into a shared library before they can be simulated.

To do this, you must generate the necessary files -- most importantly, the hardware interface header `cHDL.h`. This is done using the following HDLRuby command:

```bash
hdrcc --ch <destination_project>
```

Here, `<destination_project>` refers to both the directory where the C code resides and the name of the resulting shared library.

For example, to prepare a project located in the `echo` directory, you would run:

```bash
hdrcc --ch echo
```

This command will create a directory named echo containing the cHDL.h file and supporting files.

Next:

1. Place your C source files (e.g., `echo.c`) into the `echo` directory.

2. Change into that directory and compile the C code.

If you prefer to compile manually (e.g., without relying on Ruby tools), you can use a standard command like the following (on Linux):

```bash
gcc -shared -fPIC -undefined dynamic_lookup  -o c_program.so echo.c
```

This compiles a single-file project into a shared object file suitable for simulation.

Alternatively, if you want a simpler and more portable option, you can use Ruby's `rake-compiler`. First install it:

```bash
gem install rake-compiler
```

Then, from within the `echo` directory, run:

```bash
rake compile
```

The `rake` tool will automatically handle the compilation process across different platforms.



#### Hardware Generation

At its current stage, HDLRuby generates only the hardware portion of a design. For example, when generating Verilog, any `program` constructs are ignored. It is the user's responsibility to provide additional infrastructure to implement the hardware-software interface.

This limitation exists because such interfaces are target-specific, and often rely on licensed IP or proprietary components that cannot be integrated directly into HDLRuby.

However, this is not as restrictive as it may seem: you can still write `program` constructs that wrap access to such hardware interfaces, enabling you to reuse your HDLRuby and software code directly in your target system.

For an example, see the tutorial section: [7.6. hardware-software co-synthesis](tuto/tutorial_sw.md#7-6-hardware-software-co-synthesis).


### Extended co-simulation

Since HDLRuby programs can support any compiled software, they can be used to execute arbitrary applications -- not just software targeting the main system CPU. For example, peripheral devices such as a keyboard or monitor can be modeled using HDLRuby programs. This approach is illustrated in the HDLRuby sample `with_program_ruby_cpu.rb`.


### Development board simulation graphical interface

HDLRuby provides a web-based graphical user interface (GUI) for simulating hardware-software systems. This GUI acts as an extension of the co-design platform and is declared within a module using the `board` construct:

```ruby
board(:<board_name>,<server_port>) do
  actport <event>
  <GUI description>
end
```

Where:

* `board_name` is the name of the board.

* `server_port` is the port number used to access the GUI (default: 8000).

* `event` is the signal event (e.g., a clock's rising edge) that synchronizes the GUI with the simulator.

__GUI Elements:__

The GUI description consists of a list of visual or hidden elements. Active elements must be named and linked to HDLRuby signals using the format:

```ruby
<element> <element_name>: <HDLRuby_signal>
```

Supported elements include:

* `sw`: A set of slide switches (bit-width matches the signal).

* `bt`: A set of push buttons (bit-width matches the signal).

* `slider`: A horizontal slider for numeric input.

* `text`: A text input field. The value is interpreted as a Ruby expression. All display objects (e.g., `leds`) can be referenced as variables.

* `hook`: Attaches a signal without displaying it. Useful for referencing in `text` fields.

* `led`: A set of LEDs (bit-width matches the signal).

* `hexa`: A hexadecimal display. The width adjusts to the signal's range.

* `digit`: A decimal display. Width is based on the signal's numeric range.

* `scope`: An oscilloscope-like display. Vertical axis reflects signal values; horizontal axis shows GUI synchronization steps.

* `row`: Inserts a new line in the GUI layout.

__Example: Adder Interface with GUI:__

The following example creates a GUI for an adder system with 8-bit input signals `x` and `y`, and an output signal `z` displayed using LEDs, a numeric display, and an oscilloscope:

```ruby
system :adder_with_gui do
  [8].inner :x, :y, :z
  
  z <= x + y

  inner :gui_sync
  
  board(:adder_gui) do
    actport gui_sync.posedge
    sw x: x
    sw y: y
    row
    led z_led: z
    digit z_digit: z
    row
    scope z_scope: z
  end

  timed do
    clk <= 0
    repeat(10000) do
      !10.ns
      clk <= ~clk
    end
  end
end
```

This code defines a GUI with:

* Two sets of slide switches for inputs `x` and `y` (first row),

* A set of LEDs and a decimal display for output `z` (second row),

* An oscilloscope displaying the evolution of `z` over time (third row).

__Running the Simulation:__

You can simulate this design as you would any HDLRuby system. The following command runs the simulation and generates a VCD waveform file:

```bash
hdrcc --sim --vcd my_adder.rb my_adder
```

When this command is executed, the simulator will wait for a web browser to connect before starting. To launch the GUI, open a browser and navigate to:

```
http://localhost:8000
```

Once connected, the simulation will begin, and you can interact with the design through the GUI.


## Time

### Time Values

In HDLRuby, time values can be created using the following time suffix operators:

* `s` for seconds.

* `ms` for milliseconds.

* `us` for microseconds.

* `ns` for nanoseconds.

* `ps` for picoseconds.

For example, all of the following expressions represent one second:

```ruby
1.s
1000.ms
1000000.us
1000000000.ns
1000000000000.ps
```


### Time Processs and Time Statements

Like other HDLs, HDLRuby provides specific statements to model the passage of time. These statements are not synthesizable and are intended for simulation only, such as modeling a hardware component’s environment.

To improve clarity and avoid confusion, time-based statements are only allowed in explicitly non-synthesizable processes declared using the `timed` keyword:

```ruby
timed do
   <statements>
end
```

A time process has no sensitivity list but can include any statements allowed in a standard process, plus time-specific statements.

There are two such time statements:

* `wait` statement: this statement blocks the execution of the process for the specified amount of time. For example:

  ```ruby
     wait(10.ns)
  ```

  This can also be abbreviated using the `!` operator:
   
  ```ruby
     !10.ns
  ```

* `repeat` statement: This statement repeats a block of code for a specified number of iterations. For example, the following toggles the `clk` signal every 10 nanoseconds, repeating 10 times:

   ```ruby
      repeat(10) do 
         !10.ns
         clk <= ~clk
      end
   ```

__Note:__ These time statements are not synthesizable and can only be used within `timed` processes.

### Non-Blocking and Blocking Execution

Time processes use blocking assignments by default, but both blocking and non-blocking assignment blocks can be used inside them.

The execution semantic is:

* Blocking assignment blocks are executed sequentially.

* Non-blocking assignment blocks are executed in a semi-parallel manner, based on the following rules:

  1. Statements are grouped in sequence until a time statement is encountered.

  2. The grouped blocks are executed in parallel.

  3. The time statement is executed.

  4. Execution resumes with the next group of statements.



## High-Level Programming Features

### Generating Hardware RTL Code in HDLRuby

Since HDLRuby is built on top of Ruby, you can freely use standard Ruby constructs (such as classes, methods, and modules) without any compatibility issues. Additionally, this Ruby code does not interfere with the synthesizability of the resulting hardware design. In fact, Ruby logic can be used to generate HDLRuby constructs at compile time.

However, pure Ruby code does not interact with the HDLRuby name stack, and its misuse may lead to unintended states during compilation. Unless you're intentionally extending HDLRuby itself, it is recommended to avoid low-level Ruby generation logic for general-purpose hardware generation.

Instead, you should prefer HDLRuby’s high-level hardware generation features, which are safer and clearer—similar to Verilog’s `generate` construct. These include:

* Generic programming (explained in the next section)

* Parallel statements like `hif` or `hcase`

* Parallel enumerators (see [Parallel Enumerators](#parallel-enumerators))

These constructs can be used anywhere in the code without restriction and are generally sufficient for most hardware generation needs.

__Example: Conditional Hardware Generation__

The `hif` and `hcase` statements can be used to generate conditional logic. For instance, the following code generates either a clocked process or a continuous one depending on the value of the `clocked` flag:

```
hif(clocked) do
   par(clk.posedge) { ... }
helse
   par { ... }
end
```


### Generic Programming

#### Declaring

##### Declaring Generic Modules

Modules can be declared with generic parameters using the following syntax:

```ruby
system :<system_name> do |<list_of_generic_parameters>|
   ...
end
```

For example, the following code defines an empty module with two generic parameters named `a` and `b`:

```ruby
system(:nothing) { |a,b| }
```

Generic parameters in HDLRuby can be anything: values, data types, signals, modules, Ruby variables, and more.

__Example: Using Generics for Type, Range, and Module__

The following example demonstrates a module with:

* `t`: a generic type used for an input signal

* `w`: a bit range used for an output signal

* `s`: a generic module used to create an instance

```ruby
system :something do |t,w,s|
   t.input :isig
   [w].output :osig

   s :sI.(i: isig, o: osig)
end
```

In this example:

* `t.input :isig` declares an input of type `t`

* `[w].output :osig` declares an output with bit-width or range `w`

* `s :sI.(...)` instantiates module `s` and connects its ports

__Variadic Generic Parameters__

You can declare a module with a variable number of generic parameters using Ruby’s splat operator (`*`). The parameters are collected into an array.

```ruby
system(:variadic) { |*args| }
```

Here, `args` is an array containing any number of arguments.

##### Declaring generic types

Data types can be declared with generic parameters as follows:

```ruby
typedef :<type_name> do |<list_of_generic_parameters>|
   ...
end
```

For example, the following code defines a bit-vector type with a generic bit width parameter `width`:

```ruby
type(:bitvec) { |width| bit[width] }
```

As with modules, the generic parameters of types can be any kind of object. It is also possible to use variadic arguments.


#### Specializing

##### Specializing Generic Modules

A generic module is specialized by invoking its name and passing values for its generic arguments, as shown below:

```ruby
<module_name>(<generic_argument_values_list>)
```

If fewer values are provided than the number of generic arguments, the module is partially specialized. However, only a fully specialized module can be instantiated.

A specialized module can also be used for inheritance. For example, assuming the module `sys` has two generic arguments, it can be specialized and used to build the module `subsys` as follows:

```ruby
system :subsys, sys(1,2) do
   ...
end
```

This kind of inheritance can only be performed with fully specialized modules. For partially specialized modules, include must be used instead. For example, if `sys` is specialized with only one value, it can be used in the generic module `subsys_gen` as follows:


```ruby
system :subsys_gen do |param|
   include sys(1,param)
   ...
end
```

__Note:__ In the example above, the generic parameter `param` of `subsys_gen` is used to specialize the module `sys`.


##### Specializing Generic Types

A generic type is specialized by invoking its name and passing values corresponding to the generic arguments, as follows:

```ruby
<type_name>(<generic_argument_values_list>)
```

If fewer values are provided than the number of generic arguments, the type is partially specialized. However, only a fully specialized type can be used for declaring signals.

<!--
##### Use of Signals as Generic Parameters

Signals passed as generic arguments to modules can be used to create generic connections within the module instance. To do this, the generic argument must be declared as an `input`, `output`, or `inout` port in the body of the module, as shown below:

```ruby
system :<system_name> do |sig|
   sig.input :my_sig
   ...
end
```

In the example above, `sig` is a generic argument assumed to be a signal. The second line declares the port to which `sig` will be connected when the module is instantiated. After this declaration, the port `my_sig` can be used like any other port in the module.

```ruby
system_name(some_sig) :<instance_name>
```

Here, `some_sig` is a signal available in the current context. This instantiation automatically connects `some_sig` to the instance.
-->


### Inheritance

#### Basics

In HDLRuby, a module can inherit from one or more parent modules using the `include` command, as shown:

```ruby
   include <list_of_modules>
```

This `include` can be placed anywhere within the body of a module. However, the inherited content will only be accessible after the `include` statement is executed.

For example, the following code first defines a simple D flip-flop (`dff`) and then uses it to define a flip-flop with an additional inverted output (`qb`):

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

It is also possible to declare inheritance in a more object-oriented style by listing the parent modules immediately after the module name, as follows:

```ruby
system :<new_module_name>, <list_of_parent_modules> do
   # Additional module code
end
```

For example, the following code provides an alternative way to define `dff_full`:

```ruby
system :dff_full, dff do
   output :qb

   qb <= ~q
end
```

__Note__: From an implementation perspective, HDLRuby modules behave more like Ruby mixins than traditional class-based inheritance. Internally, modules are treated as sets of methods used to access constructs such as signals and instances.


#### About Inner Signals and Module Instances

By default, inner signals and instances defined in a parent module are not accessible in child modules. To expose them, use the `export` keyword:

```ruby
   export <symbol_0>, <symbol_1>, ...
```

For example, the following code exports signals `clk` and `rst`, and the instance `dff0` from the module `exporter`, making them accessible in its child module `importer`:

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

__Notes__ `export` accepts symbols or strings representing the names of the components to export -- not references to them.

For example, the following code is invalid:

```ruby
system :exporter do
   input :d
   inner :clk, :rst

   dff(:dff0).(clk: clk, rst: rst, d: d)

   export clk, rst, dff0 
end
```

#### Conflicts when Inheriting

Signals and instances cannot be overridden, including those inherited from parent modules. For example, the following code is invalid because the signal `rst` is already defined in `dff`:

```ruby
   system :dff_bad, dff do
      input :rst
   end
```

#### Shadowed signals and instances

In HDLRuby, it is possible to declare a signal or instance in a child module with the same name as one from an included module. When this happens, the construct from the parent module becomes shadowed -- it still exists but is no longer directly accessible, even if exported.

To access a shadowed signal or instance, you must reinterpret the current module as the parent using the `as` operator:

```ruby
   as(<parent_module)
```

For example, in the code below, the signal `db` defined in `dff_shadow` shadows the one from `dff_db`. The original `db` can still be accessed using the as operator:

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



### Opening a Module

HDLRuby allows you to continue the definition of a module after it has already been declared by using the `open` method, as shown below:

```ruby
<module>.open do
   # Additional description for the module
end
```

For example, the module `dff`, which describes a D flip-flop, can be extended to include an inverted output as follows:

```ruby
dff.open do
   output :qb

   qb <= ~q
end
```


### Opening an Instance

When a modification is required for a specific instance, it may be preferable to modify only that instance rather than creating a new module derived from the original. To do this, you can open the instance for modification using the following syntax:

```ruby
<instance_name>.open do
   # Additional description for the instance
end
```

For example, an instance of the previously defined `dff` module can be extended to include an inverted output as follows:

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


### Overloading Operators

Operators can be overloaded for specific types. This allows, for example, seamless support for fixed-point computations without requiring explicit adjustment of the decimal point position.

An operator is redefined as follows:

```ruby
<type>.define_operator(:<op>) do |<args>|
   # Operation description
end
```

Where:

* `type` is the type from which the operator is overloaded.

* `op` is the operator being overloaded (e.g., `+`).

* `args` are the arguments of the operation.

* `operation description` is an HDLRuby expression defining the new behavior of the operator.

__Example: Fixed-Point Type__

Suppose `fix32` is a 32-bit fixed-point type with the decimal point at bit 16, defined as follows:

```ruby
signed[31..0].typedef(:fix32)
```

You can overload the multiplication operator to maintain correct decimal alignment as follows:

```ruby
fix32.define_operator(:*) do |left,right|
   (left.as(signed[31..0]) * right) >> 16
end
```

__Note:__ In the example above, `left` is explicitly cast to a plain signed bit-vector to prevent infinite recursive calls to the overloaded * operator.

__Overloading with Generic Types__

Operators can also be overloaded for generic types. In this case, the generic parameters must be included in the block parameters of the overloaded operator.

For example, consider a generic fixed-point type where the decimal point is set at half the bit width:

```ruby
typedef(:fixed) do |width|
   signed[(width-1)..0]
end
```

You can overload the multiplication operator for this type as follows:

```ruby
fixed.define_operator do |width,left,right|
   (left.as(signed[(width-1)..0]) * right) >> width/2
end
```

### Predicate and Access Methods

HDLRuby provides several predicate and access methods to retrieve information about the current state of the hardware description.

| predicate name | predicate type | predicate meaning                          |
| :---           | :---           | :---                                       |
| `is_block?`    | bit            | Returns 1 if currently inside a block.           |
| `is_par?`      | bit            | Returns 1 if the current block is non-blocking.|
| `is_seq?`      | bit            | Returns 1 if the current block is blocking.|
| `is_clocked?`  | bit            | Returns 1 if the current process is clocked (i.e., triggered by a single rising or falling edge of a signal). |
| `cur_block`    | block          | Returns the current block.         |
| `cur_behavior` | process        | Returns the current process (behavior). |
| `cur_systemT`  | system         | Returns the current module (system).  |
| `top_block  `  | block          | Returns the top block of the current process. |
| `parent`       | any            | Returns the parent construct. |

__Enumerators__

HDLRuby also provides enumerators for accessing internal elements of the current construct in its current state:

| enumerator name   | accessed elements                    |
| :---              | :---                                 |
| `each_input`      | Iterates over the input signals of the current system.  |
| `each_output`     | Iterates over the output signals of the current system. |
| `each_inout`      | Iterates over the inout signals of the current system.  |
| `each_behavior`   | Iterates over the processes (behaviors) of the current system.      |
| `each_event`      | Iterates over the events of the current process.       |
| `each_block`      | Iterates over the blocks of the current process.       |
| `each_statement`  | Iterates over the statements in the current block.     |
| `each_inner`      | Iterates over the inner signals of the current block (or of the system if not inside a block). |


### Defining and Executing Ruby Methods within HDLRuby Constructs

As with any Ruby program, it is possible to define and execute methods anywhere in HDLRuby using standard Ruby syntax. When a method is defined, it is attached to the enclosing HDLRuby construct. For example:

* If a method is defined within a module declaration, it can only be used inside that module.

* If a method is defined outside of any construct, it can be used throughout the HDLRuby description.

A method can include HDLRuby code, in which case the resulting hardware description is appended to the current construct. For example, the following code connects `sig0` to Psig1` within the module `sys0`, and assigns `sig0` to `sig1` within the process of `sys1`:

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

__Warnings__:

* In the example above, the semantics of some_arrow change depending on the context in which it is called:

  * Within a module: interpreted as a static connection.

  * Within a process: interpreted as a behavioral assignment.

* Using Ruby methods to describe hardware can lead to fragile or incorrect code if not used carefully. For example, consider the following:1

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

  In this case:

  * `sys0` works correctly. 

  * `sys1` raises an error due to redeclaration of `in0`.

  * `sys2` raises an error because `input` declarations are not allowed inside a process.

__Using Ruby Method Features__

Ruby methods in HDLRuby support all standard Ruby features, including:

* Variadic arguments (`*args`)

* Named (keyword) arguments

* Block arguments (`&block`)

For example, the following method connects a single driver signal to multiple targets:

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

<!--
__Higher-Order Hardware Behavior with Blocks__

While caution is needed, properly designed methods can greatly enhance code reuse and clarity. For example, the following method executes a block of hardware description after a specified number of clock cycles:

```ruby
def after(cycles, rst, &code)
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

Explanation:

* `sub` ensures that the signal `count` is locally scoped and avoids name collisions.

* `instance_eval(&code)` executes the given block in the current context, preserving signal and instance visibility.

Using the after method, the following example turns an LED on after 1,000,000 clock cycles:

```ruby
system :led_after do
   output :led
   input :clk, :rst

   par(clk.posedge) do
      (led <= 0).hif(rst)
      after(100000,rst) { led <= 1 }
   end
end
```

__Note__: 

 * Ruby closures apply in HDLRuby. The block passed to after can use local signals and instances.

 * Signals declared within the method will not clash with existing ones in the calling context.

-->


## Extending HDLRuby

Like any Ruby-based framework, HDLRuby constructs can be dynamically extended. While modifying their internal structure is generally discouraged, it is possible -- and sometimes useful -- to add methods to existing classes for customization and extension.

### Extending HDLRuby Constructs Globally

A global extension refers to the traditional Ruby technique of *monkey patching*, where new methods are added to an existing class. For example, you can add a method that returns the number of interface signals (inputs, outputs, and inouts) of a module instance as follows:

```ruby
class SystemI
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

Once defined, the `interface_size` method can be used on any module instance:

```ruby
   <module_instance>.interface_size
```

The following table shows the HDLRuby class associated with each core construct:

| construct                   | class          |
| :---                        | :---           |
| Data type                   | `Type`         |
| Module (system)             | `SystemT`      |
| Scope                       | `Scope`        |
| Module instance             | `SystemI`      |
| Signal                      | `Signal`       |
| Connection                  | `Connection`   |
| Process (`par`, `seq`)      | `Behavior`     |
| Time process (`timed`)      | `TimeBehavior` |
| Event                       | `Event`        |
| Block (`par`, `seq`, `sub`) | `Block`        |
| Assignment                  | `Transmit`     |
| Conditional (`hif`)         | If             |
| Case (`hcase`)              | Case           |
| Program  (`program`)        | Program        |


### Extending HDLRuby Constructs Locally

A local extension of an HDLRuby construct means that only the targeted construct is modified, while all other constructs of the same type remain unaffected. This is accomplished in Ruby by accessing the construct's *eigenclass* using the `singleton_class` method and then modifying it via `class_eval`.

__Local Extension of a Specific Module__

In the following example, only the module `dff` is extended with the `interface_size` method:

```ruby
dff.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

After this extension, only `dff` responds to `interface_size`; other modules remain unchanged.

__Local Extension of a Specific Instance__

Similarly, you can extend a single instance of a module. In this example, only the instance `dff0` gains the `interface_size` method:

```ruby
dff :dff0

dff0.singleton_class.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

Other instances of the same module will not be affected.

__Local Extension of All Instances of a Module__

To extend all instances of a particular module, use the `singleton_instance` method instead of `singleton_class`. For example:

```ruby
dff.singleton_instance.class_eval do
   def interface_size
      return each_input.size + each_output.size + each_inout.size
   end
end
```

Now, any instance of the `dff` module will respond to the `interface_size` method.


### Modifying the Generation Behavior

The primary purpose of supporting global and local extensions for HDLRuby constructs is to allow users to customize and control the hardware generation process. This is especially useful when implementing synthesis algorithms tailored to specific types of modules.

For example, suppose you want to implement a generation algorithm for a category of modules. You can define an abstract module -- one without hardware content -- that holds the generation logic:

```ruby
system(:my_base) {}

my_base.singleton_instance.class_eval do
   def my_generation
      <some code>
   end
end
```

When the module `my_base` is used as a parent (i.e., included in another module), the child module inherits the `my_generation` method. For example:

```ruby
system :some_system, my_base do
   # Some system description
end
```

__Generation Invocation__

To use the custom generation logic before converting to a low-level hardware description, you would typically write:

```ruby
some_system :instance0
instance0.my_generation
low = instance0.to_low
```

However, this manual invocation can be avoided by overriding the `to_low` method to automatically include the generation step:

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

With this modification, calling `to_low` on any instance of a module that inherits from my_base will automatically execute my_generation beforehand:

```ruby
some_system :instance0
low = instance0.to_low  # Automatically runs my_generation
```




# Standard Libraries

The standard libraries are included in the `Std` Ruby module.
They can be loaded as follows, where `library_name` is the name of the library:


```ruby
require 'std/<library_name>' 
```

After loading a library, you must include the `Std` Ruby module as follows:

```ruby
include HDLRuby::High::Std
```

> However, `hdrcc` loads the stable components of the standard library by default, so you do not need to require or include anything additional to use them.

As of the current version, the stable components are:
  
* `std/clocks.rb`  

* `std/fixpoint.rb`  

* `std/decoder.rb`  

* `std/fsm.rb`  

* `std/sequencer.rb`  

* `std/sequencer_sync.rb`

* `std/hruby_enum.rb`



## Clocks

The `clocks` library provides utilities to simplify clock synchronization handling.

It allows you to multiply an event by an integer. The result is a new event whose frequency is divided by the integer multiplier.

For example, the following code describes a D flip-flop that captures data every three clock cycles:

```ruby
system :dff_slow do
   input :clk, :rst
   input :d
   output :q

   ( q <= d & ~rst ).at(clk.posedge * 3)
end
```

__Note__: This library automatically generates the RTL code required to implement the frequency division circuitry. 

<!--
## Counters
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

This statement can be used inside a clocked process where the clock event of the process is used for the counter unless specified otherwise. 

The second construct is the `before` statement that activates a block until a given number of clock cycles is passed. Its syntax and usage are identical to the `after` statement.
-->

## Decoder

The decoder library provides a new set of control statements for easily describing instruction decoders.

A decoder can be declared anywhere within a module definition using the `decoder` keyword, as shown below:

```ruby
decoder(<signal>) <block>
```

Here, `signal` is the signal to decode, and `block` is a procedure block (i.e., a Ruby proc) that defines the decoding behavior. This block can contain any code normally allowed in a standard process, and it also supports the special `entry` statement.

The `entry` statement defines a bit-pattern to match and the corresponding action to perform when the signal matches that pattern. Its syntax is:

```ruby
entry(<pattern>) <block>
```

* `pattern` is a string that defines the bit pattern to match.

* `block` is a procedure block (HDLRuby code) specifying the actions to execute when the pattern matches.

The pattern string can include:

* `0` and `1` characters to match fixed bit values.

* Alphabetical characters to define named fields within the pattern.

These named fields can be used as variables in the action block. If the same letter appears multiple times in the pattern, the corresponding bits are concatenated to form a multi-bit signal.

For example, the following code defines a decoder for the signal ir with two entries:

* The first entry sums fields `x` and `y` and assigns the result to signal `s`.

* The second entry sums fields `x`, `y`, and `z` and assigns the result to `s`.

```ruby
decoder(ir) do
   entry("000xx0yy") { s <= x + y }
   entry("10zxxzyy") { s <= x + y + z }
end
```

Note that field bits do not need to be contiguous. For example, field `z` in the second entry spans non-adjacent bits.


## FSM

The fsm library provides a set of control statements for easily describing finite state machines (FSMs).

An FSM can be declared anywhere in a module, provided it is outside any process, using the `fsm` keyword:

```ruby
fsm(<event>,<reset>,<mode>) <block>
```

Where:

* `event` is the event (e.g., rising or falling edge of a signal) that triggers state transitions.

* `reset` is the reset signal.

* `mode` is the default execution mode of the FSM, either `:sync` (synchronous/Moore) or `:async` (asynchronous/Mealy).

* `block` is a procedure block that defines the FSM's states and transitions.

__Defining States__

FSM states are declared with the following syntax:

```ruby
<kind>(<name>) <block>
```

Where:

* `kind` is the type of state (reset, state, sync, or async).

* `name` is he state name (as a symbol).

* `block` is the actions to execute when the FSM is in that state.

The available state kinds are:

* `reset`: The state entered when the FSM is reset.

  * If name is `:sync`, the reset is forced to be synchronous.

  * If name is `:async`, the reset is forced to be asynchronous.

  * If name is omitted, the mode defaults to that of the FSM.

* `state`: A regular state that follows the FSM’s default mode.

* `sync`: A state that is always synchronous, regardless of the FSM mode.

* `async`: A state that is always asynchronous, regardless of the FSM mode.

__Default Actions__

You can define actions that run in every state using the `default` statement:

```ruby
default <block>
```

This block will execute alongside the states' block.

__State Transitions__

By default, state transitions follow the order in which the states are declared. When the last state is reached, the next transition loops back to the first state -- unless otherwise specified.

To define specific transitions, use the `goto` statement at the end of a state's action block:

```ruby
goto(<condition>,<names>)
```

Where:

* `condition`: A signal whose value is used as an index.

* `names`: A list of target states. The condition’s value selects one of them by index.

For example:

```ruby
goto(cond,:st_a,:st_b,:st_c)
```

This means:

* If `cond == 0`, transition to `st_a`

* If `cond == 1`, transition to `st_b`

* If `cond == 2`, transition to `st_c`

* Otherwise, this `goto` is ignored

Multiple `goto` statements can be used in the same block. If more than one is taken, the last matching one takes precedence.

If no `goto` is taken, the FSM continues with the next declared state.

For example, the following code describes an FSM describing a circuit that checks if two buttons (`but_a` and `but_b`) are pressed and released in sequence for activating an output signal (`ok`):

__Example__

The following example defines an FSM that detects a sequence of button presses (`but_a` followed by `but_b`) and sets the output ok accordingly:

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

__About Goto Behavior__

`goto` statements are global within a state. Their position in the block does not affect execution order. For example, both of the following result in an unconditional transition to `:st_a`:

```ruby
   state(:st_0) do
      goto(:st_a)
   end
   state(:st_1) do
      hif(cond) { goto(:st_a) }
   end
```

However, to make the transition conditional, write:

```ruby
   state(:st_1) do
      goto(cond,:st_a)
   end
```

__Static FSM Mode__

While `goto` simplifies FSM design in most cases, sometimes finer control is needed. You can configure the FSM in `:static` mode, where transitions are explicitly defined using `next_state` statements.

To enable static mode, use `:static` as the FSM's execution mode:

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

In this mode, each state explicitly defines its next state(s), allowing precise transition logic.


## Parallel Enumerators

HDLRuby parallel enumerators are objects used to generate hardware processes that operate on series of signals in parallel.

They are created using the `heach` method on parallel enumerable objects.

__Parallel Enumerable Objects__

Parallel enumerable objects include:

* Arrays of signals

* Ranges

* Expressions (enumerating on each bit)

You can generate a parallel enumerable object from an integer value using one of the following methods:

* `<integer>.htimes`: Equivalent to the range `0..<integer-1>`.

* `<integer>.supto(<last>)`: Equivalent to the range `<integer>..<last>`.

* `<integer>.sdownto(<last>)`: Equivalent to the range `<last>..<integer>`.

__Parallel Enumerator Control Methods__

Parallel enumerators provide several control methods:

* `hsize`: Returns the number of elements accessible by the enumerator.

* `htype`: Returns the type of the elements accessed.

* `heach`: Returns the enumerator itself. If a block is given, it performs the iteration.

* `heach_with_index`: Iterates over each element and its index. Returns an enumerator or performs iteration if a block is given.

* `heach_with_object(<obj>)`: Iterates over each element with a custom object. Returns an enumerator or performs iteration if a block is given.

* `with_index`: Identical to `seach_with_index`.

* `with_object(<obj>)`: Identical to `seach_with_object`.

* `clone`: Creates a new enumerator over the same elements.

* `+`: Concatenates two enumerators.

__Hardware Implementations of Enumerable Methods__

Using parallel enumerators, HDLRuby provides hardware implementations of many Ruby Enumerable methods. These are available for any enumerable object and can be used inside or outside processes.

Each method name corresponds to its Ruby counterpart, prefixed with an `h` (for "hardware"). For example, `hall?` is the hardware implementation of Ruby's `all?`.

* `hall?`: Hardware implementation of `all?`. Returns a 1-bit signal (`0` = false, `1` = true).

* `hany?`: Hardware implementation of `any?`. Returns a 1-bit signal.

* `hchain`: Hardware implementation of `chain`.

* `hmap`: Hardware implementation of `map`. Returns a vector signal of the computed results.

 <!-- * `hcompact`: Hardware implementation of `compact`. However, since there is no nil value in HW, use 0 instead for compacting. Returns a vector signal containing the compaction result. -->

* `hcount`: Hardware implementation of `count`. Returns a signal whose bit width matches the size of the enumerator containing the count result.

<!-- * `hcycle`: Hardware implementation of `cycle`. -->

* `hfind`: Hardware implementation of `find`. Returns the found element or `0` if not found.

* `hdrop`: Hardware implementation of `drop`. Returns a vector signal of the remaining elements.

<!-- * `hdrop_while`: Hardware implementation of `drop_while`. Returns a vector signal containing the remaining elements. -->

* `heach_cons`: Hardware implementation of `each_cons`.

* `heach_slice`: Hardware implementation of `each_slice`.

* `heach_with_index`: Hardware implementation of `each_with_index`.

* `heach_with_object`: Hardware implementation of `each_with_object`.

* `hto_a`: Hardware implementation of `to_a`. Returns a vector signal of all enumerated elements.

<!-- * `hselect`: Hardware implementation of `select`. Returns a vector signal containing the selected elements. -->

* `hfind_index`: Hardware implementation of`find_index`. Returns the index of the found element or `-1` if not found.

* `hfirst`: Hardware implementation of `first`. Returns a vector signal of the first elements.

* `hinclude?`: Hardware implementation of `include?`. Returns a 1-bit signal.

* `hinject`: Hardware implementation of `inject`. Returns a signal containing the accumulated result. The data type of the result can be passed as initialization argument.

* `hmax`: Hardware implementation of `max`. Returns a vector signal of the maximum values.

  *Note:* Only one maximum value is supported at the moment.

* `hmax_by`: Hardware implementation of `max_by`. Returns a vector signal of the maximum values.

  *Note:* Only one maximum value is supported at the moment.

* `hmin`: Hardware implementation of `min`. Returns a vector signal of the minimum values.

  *Note:* Only one minimum value is supported at the moment.


* `hmin_by`: Hardware implementation of`min_by`. Returns a vector signal of the minimum values.

  *Note:* Only one minimum value is supported at the moment.


* `hminmax`: Hardware implementation of `minmax`. Returns a 2-element vector signal with the minimum and maximum values.

* `hminmax_by`: Hardware implementation of the Ruby `minmax_by` method. Returns a 2-element vector signal with the minimum and maximum values.

* `hnone?`: Hardware implementation of `none?`. Returns a 1-bit signal.

* `hone?`: Hardware implementation of `one?`. Returns a 1-bit signal.

<!-- * `hreject`: Hardware implementation of `reject`. Returns a vector signal containing the remaining elements. -->

* `hreverse_each`: Hardware implementation of `reverse_each`.

  *Note:* To be used inside a `seq` process.

* `hsort`: Hardware implementation of `sort`. Returns a vector of sorted elements.

  *Note*: When the number of elements is not a power of 2, you must provide the maximum (or minimum for descending sort) value as an argument.


* `hsort_by`: Hardware implementation of `sort_by`. Returns a vector signal containing the sorted elements.

  *Note*: When the number of elements is not a power of 2, you must provide the maximum (or minimum for descending sort) value as an argument.

* `hsum`: Hardware implementation of `sum`. Returns a signal with the total sum.

* `htake`: Hardware implementation of `take`. Returns a vector of the selected elements.

<!-- * `htake_while`: Hardware implementation of `take_while`. Returns a vector signal containing the taken elements. -->

<!-- * `huniq`: Hardware implementation of `uniq`. Returns a vector signal containing the selected elements. -->


## Sequencer (Software-like Hardware Coding)

This library provides a set of software-like control statements for describing the behavior of a circuit.
Behind the scenes, these constructs generate a finite state machine (FSM), where states are inferred from control points in the description.

Although sequencers are intended for hardware design, they are software-compatible and can efficiently execute as software programs. For more information, see the section on [software sequencers](#sequencers-as-software-code).

__Declaring a Sequencer__

A sequencer can be declared anywhere in a system, as long as it is outside of a process, using the `sequencer` keyword:

```ruby
sequencer(<clock>,<start>) <block>
```

Where:

* `clock` is the signal (or event, such as `posedge` or `negedge`) that advances the sequencer.

* `start` is the signal (or event) that starts the sequencer.

* `block` is the sequence of operations to perform.

__Sequencer Constructs__

The sequence block behaves like a `seq` block but includes the following software-like control statements:

* `step`: Waits until the next event (as defined by the sequencer’s `event`).

* `steps(<num>)`: Repeats `step` for `num` cycles. `num` can be any expression.

* `sif(<condition>) <block>`: Executes `block` if condition is true (not `0`).

* `selsif(<condition>) <block>`: Executes block if all previous `sif`/`selsif` conditions were false (`0`) and this one is true (not `0`).

* `selse <block>`: Executes `block` if none of the previous conditions were met.

* `swait(<condition>)`: Waits until `condition` becomes true (not `0`).

* `swhile(<condition>) <block>`: Repeats `block` while condition is true (not `0`).

* `sfor(<enumerable>) <block>`: Iterates over each element of an enumerable object or signal.

* `sbreak`: Exits the current loop.

* `scontinue`: Skips to the next iteration.

* `sterminate`: Ends the sequencer’s execution.

__Controlling Sequencers Externally__

Two methods can be used to control a sequencer from outside:

* `alive?`: Returns `1` if the sequencer is still running; `0` otherwise.

* `reset!`: Resets the sequencer to its initial state.

To use these methods, assign the sequencer to a reference variable:

```ruby
ref_sequencer = sequencer(clk,start) do
   # Some sequencer code
end

# ... Somewhere else in the code.

   # Reset the sequencer if it ended its execution.
   hif(ref_sequencer.alive? == 0) do
      ref_sequencer.reset!
   end
```

__Using Enumerators in Sequences__

Within sequencer blocks, HDLRuby provides enumerator methods similar to Ruby’s `each`. These include:

* `<object>.seach`: `object` can be any Ruby enumerable or HDLRuby signal. If a block is given, it behaves like sfor; otherwise, it returns an HDLRuby enumerator (see [enumerator](#hdlruby-enumerators-and-enumerable-objects) for details).

* `<object>.stimes`: Can be used on integers and is equivalent to calling seach on the range `0..object-1`.

* `<object>.supto(<last>)`: Can be used on integers and is equivalent to calling `seach` on the range`object..last`.

* `<object>.sdownto(<last>)`: Can be used on an integer and is equivalent to calling `seach` on the range `object..last` in reverse order.

Objects that support these methods are called *enumerable objects*. These include HDLRuby signals, HDLRuby enumerators, and all Ruby enumerable types (e.g., ranges, arrays).

__Examples__

Below are a few examples of sequencers synchronized on the positive edge of `clk`, starting when `start` becomes `1`.

_Example 1: Fibonacci Sequence_

his sequencer computes the Fibonacci sequence up to 100, producing a new term in the signal `v` on each clock cycle:

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

_Example 2: Squaring Integers_

This sequencer computes the square of integers from 10 to 100, producing one result per cycle in signal `a`:

```ruby
inner :clk, :start
[16].inner :a

sequencer(clk.posedge,start) do
   10.supto(100) { |i| a <= i*i }
end
```

_Example 3: Reversing a String in Memory_

This sequencer reverses the contents of memory `mem`. The final result will be "!dlrow olleH":

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

_Example 4: Summing Elements with Early Termination_

This sequencer computes the sum of the elements in memory `mem`, stopping if the sum exceeds 16:

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


### HDLRuby Sequential Enumerators and Enumerable Objects

HDLRuby sequential enumerators are objects used to perform iterations within sequencers. They are created using the `seach` method on enumerable objects, as presented in the previous section.

Enumerators can be controlled using the following methods:

* `size`: Returns the number of elements the enumerator can access.

* `type`: Returns the type of elements accessed by the enumerator.

* `seach`: Returns the current enumerator. If a block is given, it performs the iteration instead of returning an enumerator.

* `seach_with_index`: Returns an enumerator over the elements of the current enumerator, paired with their index positions. If a block is given, it performs the iteration instead.

* `seach_with_object(<obj>)`: Returns an enumerator over the elements of the current enumerator, each paired with the given object `obj` (any object, HDLRuby or otherwise). If a block is given, it performs the iteration instead.

* `with_index`: Identical to `seach_with_index`.

* `with_object(<obj>)`: Identical to `seach_with_object`.

* `clone`: Creates a new enumerator over the same elements.

* `speek`: Returns the current element pointed to by the enumerator without advancing it.

* `snext`: Returns the current element pointed to by the enumerator and then advances to the next one.

* `srewind`: Restarts the enumeration from the beginning.

* `+`: Concatenates two enumerators.

You can also define a custom enumerator using the following syntax:

```ruby
<enum> = senumerator(<typ>,<size>) <block>
```

Where:

* `enum` is a Ruby variable referring to the enumerator,

* `typ` is the data type of the elements,

* `block` is the code block that defines how to access each element by index.

For example, an enumerator over a memory can be defined as follows:

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

In the code above, `mem_enum` is a variable referring to the enumerator that accesses memory `mem`. The access assumes that one clock cycle must pass after setting the address before the data becomes available. Therefore, a step command is used in the block before returning data.

__Enumeration Algorithms__

Based on the enumerator functionality, several algorithms have been implemented in HDLRuby using sequential enumerators. These algorithms mirror the behavior of Ruby's Enumerable methods and are compatible with all HDLRuby enumerable objects. Each algorithm is implemented in hardware for HDLRuby sequencers and is accessible via the corresponding Ruby method, prefixed with the letter `s`.

Here are the available methods in detail:

* `sall?`: Sequencer implementation of `all?`. Returns a 1-bit signal (`0` for false, `1` for true).

* `sany?`: Sequencer implementation of `any?`. Returns a 1-bit signal.

* `schain`: Sequencer implementation of `chain`.

* `smap`: Sequencer implementation of `map`. When used with a block, returns a vector signal containing each computation result.

* `scompact`: Sequencer implementation of`compact`. Since there is no `nil` in HDLRuby, the value `0` is used instead. Returns a vector signal containing the compacted result.

* `scount`: Sequencer implementation of`count`. Returns a signal whose bit width matches the enumerator’s size, representing the count result.

* `scycle`: Sequencer implementation of `cycle`.

* `sfind`: Sequencer implementation of `find`. Returns a signal containing the found element, or 0 if not found.

* `sdrop`: Sequencer implementation of`drop`. Returns a vector signal containing the remaining elements.

* `sdrop_while`: Sequencer implementation of `drop_while`. Returns a vector signal containing the remaining elements.

* `seach_cons`: Sequencer implementation of `each_cons`.

* `seach_slice`: Sequencer implementation of `each_slice`.

* `seach_with_index`: Sequencer implementation of `each_with_index`.

* `seach_with_object`: Sequencer implementation of `each_with_object`.

* `sto_a`: Sequencer implementation of `to_a`. Returns a vector signal containing all the elements of the enumerator.

* `sselect`: Sequencer implementation of `select`. Returns a vector signal containing the selected elements.

* `sfind_index`: Sequencer implementation of`find_index`. Returns the index of the found element or -1 if not.

* `sfirst`: Sequencer implementation of `first`. Returns a vector signal containing the first elements.

* `sinclude?`: Sequencer implementation of `include?`. Returns a 1-bit signal.

* `sinject`: Sequencer implementation of `inject`. Returns a signal of the same type as the enumerator’s elements, containing the result.

* `smax`: Sequencer implementation of `max`. Returns a vector signal containing the found maximum value(s).

* `smax_by`: Sequencer implementation of `max_by`. Returns a vector signal containing the found maximum value(s).

* `smin`: Sequencer implementation of `min`. Returns a vector signal containing the found minimum value(s).

* `smin_by`: Sequencer implementation of `min_by`. Returns a vector signal containing the found minimum value(s).

* `sminmax`: Sequencer implementation of `minmax`. Returns a 2-element vector signal containing the resulting minimum and maximum values.

* `sminmax_by`: Sequencer implementation of `minmax_by`. Returns a 2-element vector signal containing the resulting minimum and maximum values.

* `snone?`: Sequencer implementation of `none?`. Returns a 1-bit signal.

* `sone?`: Sequencer implementation of `one?`. Returns a 1-bit signal.

* `sreject`: Sequencer implementation of `reject`. Returns a vector signal containing the remaining elements.

* `sreverse_each`: Sequencer implementation of `reverse_each`.

* `ssort`: Sequencer implementation of `sort`. Returns a vector signal containing the sorted elements.

* `ssort_by`: Sequencer implementation of `sort_by`. Returns a vector signal containing the sorted elements.

* `ssum`: Sequencer implementation of `sum`. Returns a signal of the same type as the enumerator’s elements, containing the sum result.

* `stake`: Sequencer implementation of `take`. Returns a vector signal containing the taken elements.

* `stake_while`: Sequencer implementation of `take_while`. Returns a vector signal containing the taken elements.

* `suniq`: Sequencer implementation of `uniq`. Returns a vector signal containing the selected elements.



### Shared Signals, Arbiters, and Monitors

#### Shared Signals

s with any other process, multiple sequencers cannot write to the same signal. Doing so would cause race conditions, which can physically damage the device if permitted. In standard RTL design, this issue is typically handled using three-state buses, multiplexers, and arbiters.

However, HDLRuby sequencers introduce a special kind of signal called a *shared signal*, which abstracts away these implementation details and prevents race conditions.

Shared signals are declared similarly to regular signals, based on their type. The syntax is:

```ruby
<type>.shared <list of names>
```

They can also be initialized with default values as follows:

```ruby
<type>.shared <list of names with initialization>
```

For example, the following code declares two 8-bit shared signals `x` and `y`, and two signed 16-bit shared signals `u` and `v`, both initialized to 0:

```ruby
[8].shared :x, :y
signed[8].shared u: 0, v: 0
```

A shared signal can be read from and written to by any sequencer, from anywhere in the subsequent code within the current scope. However, shared signals cannot be written to outside of a sequencer.

Valid example:

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

Invalid example:

```ruby
[8].shared w: 0

par(clk.posedge) { w <= w + 1 }
```

By default, a shared signal acknowledges writes from the first sequencer that attempts to write to it (in order of declaration). All other writes are ignored. In the valid example above, the value of `x` is always set by the first sequencer, producing values from 0 to 9, changing once per clock cycle. The signal `y`, however, is only written by the second sequencer and thus reflects its values.

This default behavior avoids race conditions but offers limited flexibility. To gain better control, you can explicitly select which sequencer is allowed to write to a shared signal. This is done using the `select` sub-signal of the shared signal:

```ruby
<shared signal>.select <= <index>
```

The selection index starts at 0 for the first sequencer writing to the signal, 1 for the second, and so on.

For example, to allow the second sequencer to write to x, you can add the following line after declaring `x`:

```ruby
   x.select <= 1
```

This selection can also be changed dynamically at runtime. For instance, to alternate the writer every clock cycle:

```ruby
   par(clk.posedge) { x.select <= x.select + 1 }
```

__Note__: The `select` sub-signal is a standard RTL signal and is subject to the same rules and limitations as any other non-shared signal. It is not itself a shared signal.


#### Arbiters

In most cases, it's not the signals themselves that we want to share, but rather the resources they control. For example, in a CPU, it's the ALU that is shared as a whole -- not each of its inputs separately. To support such scenarios and simplify the handling of shared signals, HDLRuby provides arbiter components.

An arbiter is instantiated like a standard module. The syntax is as follows, where `name` is the name of the arbiter instance:

```ruby
arbiter(:<name>).(<list_of_shared_signal>)
```

When instantiated, the arbiter takes control of the `select` sub-signals of the specified shared signals. As a result, you can no longer manually set the `select` values for those signals. In exchange, the arbiter allows sequencers to request or release write access to the shared signals.

To request access, a sequencer assigns the value 1 to the arbiter. To release access, it assigns 0. If a sequencer attempts to write to a shared signal under arbitration without first requesting access, the write will be ignored.

__Example__

The following example defines an arbiter named `ctrl_xy` that manages access to shared signals `x` and `y`, along with two sequencers that request and release access to them:

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

In this example, both sequencers request access before writing to the shared signals and release it afterward.

__Note__: Requesting access does not guarantee that access will be granted. If access is not granted, write operations will be ignored.

By default, the arbiter grants access based on the order of sequencer declaration. That is, if multiple sequencers request access simultaneously, the one declared first in the code has priority.

In the example above, the first sequencer is granted write access to `x` and `y` and holds it for five cycles. Once it releases access, the second sequencer gains control and begins writing. The second sequencer runs its first five iterations without affecting the shared signals—only the last five are effective.

To avoid wasting cycles in such situations, a sequencer can check whether it currently holds write access by using the arbiter’s `acquired` sub-signal. This signal is 1 if the sequencer has been granted access and 0 otherwise. For example, the following line will increment `x` only when access is granted:

```ruby
hif(ctrl_xy.acquired) { x <= x + 1 }
```

__Changing Arbiter Policy__

You can change the arbiter's access-granting policy using the `policy` method. One option is to provide a priority list -- a vector of sequencer indices in order of decreasing priority (i.e., the first entry has the highest priority). Sequencers are numbered in the order they are declared and use the arbiter.

For example, to give the second sequencer priority over the first in the earlier example, you could write:

```ruby
ctrl_xy.policy([1,0])
```

You can also define more complex arbitration logic by passing a block to `policy`. This block receives a vector (`acq`) indicating which sequencers are currently requesting access (each bit set to 1 means a request is active), and returns the index of the sequencer to be granted access.

Here’s an example that alternates the priority at each access:

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
In this example:

* `acq` is a bit vector where bit 0 corresponds to sequencer 0, bit 1 to sequencer 1, etc.

* he policy toggles `priority_xy` after each access, thereby switching priority between sequencers.


#### Monitors

Arbiters are especially useful when sequencers accessing the same resource do not overlap in time or do not need to synchronize with each other. However, when synchronization is required -- meaning a sequencer must wait until it has exclusive access before proceeding -- *a monitor* is more appropriate.

Monitors are instantiated in the same way as arbiters:

```ruby
monitor(:<name>).(<list_of_shared_signals>)
```

Like arbiters, monitors manage shared signals and support the same write-access granting policies. However, unlike arbiters, monitors block the execution of a sequencer that requests access until the access is granted. This guarantees that a sequencer’s operations on shared signals are performed without interruption or interference from other sequencers.

__Example__

Let’s revisit the previous arbiter-based example. If we replace the arbiter with a monitor:

```ruby
monitor(:ctrl_xy).(x,y)
```

Then the second sequencer will be paused until it is granted access to shared signals `x` and `y`. This ensures that all iterations of its loop are performed as intended, without being skipped or ignored.

Since monitors block execution, they implicitly insert a `step`. To make this behavior explicit and clear, acquiring access to a monitor is done using the `lock` method (instead of assigning 1), and releasing access is done using the `unlock` method (instead of assigning 0).

Here is the rewritten version of the previous example using a monitor:

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

In this example:

* Each sequencer waits to acquire exclusive access before proceeding.

* The monitor guarantees mutual exclusion, ensuring no interleaved writes occur.

* The `lock` and `unlock` methods clearly define the critical section.


### Sequencer-Specific Functions

HDLRuby functions defined with `hdef` can be used within sequencers like any other HDLRuby construct. However, just like process constructs such as `hif`, the body of an `hdef` function cannot include any sequencer-specific constructs.

To define functions that do support sequencer-specific constructs, use `sdef` instead of `hdef`. The syntax is:

```ruby
   sdef :<function_name> do |<arguments>|
   # Sequencer code
   end
```

Functions defined with `sdef` can be declared anywhere in an HDLRuby description but can only be called from within a sequencer.

__Recursion Support__

Since `sdef` is intended to support software-like control structures, it also supports recursion. For example, a recursive factorial function can be defined as follows:

```ruby
sdef(:fact) do |n|
    sif(n > 1) { sreturn(n*fact(n-1)) }
    selse      { sreturn(1) }
end
```

As shown above, the `sreturn` construct is used to return a value from within the body of an `sdef` function.

When recursion is used, HDLRuby automatically allocates a stack to store the return state and the function arguments. The stack size is heuristically determined based on the maximum bit width of the function arguments at the time of the recursive call.

For example, if the argument `n` in the fact function is 16 bits, the stack will support up to 16 recursive calls.

If this heuristic is insufficient, you can manually set the stack size by providing a second argument to `sdef`:

```ruby
sdef(:fact,32) do |n|
    sif(n > 1) { sreturn(n*fact(n-1)) }
    selse      { sreturn(1) }
end
```

__Notes__:

* Each recursive function call takes one sequencer cycle, and each return takes two cycles.

* Tail-call optimization is currently not supported.

* If the number of recursive calls exceeds the available stack size (i.e., a stack overflow occurs), the current recursion is terminated, and the sequencer continues execution normally.

* To handle stack overflows explicitly, you can attach a handler process using a proc block as a third argument to `sdef`:
  
  ```ruby
     sdef(:<name>,<depth>, proc <block>) do
        <function code>
     end
  ```

  **Important:** The overflow handler block cannot contain sequencer-specific constructs.

  For example, the factorial function can be modified to set a `stack_overflow` signal in case of overflow:

  ```ruby
  sdef(:fact,32, proc { stack_overflow <= 1 }) do |n|
      sif(n > 1) { sreturn(n*fact(n-1)) }
      selse      { sreturn(1) }
  end
  ```

  In the code above, the signal `stack_overflow` must be declared before calling the fact function.


### Sequencers as Software Code

#### Introduction to Sequencer as Software Code

Sequencers can be executed in software using a Ruby interpreter while maintaining functional equivalence with the hardware implementation. To achieve this, the following headers must be added to your Ruby source code:

```ruby
require 'HDLRuby/std/sequencer_sw'
include RubyHDL::High
using RubyHDL::High
```

After this, signals and sequencers can be described exactly as in HDLRuby. However, unlike in hardware simulation, sequencer objects are not executed immediately -- they must be assigned to a variable for later execution.

For example, the following Ruby code defines a sequencer (referenced by the variable `my_seq`) that increments the signal `counter` up to 1000:

```ruby
require 'HDLRuby/std/sequencer_sw'
include RubyHDL::High
using RubyHDL::High

[32].inner :counter

my_seq = sequencer do
   counter <= 0
   1000.stimes do
      counter <= counter + 1
   end
end
```

You may notice that no clock or start signal is provided to the sequencer. This is because, in software execution, everything runs sequentially -- no clock or control signals are needed. Instead, you start the sequencer by calling it directly using the function call syntax:

```ruby
my_seq.()
```

To check whether the sequencer executed correctly, you can read signal values outside the sequencer using the `value` method. For instance, the code below initializes `counter` to 0, runs the sequencer, and then prints the final value:

```ruby
require 'HDLRuby/std/sequencer_sw'
include RubyHDL::High
using RubyHDL::High

[32].inner :counter

counter.value = 0

my_seq = sequencer do
   counter <= 0
   1000.stimes do
      counter <= counter + 1
   end
end

my_seq.()

puts "counter=#{counter.value}"
```

__Note__: When printing the value of a signal, the `value` method can be omitted, as signals are implicitly converted to their current value. For example, the last line above can also be written as:

```ruby
puts "counter=#{counter}"
```

Internally, the HDLRuby code of a sequencer is translated to Ruby before execution. This generated Ruby code can be accessed using the `source` method. You can save it to a file for standalone execution, as shown below:

```ruby
File.open("sequencer_in_ruby.rb","w") do |f|
   f << my_seq.source
end
```

You can also generate C or Python code from the sequencer using the `to_c` and `to_python` methods, respectively. The following commands create equivalent C and Python files from `my_seq`:

```ruby
File.open("sequencer_in_c.c","w" do |f|
   f << my_seq.to_c
end

File.open("sequencer_in_python.py","w" do |f|
   f << my_seq.to_python
end
```

__Notes:__

* Currently, synchronization commands (presented in section [Synchronizing Sequencers for Pseudo-Parallel Execution](#synchronizing-sequencers-for-pseudo-parallel-execution) are not yet supported in the C and Python backends.

* The Ruby code for sequencers is compatible with mruby, making it suitable for execution on embedded systems.

* You can also generate experimental TensorFlow code using the `to_tf` method.


#### Why Would I Want to Execute a Sequencer in Software, and What are the Limitations?

There are two main reasons for executing sequencers in software:

1. **High-speed simulation**

  Software-executed sequencers run approximately 10 times faster than those simulated using the HDLRuby simulator.

2. **Seamless transition from software to hardware**

  In early design stages, it is often unclear whether a given component will ultimately be implemented in software or hardware. Using the same code for both provides:

  * Reliability -- guaranteed functional equivalence between software and hardware.

  * Reduced design time -- no need to rewrite or duplicate code.

---

While software-based sequencers are functionally equivalent to their hardware counterparts, they differ fundamentally in how they handle time and parallelism:

* In hardware, sequencers are implemented as finite state machines that respond to a clock and run in parallel with the rest of the circuit.

* In software, sequencers are implemented as fibers that execute sequentially.

This distinction means that software sequencers may not be suitable for designs that rely heavily on timing or parallelism, such as communication protocols.

However, there are ways to introduce hardware-like timing and concurrency, which are described in the following sections.


#### Adding a Clock to a Software Sequencer.

As mentioned earlier, software execution does not involve a hardware clock. However, you can simulate a clock during the execution of a software sequencer to estimate its performance as if it were implemented in hardware.

This is done by passing a signal as an argument to the sequencer. That signal will be incremented at each simulated clock cycle:

```ruby
sequencer(<clock_counting_signal>) do
  ...
end
```

After execution, the total number of estimated clock cycles is stored in the clock count signal. For example, the following code displays `1000 clocks`, which represents the number of cycles the sequencer would take if implemented in hardware:

```ruby
[32].inner :clk_count
clk_count.value = 0

sequencer(clk_count) do
   1000.stimes
end.()

puts "#{clk_count} clocks"
```

__Note__: In the example above, the sequencer is not stored in a variable because it is executed immediately upon definition.

#### Adding a Signal to Control the Execution of a Software Sequencer.

In addition to a clock counter signal, you can pass a start signal to control when a software sequencer begins execution—just like in hardware implementations.

To do this, pass the start signal as the second argument to the `sequencer` function. For example, in the code below, the sequencer begins executing when the start `signal` is set to `1`:

```ruby
[32].inner :clk_count
[1].inner :start
clk_count.value = 0

sequencer(clk_count,start) do
   1000.stimes
end

start.value = 1

puts "#{clk_count} clocks"
```

In this mode, you don’t need to store the sequencer in a Ruby variable. Execution begins just like in hardware, and the sequencer can also be triggered from another sequencer.

__Controlling One Sequencer from Another__

The example below shows two sequencers, where the first sequencer controls the start of the second by setting the `start1` signal to `1`:

```ruby
[1].inner :start0, :start1
[8].inner :count0, :count1

sequencer(nil,start0) do
   count0 <= 0
   swhile(count0<100) { count0 <= count0 + 1 }
   start1 <= 1
end

sequencer(nil,start1) do
   count1 <= 0
   swhile(count1<100) { count1 <= count1 + 1 }
end
```

#### Synchronizing Sequencers for Pseudo-Parallel Execution

In software, sequencers normally run to completion before any other code is executed. However, you can simulate parallel execution by using the `sync` command. While `sync` has no hardware equivalent, it can be used in software to pause and resume sequencers in a controlled, cooperative manner.

When a `sync` command is encountered during execution:

* The sequencer is paused.

* Control is returned to the code following the sequencer's start.

* The paused sequencer can later be resumed by either:

  * Calling it again using the call operator (`my_seq.()`), or

  * Setting its associated start signal to `1`.

__Example: Pausing and Resuming a Sequencer__

In the following example, the sequencer runs until `count` reaches 20, then pauses. After resuming, it continues up to 40:

```ruby

[32].inner :count

my_seq = sequencer do
   count <= 0
   20.stimes
      count <= count + 1
   sync
   20.stimes
      count <= count + 1
   end
end

my_seq.()
puts "stop at count=#{count}"
my_seq.()
puts "end at count=#{count}"
```

__Cycle-Accurate Synchronization__

To simulate cycle-accurate synchronization, you could insert a `sync` call at each estimated clock cycle. However, this comes with a performance cost. Depending on the Ruby interpreter and system configuration, heavy use of `sync` may cause software execution to become slower than the HDLRuby hardware simulator.

__Recommendation:__ Use `sync` only when necessary for modeling concurrency or interleaving. For cycle-accurate simulation, prefer using HDLRuby's hardware simulation mode.

__Checking If a Sequencer Is Still Running__

To check whether a sequencer is still active or paused (e.g., waiting at a `sync`), use the `alive?` method. For example, the following loop resumes the sequencer until it finishes:

```ruby
my_seq.() while(my_seq.alive?)
```

#### Executing ruby code within a software sequencer.

When running a sequencer in software, HDLRuby provides an additional command called `ruby`, which allows execution of plain Ruby code inside a sequencer block.

For example, the following code prints `Hello` ten times using Ruby's `puts` method:

```ruby
sequencer do
   stimes.10 do
      ruby { puts "Hello" }
   end
end.()
```

Alternatively, you can generate Ruby code dynamically using the `text` or `expression` commands:

* `text` inserts a Ruby statement.

* `expression` inserts a Ruby expression.

Both functions format their arguments similarly to the C `printf` function.

For example, the following code prints `Hello 0` through `Hello 9` when executed:

```
sequencer do
   stimes.10 do |i|
      text("puts \"Hello %d\"",i)
   end
end.()
```

__Choosing Between ruby, text, and expression__

* `ruby` is safer, as errors are checked at compile time, but it is slower and incompatible with separate code generation (e.g., for C or Python).

* `text` and `expression` allow faster execution and code export, but offer less safety, as errors are only detected at run time.

__Accessing Signal Values in text and expression Generated Code__

Since the string passed to `text` and `expression` is inserted as-is into the generated Ruby (or C) code, you cannot directly embed signal values into it. To include signal values safely and correctly, use:

* `to_ruby`, `to_c`, or `to_python` to get the raw value in the corresponding language.

* `value_text` for a hardware-accurate representation (handling overflow/underflow).

```ruby
sequencer do
   text("puts #{sig0.to_ruby}")
   text("puts #{sig1.value_text}")
end
```

#### Using Software Sequencer Inside a HDLRuby program.

HDLRuby supports hardware/software co-design through the `program` [construct](#declaring-a-software-component). Since software sequencers are software components, they can be used within this construct when the selected language is Ruby.

To enable software sequencer functionality in Ruby, you must insert the following command at the beginning of the code block:

```ruby
activate_sequencer_sw(binding)
```

Software sequencers can also be used with the C language, but in that case, the corresponding C code must be explicitly generated beforehand using the `to_c` method.

__Connecting Signals to Program Ports__

When writing Ruby software within a `program`, the signals used by the software sequencer can be automatically connected to the RTL-level ports by declaring them as:

* `inport` for input signals, and

* `outport` for output signals.

The following example describes a software sequencer that copies the value from the input port `inP` to the output port `outP`. The signals `sig0` and `sig1` come from the surrounding RTL design.

```ruby
program(:ruby) do
  actport clk.posedge
  inport inP: sig0
  outport outP: sig1
  code do
    activate_sequencer_sw(binding)
    input :inP
    output :outP
    sequencer do
      outP <= inP
    end
  end
end
```

In this example:

* `actport` specifies that the Ruby code is triggered on the positive edge of the clock signal.

* The `input` and `output` declarations inside the code block mirror the port names, making them accessible within the sequencer.

* `activate_sequencer_sw(binding)` initializes the environment for using HDLRuby software sequencers.



## Fixed-Point

This library provides a set of fixed-point data types for use in HDLRuby designs. These types can represent:

* Bit (or unsigned) values.

* Signed values.

They are declared using the following syntax:

```ruby
bit[<integer_part_range>,<fractional_part_range>]
unsigned[<integer_part_range>,<fractional_part_range>]
signed[<integer_part_range>,<fractional_part_range>]
```

For example, the following code declares a signed fixed-point signal named `sig` with 4 bits for the integer part and 4 bits for the fractional part:

```ruby
bit[4,4].inner :sig
```

When performing arithmetic operations on fixed-point types, HDLRuby automatically adjusts the decimal point position to maintain correct precision in the result.

__Converting Literals to Fixed-Point__

A method is also provided to convert numeric literals (such as integers or floats) to fixed-point format:

```ruby
<litteral>.to_fix(<number_of_bits_after_the_decimal_point>)
```

For example, the following code converts the floating-point number 3.178 to a fixed-point representation with 16 fractional bits:

```
3.178.to_fix(16)
```

<!--

## Channel
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

__Note__: The code of the circuits, in the examples `producer8`, `consumer8`, and `producer_consummer8` is independent of the content of the channel. For example, the sample `with_channel.rb` (please see [samples](#sample-hdlruby-descriptions)) uses the same circuits with a channel implementing handshaking.

-->

<!---

## Pipeline
<a name="pipeline"></a>

This library provides a construct for an easy description of pipeline architectures.

-->

# Sample HDLRuby descriptions

Several samples HDLRuby descriptions are available in the following directory:

```bash
path/to/HDLRuby/lib/HDLRuby/hdr_samples
```

If you installed HDLRuby as a gem, you can find the installation path by running:

```bash
gem which HDLRuby
```

However, the recommended way to access the samples is to import them into your local directory using the following command:

```bash
hdrcc --get-samples
```

__Naming Conventions for Sample Files__

The samples follow a naming convention:

* `<name>.rb`:
 
  A standard sample, requiring no parameters.

* `<name>_gen.rb`: 

  A sample that requires generic parameters for processing.

* `<name>_bench.rb`: 

  A sample that includes a simulation benchmark. These are the only samples that can be simulated using the hdrcc -S command.

* `with_<name>.rb`:

  A sample that illustrates a specific feature of HDLRuby or one of its libraries. These usually include a benchmark.




# Converting Verilog HDL to HDLRuby

While the HDLRuby framework does not yet support Verilog HDL files as direct input, a standalone tool is provided to convert Verilog files to HDLRuby. To perform this conversion, use the following command:

```bash
v2hdr <input_Verilog_HDL_file> <output_HDLRuby_file>
```

For example, assuming you have a Verilog HDL file named `adder.v` that describes an adder circuit, you can convert it to HDLRuby using:

```bash
v2hdr adder.v adder.v.rb
```

__Alternative: Loading Verilog HDL Directly from HDLRuby__

Instead of manually converting a Verilog file, you can load it from a HDLRuby description using the `require_verilog` command.

Assuming `adder.v` contains the following Verilog code:

```verilog
module adder(x,y,z);
  input[7:0] x,y;
  output[7:0] z;
  
  assign z = x + y;
endmodule
```

You can load and instantiate this module in HDLRuby just like any other system:

```ruby
require_verilog "adder.v"

system :my_IC do
   [8].inner :a, :b, :c

   adder(:my_adder).(a,b,c)

   ...
end
```


__Notes__:

* Verilog HDL allows signal and module names to start with uppercase letters. In HDLRuby, however, identifiers starting with a capital letter are reserved for constants. To avoid naming conflicts, Verilog names beginning with a capital letter are prefixed with an underscore (`_`) when imported into HDLRuby.

  For example, if the Verilog module were named `ADDER`, it would be imported as `_ADDER` in HDLRuby, and instantiated like this:

  ```ruby
  _ADDER(:my_add).(a,b,c)
  ```

* In the current version of HDLRuby, Verilog HDL files are converted to HDLRuby using the v2hdr tool before being loaded with `require_verilog`.


# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/civol/HDLRuby.


# To do

* Find and fix the (maybe) terrifying number of bugs.


# License

The gem is available as open-source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

