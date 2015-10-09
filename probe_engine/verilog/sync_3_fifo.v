`timescale 1 ns / 1 ps

module sync_3_fifo (
   input                      clk,
   input                      rst,

   output   [2:0]             afull_out,
   input    [2:0]             write_en_in,
   input    [63:0]            data_2_in,
   input    [63:0]            data_1_in,
   input    [63:0]            data_0_in,

   output                     empty_out,
   input                      read_en_in,
   output   [63:0]            data_2_out,
   output   [63:0]            data_1_out,
   output   [63:0]            data_0_out
);

//   localparam FIFO_DEPTH  = 512;

   wire  [2:0]                fifo_empty_s;

//   generic_fifo #(
//      .DATA_WIDTH       (64),
//      .DATA_DEPTH       (FIFO_DEPTH),
//      .AFULL_POS        (FIFO_DEPTH-12)
//   ) FIFO_0 (
//      .clk              (clk),
//      .rst              (rst),
//      .afull_out        (afull_out[0]),
//      .write_en_in      (write_en_in[0]),
//      .data_in          (data_0_in),
//      .empty_out        (fifo_empty_s[0]),
//      .read_en_in       (read_en_in),
//      .data_out         (data_0_out)
//   );

//   generic_fifo #(
//      .DATA_WIDTH       (64),
//      .DATA_DEPTH       (FIFO_DEPTH),
//      .AFULL_POS        (FIFO_DEPTH-12)
//   ) FIFO_1 (
//      .clk              (clk),
//      .rst              (rst),
//      .afull_out        (afull_out[1]),
//      .write_en_in      (write_en_in[1]),
//      .data_in          (data_1_in),
//      .empty_out        (fifo_empty_s[1]),
//      .read_en_in       (read_en_in),
//      .data_out         (data_1_out)
//   );

//   generic_fifo #(
//      .DATA_WIDTH       (64),
//      .DATA_DEPTH       (FIFO_DEPTH),
//      .AFULL_POS        (FIFO_DEPTH-12)
//   ) FIFO_2 (
//      .clk              (clk),
//      .rst              (rst),
//      .afull_out        (afull_out[2]),
//      .write_en_in      (write_en_in[2]),
//      .data_in          (data_2_in),
//      .empty_out        (fifo_empty_s[2]),
//      .read_en_in       (read_en_in),
//      .data_out         (data_2_out)
//   );

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

   fifo_64x512 FIFO_2 (
      .clk                    (clk),
      .rst                    (rst),
      .din                    (data_2_in),
      .wr_en                  (write_en_in[2]),
      .rd_en                  (read_en_in),
      .dout                   (data_2_out),
      .full                   (),
      .empty                  (fifo_empty_s[2]),
      .prog_full              (afull_out[2])
   );


   assign empty_out = (fifo_empty_s != 3'd0);


endmodule

