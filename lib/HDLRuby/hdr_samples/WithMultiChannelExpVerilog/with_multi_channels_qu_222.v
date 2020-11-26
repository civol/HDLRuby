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
   wire _00003a13;
   wire [1:0] _00003a14;
   reg _00003a8;
   wire [7:0] _00003a9;
   reg [1:0] _00003a10;
   reg _00003a11;
   reg [7:0] _00003a12  [0:2];
   wire [7:0] _00003a4;
   wire _00003a5;
   wire [1:0] _00003a6;
   reg [7:0] _00003a7  [0:2];
   reg _00003a1;
   reg [1:0] _00003a2;
   reg _00003a3;
   reg [7:0] my__ch_00003a0_00003a_00003abuffer  [0:2];
   reg [1:0] my__ch_00003a0_00003a_00003arptr;
   reg [1:0] my__ch_00003a0_00003a_00003awptr;
   wire my__ch_00003a0_00003a_00003arreq;
   wire my__ch_00003a0_00003a_00003awreq;
   reg my__ch_00003a0_00003a_00003arack;
   reg my__ch_00003a0_00003a_00003awack;
   reg [7:0] my__ch_00003a0_00003a_00003ardata;
   wire [7:0] my__ch_00003a0_00003a_00003awdata;
   wire my__ch_00003a0_00003a_00003arsync;
   wire my__ch_00003a0_00003a_00003awsync;

   assign _00003a13 = my__ch_00003a0_00003a_00003awack;

   assign _00003a14 = my__ch_00003a0_00003a_00003arptr;

   assign _00003a8 = my__ch_00003a0_00003a_00003awreq;

   assign _00003a9 = my__ch_00003a0_00003a_00003awdata;

   assign _00003a10 = my__ch_00003a0_00003a_00003awptr;

   assign _00003a11 = my__ch_00003a0_00003a_00003awsync;

   assign _00003a12 = my__ch_00003a0_00003a_00003abuffer;

   assign _00003a4 = my__ch_00003a0_00003a_00003ardata;

   assign _00003a5 = my__ch_00003a0_00003a_00003arack;

   assign _00003a6 = my__ch_00003a0_00003a_00003awptr;

   assign _00003a7 = my__ch_00003a0_00003a_00003abuffer;

   assign _00003a1 = my__ch_00003a0_00003a_00003arreq;

   assign _00003a2 = my__ch_00003a0_00003a_00003arptr;

   assign _00003a3 = my__ch_00003a0_00003a_00003arsync;

   always @( posedge clk2 ) begin

      _00003a11 <= 32'd1;

      _00003a8 <= 32'd0;

      if (rst) begin
         idata <= 32'd0;
      end
      else begin
         if ((((_00003a10 + 32'd1) % 32'd3) != _00003a14)) begin
            _00003a12[_00003a10] <= idata;
            _00003a10 <= ((_00003a10 + 32'd1) % 32'd3);
            idata <= (idata + 32'd1);
         end
      end

   end

   always @( posedge clk2 ) begin

      _00003a3 <= 32'd1;

      _00003a1 <= 32'd0;

      if (rst) begin
         counter <= 32'd0;
      end
      else begin
         if ((_00003a2 != _00003a6)) begin
            odata <= _00003a7[_00003a2];
            _00003a2 <= ((_00003a2 + 32'd1) % 32'd3);
            counter <= (counter + 32'd1);
         end
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

   always @( posedge clk2 ) begin

      if (rst) begin
         my__ch_00003a0_00003a_00003arptr <= 32'd0;
         my__ch_00003a0_00003a_00003awptr <= 32'd0;
      end
      else begin
         if (~my__ch_00003a0_00003a_00003arsync) begin
            if (~my__ch_00003a0_00003a_00003arreq) begin
               my__ch_00003a0_00003a_00003arack <= 32'd0;
            end
            if (((my__ch_00003a0_00003a_00003arreq & ~my__ch_00003a0_00003a_00003arack) & (my__ch_00003a0_00003a_00003arptr != my__ch_00003a0_00003a_00003awptr))) begin
               my__ch_00003a0_00003a_00003ardata <= my__ch_00003a0_00003a_00003abuffer[my__ch_00003a0_00003a_00003arptr];
               my__ch_00003a0_00003a_00003arptr <= ((my__ch_00003a0_00003a_00003arptr + 32'd1) % 32'd3);
               my__ch_00003a0_00003a_00003arack <= 32'd1;
            end
         end
         if (~my__ch_00003a0_00003a_00003awsync) begin
            if (~my__ch_00003a0_00003a_00003awreq) begin
               my__ch_00003a0_00003a_00003awack <= 32'd0;
            end
            if (((my__ch_00003a0_00003a_00003awreq & ~my__ch_00003a0_00003a_00003awack) & (((my__ch_00003a0_00003a_00003awptr + 32'd1) % 32'd3) != my__ch_00003a0_00003a_00003arptr))) begin
               my__ch_00003a0_00003a_00003abuffer[my__ch_00003a0_00003a_00003awptr] <= my__ch_00003a0_00003a_00003awdata;
               my__ch_00003a0_00003a_00003awptr <= ((my__ch_00003a0_00003a_00003awptr + 32'd1) % 32'd3);
               my__ch_00003a0_00003a_00003awack <= 32'd1;
            end
         end
      end

   end

endmodule