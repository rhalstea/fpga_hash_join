`timescale 1 ns / 1 ps

// This component will be given the number of rows, and the size of each row
// (assume each row is the same size). With this information it will request
// all rows, and filter out the column of interest. 
 
module filter_rows (
   input                clk,
   input                rst,
   output               done,

   input    [63:0]      num_rows_in,
   input    [63:0]      row_start_in,
   input    [63:0]      row_skip_in,
   input    [63:0]      rows_size_in,        // size is passed in bytes
   input    [63:0]      hash_mask_in,


   output               output_empty_out,
   input                output_read_en_in,
   output   [63:0]      output_value_out,
   output   [63:0]      output_hash_out,

   input                row_rq_stall_in,
   output               row_rq_vld_out,
   output   [47:0]      row_rq_vadr_out,
   output               row_rs_stall_out,
   input                row_rs_vld_in,
   input    [63:0]      row_rs_data_in
);

   wire                          rows_done_s;
   wire                          rows_output_empty_s;
   wire  [63:0]                  rows_output_value_s;
   wire                          rows_read_en_s;

   wire                          hash_done_s;
   wire                          hash_afull_s;

   stream_rows ROWS_0 (
      .clk                       (clk),
      .rst                       (rst),
      .done                      (rows_done_s),
      .num_rows_in               (num_rows_in),
      .rows_size_in              (rows_size_in),            // size is passed in bytes
      .row_start_in              (row_start_in),
      .row_skip_in               (row_skip_in),
      .output_empty_out          (rows_output_empty_s),
      .output_read_en_in         (rows_read_en_s),
      .output_value_out          (rows_output_value_s), 
      .row_rq_stall_in           (row_rq_stall_in),
      .row_rq_vld_out            (row_rq_vld_out),
      .row_rq_vadr_out           (row_rq_vadr_out),
      .row_rs_stall_out          (row_rs_stall_out),
      .row_rs_vld_in             (row_rs_vld_in),
      .row_rs_data_in            (row_rs_data_in)
   );

   assign rows_read_en_s = !hash_afull_s && !rows_output_empty_s;

   hash_phase HASH (
      .clk                       (clk),
      .rst                       (rst),
      .done                      (hash_done_s),
      .hash_mask_in              (hash_mask_in),
      .afull_out                 (hash_afull_s),
      .write_en_in               (rows_read_en_s),
      .value_in                  (rows_output_value_s),
      .empty_out                 (output_empty_out),
      .read_en_in                (output_read_en_in),
      .value_out                 (output_value_out),
      .hash_out                  (output_hash_out)
   );

   assign done = rows_done_s && hash_done_s;

endmodule
