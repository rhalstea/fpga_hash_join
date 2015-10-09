`timescale 1 ns / 1 ps

module outstanding_requests (
   input                      clk,
   input                      rst,
   output                     done,
   input                      rq_vld_in,
   input                      rs_vld_in
);

   reg   [63:0]               rq_count_s;
   reg   [63:0]               rs_count_s;

   always @(posedge clk)
   begin
      if (rst == 1)              rq_count_s <= 64'd0;
      else if (rq_vld_in == 1)   rq_count_s <= rq_count_s + 64'd1;

      if (rst == 1)              rs_count_s <= 64'd0;
      else if (rs_vld_in == 1)   rs_count_s <= rs_count_s + 64'd1;

   end

   assign done = (rq_count_s == rs_count_s);

endmodule
