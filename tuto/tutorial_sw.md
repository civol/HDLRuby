# HDLRuby Tutorial for Software People

In this tutorial, you will learn the basics about the description of digital circuits using HDLRuby from the software point of view. In detail you will learn:

 1. [What is HDLRuby and how to use its framework.](#hdlruby)

 2. [How to represent a circuit.](#circuit)

 3. [How to describe an algorithm to be implemented by a circuit.](#algorithm)

 4. [How to simulate the physical environment of a circuit.](#environment)

 5. [How to make a structural description of a circuit.](#structural)

 6. [How to make a behavioral description of a circuit.](#behavioral)

Within theses topics, you will also have explanation about how the following high-level concepts can be used in HDLRuby:

 * Object oriented programming

 * Reflection

 * Genericity

 * Metaprogramming

But, before going further, here are a few...

## Prerequisites

Since this tuturial is aiming at software people, it is assumed you have a good understanding on programming and the relevant tools (e.g., editor, compiler). However it is not assumed that you have any knowledge about digital hardware design. Otherwise, it is recommended but not mandatory to have knowledge about the Ruby programming language.

In order to use HDLRuby the following software are required:

 * A distribution of the Ruby language.

 * A text editor. If you like syntax highlighting or other fancy features, please choose one supporting Ruby. 

 * A command line interface (e.g., command prompt, terminal emulator).

The following software is also recommended:

 * A wave viewer supporting *vcd* files (e.g., [GTKWave](https://gtkwave.sourceforge.net/))



## 1. What is HDLRuby and how to use its framework <a name="hdlruby"></a>

HDLRuby is a hardware description language (HDL) based on the Ruby programming language. It is implemented as a Ruby library so that, by contruction any Ruby code can be used and executed within HDLRuby description.

Before going further, let us briefly explain what is a [HDL](#hdl). Then, more details will be given about how to [install HDLRuby](#install-hdlruby) and how to [use it](#use-hdlruby).

### 1.1. What is a hardware description language (HDL) <a name="hdl"></a>

A hardware description language (HDL) is a formal language similar to programming languages that is used for describing electronic circuits. Such circuits can be divided into two categories: analog circuits and digital circuits. While there exists HDL for describing the first category of circuits, a large majority of them only support the second one so that in practice, HDL means actual language for describing digital circuits only. Among the multiple HDL, two became de-facto standards: Verilog HDL and VHDL.

HDL are there for helping producing circuits. Nowadays, there exist powerful software tools that can automatically produce circuits from HDL descriptions. However, like in software, there may be errors in the descriptions, or they may be sub optimal, so that the final circuit does not work, or does not meet some constraints. Unfortunately, in hardware, producing a circuit is very time consuming and expensive so that contrary to software, errors or low performance results must be avoided as early as possible. This is why it is common in hardware to **simulate** your circuit description before starting to produce it. In other words, while in software it is common to perform the following loop:

```
┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│                  │      │                  │      │                  │
│  write program   ├─────►│  compile program ├─────►│   test program   │
│                  │      │                  │      │                  │
└──────────────────┘      └──────────────────┘      └────────┬─────────┘
                                    ▲                        │
                                    │                        │
                                    │                        ▼
                                    │               ┌──────────────────┐
                                    │               │                  │
                                    └───────────────┤   fix program    │
                                                    │                  │
                                                    └──────────────────┘

```

In hardware, the design loop is more like as follows:

```
┌──────────────────────┐      ┌──────────────────────┐      ┌──────────────────────┐
│                      │      │                      │      │                      │
│  write description   ├─────►│ simulate description ├─────►│   produce circuit    │
│                      │      │                      │      │                      │
└──────────────────────┘      └─────┬────────────────┘      └───────────┬──────────┘
                                    │          ▲                        │
                                    │          │                        │
                                    ▼          │                        ▼
                              ┌────────────────┴─────┐      ┌──────────────────────┐
                              │                      │      │                      │
                              │   fix description    │◄─────┤     test circuit     │
                              │                      │      │                      │
                              └──────────────────────┘      └──────────────────────┘
```


At first, the HDL have the same look and feel compared to classical programming languages like C or Java: they include expressions, control statements and kind of variables. However, the underlining model of computation is quite different, especially because circuits are inherently parallel devices, but this will be explained progressively during this tutorial. For now, it is enough to remember the following:

 * HDL are used for describing digital circuits and the most common ones are Verilog HDL and VHDL.

 * Using software tools called synthesis tools, you can produce real digital circuits from HDL description. But before that you will need to simulate your description.

 * HDL look like common programming languages but do not work the same.


#### And what about HDLRuby?

Well, HDLRuby is an HDL for describing digital circuits like Verilog HDL or VHDL, but aiming at being more flexible and productive than them by relying on many concepts inherited from the Ruby programming language. So everything said earlier about HDL applies to HDLRuby, but we try to make it much *easier* for the designers.


### 1.2. Installing HDLRuby <a name="install-hdlruby"></a>

HDLRuby is distributed as a rubygems package. It can therefore be installed using the following command:

```bash
gem install HDLRuby
```

If everything is OK the following should be displayed:

```
Fetching HDLRuby-<version>.gem
Building native extensions. This could take a while...
Successfully installed HDLRuby-<version>
Parsing documentation for HDLRuby-<version>
Done installing documentation for HDLRuby after <x> seconds.
```

The `<version>` number should be the latest version of HDLRuby.

You can then check is HDLRuby is properly installed by using the following command:

```bash
hdrcc --version
```

And the result should be:

```
<version>
```

If the resulting `<version>` number does not match the install number, there may have been a problem somewhere. It may be a good idea to close the terminal or command prompt and try again the command in a new one.



### 1.3. Using HDLRuby <a name="use-hdlruby"></a>

Up to now, we said that HDLRuby is a language, it is in truth a complete framework for designing and simulating digital circuits. It includes several compilers, simulators and libraries that are all accessible through a single command: `hdrcc`
.

Basically, `hdrcc` is used as follows:

```bash
hdrcc <options> <input file> <output directory>
```

Where `<options>` specifies the action to be performed, `<input file>` specifies the input HDLRuby file and `<output directory>` specifies the directory where the command results will be saved. As a general rule, when an input file is specified, an output directory must also be specified.

Several actions are possible using `hdrcc`, the main ones being the followings:

 * Simulate a circuit description:  
 
 ```bash
 hdrcc --sim <input file> <output directory>
 ```

 * Generate the equivalent Verilog HDL code:  

 ```bash
 hdrcc --verilog <input file> <output directory>
 ```  

 This second action is necessary if you want to produce a real circuit since HDLRuby is not yet supported by synthesis tools.

__Note__: VHDL generation is also possible using the following command:  

 ```bash
 hdrcc --vhdl <input file> <output directory>
 ```

 However, the Verilog HDL output is tested more often than the VHDL one (for practical reasons), and is therefore more reliable.

And that's it! For details about all the actions that can be performed, how to write an input file and what kind of output can be produced, let us seen the remaining of the tutorial.


## 2. How to represent a circuit in HDLRuby <a name="circuit"></a>

In this section we will see:

 * [How to declare a circuit.](#circuit-declare)

 * [How to reuse a circuit already declared.](#circuit-use)

### 2.1 Declaring a circuit <a name="circuit-declare"></a>

In HDLRuby as well as in other HDL, a circuit is viewed as a box that communicates with its environment with ports. The following charts illustrate such a view with a circuit including 6 ports:

```
A port
   │
   │
   │     ┌────────────────────────┐
   └───►┌┼┐                      ┌┼┐
        └┼┘                      └┼┘
        ┌┼┐      A circuit       ┌┼┐
        └┼┘                      └┼┘
        ┌┼┐                      ┌┼┐
        └┼┘                      └┼┘
         └────────────────────────┘
```

However, ports are not simple entry point: they have a data type and a direction that can be one of the following:

 * `input`: such a port can only be used for transmitting data from the outside of the circuit to its inside.

 * `output`: such a port can only be used for transmitting data from the inside of the circuit to its outside.


#### That's all very well, but when do I write HDLRuby code?

With that in mind, declaring a circuit consists in specifying its name and its ports. In HDLRuby this is done as follows:

```ruby
system :my_circuit do
   input :clk, :rst
   [16].input :addr
   input :ce
   [8].input  :data_in
   [8].output :data_out
end
```

So please write the code above in a file called (for example) `my_circuit.rb`, and let us explain its meaning.

 * In the first line, the keyword `system` indicates a new circuit will be described. Its name is given after the colon, `my_circuit` here.

 * The `do` &rarr; `end` block contains the description of the circuit. Here, only the port are specified as follows:

   - On the second line, `input` specifies two one-bit input ports named respectively `clk` and `rst`.

   - The third line specifies a 16-bit input port named `addr`.

   - The fourth line specifies a one-bit input port named `ce`.

   - The fifth line specifies an eight-bit input port named `data_in`.

   - The sixth line specifies an 8-bit output port named `data_out`.

```
      ┌───────────────────────────┐
clk  ┌┴┐                         ┌┴┐   ce    
────►│1│                         │1│◄────    
     └┬┘                         └┬┘         
      │                           │          
rst  ┌┴┐                         ┌┴┐  data_in
────►│1│        my_circuit       │8│◄────    
     └┬┘                         └┬┘         
      │                           │           
addr ┌┴┐                         ┌┴┐ data_out           
────►│1│                         │8├────►    
     │6│                         └┬┘         
     └┬┘                          │
      └───────────────────────────┘
```


To sum up things:

 - `system` declares a new circuit description.

 - `input` specifies one or several input ports, `output` one or several output ports, `inout` one or several input-output ports.

 - The data type of the port is given before the direction as follows:  

 ```ruby
 <type>.input <list of ports names>
 ```  

 We will give later more details about data types in HDLRuby.


Now let us try if your circuit description is all right with the following command:

```bash
hdrcc my_circuit.rb work
```

...Nothing happened? Great, that means that there were no syntax error in your description. Now let us try something else:

```bash
hdrcc --hdr my_circuit.rb work
```

If everything was OK, a file named `my_circuit.rb` should have appeared in the `work` directory. Open it with a text editor, its content should be the following:

```ruby
system :"__:T:0:1" do
   bit.input :clk
   bit.input :rst
   bit[15..0].input :addr
   bit.input :ce
   bit[7..0].input :data_in
   bit[7..0].output :data_out

end
```

It looks somewhat similar to the code you have just written? This is because it is the internal representation (IR) of your circuit in HDLRuby. You can see that the name of the circuit change to some weird character string, and that the data types also changed. For the name, this is for avoiding name clashes, so you do not need to be concerned about it. For the data types, those are actually the low level representation of the same data types that were used in the initial file. Still, this low level representation is very close to the original one, but that will be less and less the case as the features are added to the circuit.

Now, out of curiosity, how will look the equivalent Verilog HDL code? For checking that just type the following command:

```bash
hdrcc --verilog my_circuit.rb work
```

If everything was OK, a file named `my_circuit.v` should have appeared in the `work` directory. Open it with a text editor, its content should be the following:

```verilog
`timescale 1ps/1ps

module _v0_1( _v1_clk, _v2_rst, _v3_addr, _v4_data_in, _v5_data_out );
   input _v1_clk;
   input _v2_rst;
   input [15:0] _v3_addr;
   input _v4_ce;
   input [7:0] _v5_data_in;
   output [7:0] _v6_data_out;


endmodule
```

The syntax looks indeed a little bit different from HDLRuby, but you should be able to recognise the description of the circuit. The name of the ports is different though, this is because HDLRuby supports any UNICODE character for names and to avoid compatibility problem, recreates the names when generating Verilog. Still, an effort is made to keep the original name, e.g., `clk` became `_v1_clk`. But, just for the fun, please replace `:addr` in the HDLRuby file by `:☺` and regenerate Verilog HDL from it... It works! And the result is:

```verilog
`timescale 1ps/1ps

module _v0_1( _v1_clk, _v2_rst, _v3_, _v4_data_in, _v5_data_out );
   input _v1_clk;
   input _v2_rst;
   input [15:0] _v3_;
   input _v4_ce;
   input [7:0] _v5_data_in;
   output [7:0] _v6_data_out;


endmodule
```

Unfortunately, there is no more any smiling face. This is because Verilog HDL only supports a subset of ASCII for names. But even without smiling, the code is valid because the HDLRuby framework did recreate Verilog HDL friendly names.


### 2.2 How to reuse a circuit already declared <a name="circuit-use"></a>

Like with functions in software, a circuit is often used as part of one or several larger circuits. Contrary to software however, the circuit must be physically copied for being reused. This copy is called and *instance* and the act of copying an *instantiation*. In HDLRuby, an instantiation is done as follows:

```ruby
<circuit name>(:<copy name>)
```

For example, if you what to use to copies of the previously defined circuit `my_circuit` in a new circuit called `another_circuit` you can do as follows:

```ruby
system :another_circuit do
   input :clk, :rst
   [16].input :addr
   input :ce0, :ce1
   [8].input :data_in
   [8].output :data_out

   my_circuit(:my_circuit0)
   my_circuit(:my_circuit1)
end
```

For testing purpose, write the code above into another file called `another_circuit.rb`, and try to generate Verilog HDL from it:

```bash
hdrcc --verilog another_circuit.rb work
```

Oh, it appears that something went wrong since the following should have appeared:

```
another_circuit.rb:8:in `block in <main>': undefined HDLRuby construct, local variable or method `my_circuit'.
```

This error message indicates that `my_circuit` is not known. This is because, like the Ruby language, in HDLRuby you must specify the files your are using. Please add as first line in your `another_circuit.rb` file the following code:

```ruby
require_relative "my_circuit.rb"
```

Then retry the Verilog HDL generation command:

```bash
hdrcc --verilog another_circuit.rb work
```

Three new files should have appeared in the `work` directory: `_v10_5.v`, `_v8_4.v` and `another_circuit.v`. If you open the third file you should see:

```verilog
`timescale 1ps/1ps

module _v0_3( _v1_clk, _v2_rst, _v3_addr, _v4_ce0, _v5_ce1, _v6_data_in, _v7_data_out );
   input _v1_clk;
   input _v2_rst;
   input [15:0] _v3_addr;
   input _v4_ce0;
   input _v5_ce1;
   input [7:0] _v6_data_in;
   output [7:0] _v7_data_out;

   _v8_4 _v9_my_circuit0();
   _v10_5 _v11_my_circuit1();

endmodule
```

Again, we can see similarities between the resulting Verilog HDL code and the original HDLRuby one. Still, what are `_v8_4` and `_v10_5`? You can see them by opening the corresponding files `_v8_4.rb` and `_v10_5.rb`, those are actually the descriptions of `my_circuit` in Verilog HDL.

> __But why two of them?__ I would like to answer that this is because of a limitation of Verilog HDL, but this is not the case. Actually, it is because HDLRuby's instantiation mechanism is very different from the Verilog HDL (and the VHDL) one, so that for the moment, and only for easing the coding work of the HDLRuby compiler, one description of `my_circuit` is generated per instance.


Copying a circuit is easy, but it achieve no purpose if the copied circuit are not in relationship with their environment. It is where the ports become useful: they are the communication points between a circuit and its outside world. Concretely, in order to interact with a circuit, its ports must be connected to something that will interact with them. How this interaction work is a story for other sections, e.g., the one about [algorithms](#algorithm), about the [environement](#environment) and the one about [behaviors](#behavior). For now let us focus on connection: in HDLRuby this is done using the connection operator `<=` as follows:

 * For an input port of the current circuit:  
 ```ruby
 <something> <= <input port>
 ```

 * For an output port of the current circuit:
 ```ruby
 <output port> <= <something>
 ```

Many things can be connected to a port, but right now, we only know about ports, so let us do the connection in `another_circuit` with them. So here is the new code of `another_circuit.rb`, please modify the file accordingly:

```ruby
require_relative "my_circuit.rb"

system :another_circuit do
   input :clk, :rst
   [16].input :addr
   input :ce0, :ce1
   [8].input :data_in
   [8].output :data_out

   my_circuit(:my_circuit0)
   my_circuit(:my_circuit1)

   my_circuit0.clk  <= clk
   my_circuit0.rst  <= rst
   my_circuit0.addr <= addr
   my_circuit0.ce   <= ce0
   my_circuit0.data_in <= data_in

   my_circuit1.clk  <= clk
   my_circuit1.rst  <= rst
   my_circuit1.addr <= addr
   my_circuit1.ce   <= ce1
   my_circuit1.data_in <= data_in
end
```

If you are familiar with object oriented or structured software programming, this code should be straight forward: the dot `.` operator is used to access a sub element, and in this case the ports of `my_circuit0` and `my_circuit1`. For example, the first connection line (line 10) connects the `clk` port of `another_circuit` to the one of `my_circuit0`, so that any data that goes through the former port will also go through the latter.

Now, the `data_out` ports are still not connected. It may be tempting to connect them like `data_in` as follows:

```ruby
  data_out <= circuit0.data_out
  data_out <= circuit1.data_out
```

This will work indeed, but not the way you may think: in hardware you cannot normally connect to one port several different objects. It is like assigning several values at the **same** time to a single variable. What will happen in HDLRuby, is that only the last statement will be kept, i.e., port `data_out` of `circuit0` will not be connected.

With such kind of cases, what we often want to do is to connect to `data_out` some computation result between the output of `circuit0` and `circuit1`. This is the opportunity to see another kind of construct that can be connected to a port: an expression. Like in software, an expression represent an arithmetic and logic computation. For example let us consider the following connection:

```ruby
  data_out <= my_circuit0.data_out + my_circuit1.data_out
```

With this connection, the sum of the outputs `my_circuit0` and `my_circuit1` is transmitted trough the output port `data_out` of `another_circuit`.

> __But when is this computation perfomed?__ This is a very good question: while in software, programs are executed one instruction after the other, in hardware there is no such a thing as the execution of instruction. Actually, the expression connected to `data_out` is not an instruction at all! It is a description of a part of the circuit that specifies that an adder (a circuit that make addition) must be instantiated with the output ports `data_out` of `my_circuit0` and `my_circuit1` connected to its inputs and its output connected to the output port `data_out` of `another_circuit`. The following figures shows the schematic of this hardware portion:
   
```
┌────────────────────────────────────────────┐
│                                            │
│              another_circuit               │
│                                            │
│  ┌────────────────┐    ┌────────────────┐  │
│  │                │    │                │  │
│  │  my_circuit0   │    │  my_circuit1   │  │
│  │                │    │                │  │
│  │ data_out┌─┐    │    │    ┌─┐data_out │  │
│  └─────────┤8├────┘    └────┤8├─────────┘  │
│            └┬┘              └┬┘            │
│             │                │             │
│            ┌▼┐              ┌▼┐            │
│       ┌────┤8├──────────────┤8├───┐        │
│        \   └─┘              └─┘  /         │
│         \         Adder         /          │
│          \         ┌─┐         /           │
│           \────────┤8├────────/            │
│                    └┬┘                     │
│                     │                      │
│            data_out┌▼┐                     │
└────────────────────┤8├─────────────────────┘
                     └─┘
```

> __So, when this expression is executed?__ It is continuously executed, i.e., as soon as one of the outputs `data_out` of `my_circuit0` or `my_circuit1` changes, so does the output `data_out` of `another_circuit`.

For trying this new circuit, please update the code of `another_circuit.rb` as follows:

```ruby
require_relative "my_circuit.rb"

system :another_circuit do
   input :clk, :rst
   [16].input :addr
   input :ce0, :ce1
   [8].input :data_in
   [8].output :data_out

   my_circuit(:my_circuit0)
   my_circuit(:my_circuit1)

   my_circuit0.clk  <= clk
   my_circuit0.rst  <= rst
   my_circuit0.addr <= addr
   my_circuit0.ce   <= ce0
   my_circuit0.data_in <= data_in

   my_circuit1.clk  <= clk
   my_circuit1.rst  <= rst
   my_circuit1.addr <= addr
   my_circuit1.ce   <= ce1
   my_circuit1.data_in <= data_in

   data_out <= my_circuit0.data_out + my_circuit1.data_out
end
```

Then, let us generate again Verilog HDL from it:

```bash
hdrcc --verilog another_circuit.rb work
```

Oh! If you get the following error message:

```
another_circuit.rb:15:in `block in <main>': undefined method `addr' for #<HDLRuby::High::Namespace:<whatever number>>
```

Do not forget to replace the smiling face by `addr` in `my_circuit.rb`.

When the compile succeeds (no error message), two new files appear in `work`, namely `_v20_4.v` and `_v23_5.v`. Those are the new descriptions of `my_circuit`, they did not change really, but since new hardware have been added their name changed. For the interesting part, let us open again `another_circuit.v`, the result should be as follows:

```verilog
`timescale 1ps/1ps

module _v0_3( _v1_clk, _v2_rst, _v3_addr, _v4_ce0, _v5_ce1, _v6_data_in, _v7_data_out );
   input _v1_clk;
   input _v2_rst;
   input [15:0] _v3_addr;
   input _v4_ce0;
   input _v5_ce1;
   input [7:0] _v6_data_in;
   output [7:0] _v7_data_out;
   wire _v8_0;
   wire _v9_1;
   wire [15:0] _v10_2;
   wire _v11_3;
   wire [7:0] _v12_4;
   wire _v13_5;
   wire _v14_6;
   wire [15:0] _v15_7;
   wire _v16_8;
   wire [7:0] _v17_9;
   wire [7:0] _v18_10;
   wire [7:0] _v19_11;

      _v20_4 _v21_my_circuit0(._v1_clk(_v8_0),._v2_rst(_v9_1),._v3_addr(_v10_2),._v22_ce(_v11_3),._v6_data_in(_v12_4),._v7_data_out(_v18_10));
   _v23_5 _v24_my_circuit1(._v1_clk(_v13_5),._v2_rst(_v14_6),._v3_addr(_v15_7),._v22_ce(_v16_8),._v6_data_in(_v17_9),._v7_data_out(_v19_11));
   assign _v8_0 = _v1_clk;

   assign _v9_1 = _v2_rst;

   assign _v10_2 = _v3_addr;

   assign _v11_3 = _v4_ce0;

   assign _v12_4 = _v6_data_in;

   assign _v13_5 = _v1_clk;

   assign _v14_6 = _v2_rst;

   assign _v15_7 = _v3_addr;

   assign _v16_8 = _v5_ce1;

   assign _v17_9 = _v6_data_in;

   assign _v7_data_out = (_v18_10 + _v19_11);


endmodule
```

The code is starting to get complicated, and seemed to be much more different from the HDLRuby description than before. This is because this time, real syntactic limitations of Verilog HDL compared to HDLRuby have to be bypassed. Here, the limitation is that while in HDLRuby, ports can be connected wherever we want, in Verilog HDL, this must be done only while instantiating.

In fact, in HDLRuby too you can do the connection while instantiating, this is even recommended for a better readability of the code. There are two ways to do so: by position (like for the arguments of a function call) or by name. Let us see both by editing again `another_circuit.rb`: please just replace both instantiation lines by the followings:

```ruby
my_circuit(:my_circuit0).(clk,rst,addr,ce0,data_in,data_out)
my_circuit(:my_circuit1).(clk: clk, rst: rst, addr: addr, ce: ce1,
                          data_in: data_in, data_out: data_out)
```

The instantiation for `my_circuit0` does the connection by position, that is to say that each port given between the second parenthesis are connected in the order of declaration of in ports of `my_circuit.rb`. For `my_circuit1P the connection is done by name: then syntax `<name>: <something>` connects ports named `name` of the instance of `my_circuit` to `something`. For example `clk: clk` connects port `clk` of `my_circuit0` to port `clk` of `another_circuit`.


#### That's all for this section!

Now you know:

 * How to declare a new circuit with its name and ports in HDLRuby.

 * How to check it with hdrcc.

 * How to convert it to Verilog HDL.

 * How to reuse it into another circuit.

 * And even, how to describe computation some expressions and connect them to an output port.

But you still do not know: how to describe more complex computation, e.g., controls, and how to simulate a circuit. Let us start slowly (from the software person point of view) with how to describe an algorithm the simple way in HDLRuby.



## 3. How to describe an algorithm to be implemented by a circuit. <a name="algorithm"></a>

In this section we will see:

 * [How handle values in a circuit.](#signal)

 * [How to describe an algorithm that a circuit can implement.](#algorithm)

### 3.1. How to handle values in a circuit. <a name=signal></a>

In software, value handling looks straight forward enough: they are computed with expressions and are stored into variables. However, what a variable is highly depends on what language you use... And this is exactly the same in hardware: there is some construct that can be considered as variable but the way they work is different depending on the language that is used, e.g., Verilog HDL, VHDL, or in our case HDLRuby. Fortunately, there is a concept that is the same for these three language: the signal.

Like a variable a signal has a data type and holds a value of this type. However, in hardware, there is not such a thing as assignment for changing the value.


### 3.2. How to describe an algorithm that a circuit can implement. <a name=algorithm></a>
