`timescale 1 ns / 1 ps

// This component will read in a column of interest, and hash the value.
 
module hash_phase (
   input                      clk,
   input                      rst,
   output                     done,

   input    [63:0]            hash_mask_in,

   output                     afull_out,
   input                      write_en_in,
   input    [63:0]            value_in,

   output                     empty_out,
   input                      read_en_in,
   output   [63:0]            value_out,
   output   [63:0]            hash_out
);

   wire                       function_valid_out_s;
   wire  [63:0]               function_data_out_s;
   hash_function FUNCTION (
      .clk                    (clk),
      .rst                    (rst),
      .valid_in               (write_en_in),
      .data_in                ({32'd0, value_in[63:32]}),
      .valid_out              (function_valid_out_s),
      .data_out               (function_data_out_s)
   );

   wire  [1:0]                fifo_afull_s;
   wire                       fifo_empty_s;
   wire  [63:0]               hash_fifo_data_out_s;

   sync_2_fifo FIFO ( 
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (fifo_afull_s),
      .write_en_in            ({write_en_in, function_valid_out_s}),
      .data_1_in              (value_in),
      .data_0_in              (function_data_out_s),
      .empty_out              (fifo_empty_s),
      .read_en_in             (read_en_in),
      .data_1_out             (value_out),
      .data_0_out             (hash_fifo_data_out_s)
   );

   assign hash_out   = hash_fifo_data_out_s & hash_mask_in;

   assign afull_out  = (fifo_afull_s != 2'd0);
   assign empty_out  = fifo_empty_s;
   assign done       = fifo_empty_s;

endmodule

