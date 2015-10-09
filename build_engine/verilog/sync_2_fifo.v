`timescale 1 ns / 1 ps

module sync_2_fifo (
   input                      clk,
   input                      rst,

   output   [1:0]             afull_out,
   input    [1:0]             write_en_in,
   input    [63:0]            data_1_in,
   input    [63:0]            data_0_in,

   output                     empty_out,
   input                      read_en_in,
   output   [63:0]            data_1_out,
   output   [63:0]            data_0_out
);

   wire  [1:0]                fifo_empty_s;

   fifo_64x512 FIFO_0 (
      .clk                    (clk),
      .rst                    (rst),
      .din                    (data_0_in),
      .wr_en                  (write_en_in[0]),
      .rd_en                  (read_en_in),
      .dout                   (data_0_out),
      .full                   (),
      .empty                  (fifo_empty_s[0]),
      .prog_full              (afull_out[0])
   );

   fifo_64x512 FIFO_1 (
      .clk                    (clk),
      .rst                    (rst),
      .din                    (data_1_in),
      .wr_en                  (write_en_in[1]),
      .rd_en                  (read_en_in),
      .dout                   (data_1_out),
      .full                   (),
      .empty                  (fifo_empty_s[1]),
      .prog_full              (afull_out[1])
   );

   assign empty_out = (fifo_empty_s != 2'd0);

endmodule

