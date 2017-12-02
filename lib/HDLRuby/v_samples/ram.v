/* Description of an 8-bit data 16-bit address asynchronous ram. */

module ram(en,rwb,addr,data);

    input       en,rwb;
    input[15:0] addr;
    inout [7:0] data;

    reg [7:0] content[0:65535];

    assign data = (en & rwb) == 1 ? content[addr] : 8'bzzzzzzzz;

    always @ (*)
    begin
        if ((en & ~rwb) == 1) begin
            content[addr] <= data;
        end
    end

endmodule
