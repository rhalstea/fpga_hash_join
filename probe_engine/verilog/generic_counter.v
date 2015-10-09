`timescale 1 ns / 1 ps

module generic_counter (
   input                      clk,
   input                      rst,
   output                     done,

   input    [63:0]            start_in,
   input    [63:0]            end_in,
   input    [63:0]            step_in,

   input                      read_in,
   output   [63:0]            count_out
);

   reg   [63:0]               counter_s;

   always @(posedge clk)
   begin
      if (rst == 1'd1)
         counter_s <= start_in;
      else if (read_in == 1'd1)
         counter_s <= counter_s + step_in;
   end

   assign count_out = counter_s;
   assign done = counter_s >= end_in;

endmodule
