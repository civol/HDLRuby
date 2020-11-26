`timescale 1ps/1ps

module _____00003aT0( ); 
   reg rst;
   reg clk1;
   reg clk2;
   reg clk3;
   reg [7:0] idata;
   reg [7:0] odata;
   wire [7:0] odata2;
   reg [3:0] counter;
   reg [7:0] _00003a2;
   wire [7:0] _00003a1;
   wire [7:0] my__ch_00003a0_00003a_00003abuffer;

   assign _00003a2 = my__ch_00003a0_00003a_00003abuffer;

   assign _00003a1 = my__ch_00003a0_00003a_00003abuffer;

   always @( posedge clk2 ) begin

      if (rst) begin
         idata <= 32'd0;
      end
      else begin
         _00003a2 <= idata;
         idata <= (idata + 32'd1);
      end

   end

   always @( posedge clk3 ) begin

      if (rst) begin
         counter <= 32'd0;
      end
      else begin
         odata <= _00003a1;
         counter <= (counter + 32'd1);
      end

   end

   initial begin

      clk1 = 32'd0;

      clk2 = 32'd0;

      clk3 = 32'd0;

      rst = 32'd0;

      #10000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      rst = 32'd1;

      #3000

      clk2 = 32'd1;

      #3000

      clk3 = 32'd0;

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = 32'd0;

      #3000

      clk3 = 32'd1;

      #2000

      rst = 32'd0;

      #2000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

      clk1 = 32'd1;

      #10000

      clk1 = 32'd0;

      #3000

      clk2 = ~clk2;

      #3000

      if ((clk2 == 32'd0)) begin
         clk3 = ~clk3;
      end

      #4000

   end

endmodule