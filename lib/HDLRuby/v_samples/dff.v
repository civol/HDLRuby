/* Description of a D-FF. */

module dff(clk,d,q);

    input clk,d;
    output q;

    always @ (posedge clk) begin
        q <= d & ~rst;
    end

endmodule
