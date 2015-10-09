`timescale 1 ns / 1 ps

module engine (
   input                      clk,
   input                      rst,
   output                     done,

   input    [63:0]            num_rows_in,
   input    [63:0]            rows_size_in,  // size is passed in bytes

   input    [63:0]            row_start_in,  // what row should it start at
   input    [63:0]            row_skip_in,   // how many rows should be skipped when
                                             // incrementing
   input    [63:0]            hash_table_mask,

   input                      row_rq_stall_in,
   output                     row_rq_vld_out,
   output   [47:0]            row_rq_vadr_out,
   output                     row_rs_stall_out,
   input                      row_rs_vld_in,
   input    [63:0]            row_rs_data_in,

   input                      ll_afull_in,
   output                     ll_write_en_out,
   output   [47:0]            ll_address_out,
   output   [63:0]            ll_payload_out,

   input                      ht_rq_afull_in,
   output                     ht_rq_read_en_out, 
   output   [47:0]            ht_rq_address_out,
   output   [63:0]            ht_rq_data_out,
   output                     ht_rs_afull_out,
   input                      ht_rs_write_en_in,
   input    [63:0]            ht_rs_data_in,

   input                      ll_update_afull_in,
   output                     ll_update_write_en_out,
   output   [47:0]            ll_update_addr_out,
   output   [63:0]            ll_update_data_out,

   input                      ll_rs_write_en_in
);

   wire                       rows_done_s;
   wire                       rows_output_empty_s;
   wire  [63:0]               rows_output_value_s;
   wire                       rows_read_en_s;

   wire                       build_done_s;
   wire                       build_row_afull_s;


   stream_rows ROWS (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (rows_done_s),
      .num_rows_in            (num_rows_in),
      .rows_size_in           (rows_size_in),
      .row_start_in           (row_start_in),
      .row_skip_in            (row_skip_in),
      .output_empty_out       (rows_output_empty_s),
      .output_read_en_in      (rows_read_en_s),
      .output_value_out       (rows_output_value_s),
      .row_rq_stall_in        (row_rq_stall_in),
      .row_rq_vld_out         (row_rq_vld_out),
      .row_rq_vadr_out        (row_rq_vadr_out),
      .row_rs_stall_out       (row_rs_stall_out),
      .row_rs_vld_in          (row_rs_vld_in),
      .row_rs_data_in         (row_rs_data_in)
   );

   assign rows_read_en_s = !rows_output_empty_s && !build_row_afull_s;

   build_phase BUILD (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (build_done_s),
      .row_start_in           (row_start_in),
      .row_skip_in            (row_skip_in),
      .hash_table_mask        (hash_table_mask),
      .row_afull_out          (build_row_afull_s),
      .row_write_en_in        (rows_read_en_s),
      .row_value_in           (rows_output_value_s),
      .ll_afull_in            (ll_afull_in),
      .ll_write_en_out        (ll_write_en_out),
      .ll_address_out         (ll_address_out),
      .ll_payload_out         (ll_payload_out),
      .ht_rq_afull_in         (ht_rq_afull_in),
      .ht_rq_read_en_out      (ht_rq_read_en_out), 
      .ht_rq_address_out      (ht_rq_address_out),
      .ht_rq_data_out         (ht_rq_data_out),
      .ht_rs_afull_out        (ht_rs_afull_out),
      .ht_rs_write_en_in      (ht_rs_write_en_in),
      .ht_rs_data_in          (ht_rs_data_in),
      .ll_update_afull_in     (ll_update_afull_in),
      .ll_update_write_en_out (ll_update_write_en_out),
      .ll_update_addr_out     (ll_update_addr_out),
      .ll_update_data_out     (ll_update_data_out),
      .ll_rs_write_en_in      (ll_rs_write_en_in)
   );


   assign done = rows_done_s && build_done_s;

endmodule
