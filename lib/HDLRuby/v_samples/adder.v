/* Description of an adder. */

module adder(x,y,s);

    input [7:0]  x,y;
    output[7:0]  s;

    assign s = x + y;

endmodule
