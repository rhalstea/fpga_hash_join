`timescale 1 ns / 1 ps

module engine (
   input                      clk,
   input                      rst,
   output                     done,

   input    [63:0]            num_rows_in,
   input    [63:0]            row_start_in,
   input    [63:0]            row_skip_in,
   input    [63:0]            rows_size_in,           // size is passed in bytes
   input    [63:0]            hash_mask_in,

   input                      row_rq_stall_in,
   output                     row_rq_vld_out,
   output   [47:0]            row_rq_vadr_out,
   output                     row_rs_stall_out,
   input                      row_rs_vld_in,
   input    [63:0]            row_rs_data_in,

   input                      ht_rq_afull_in,
   output                     ht_rq_vld_out,
   output   [47:0]            ht_rq_address_out,
   output                     ht_rs_afull_out,
   input                      ht_rs_write_en_in,
   input    [63:0]            ht_rs_data_in,

   input                      ll_rq_0_afull_in,
   output                     ll_rq_0_vld_out,
   output   [47:0]            ll_rq_0_address_out,
   output                     ll_rs_0_afull_out,
   input                      ll_rs_0_write_en_in,
   input    [63:0]            ll_rs_0_data_in,
   
   input                      ll_rq_1_afull_in,
   output                     ll_rq_1_vld_out,
   output   [47:0]            ll_rq_1_address_out,
   output                     ll_rs_1_afull_out,
   input                      ll_rs_1_write_en_in,
   input    [63:0]            ll_rs_1_data_in,

   output                     output_empty_out,
   input                      output_read_en_in,
   output   [63:0]            output_dim_table_out,
   output   [63:0]            output_fact_table_out
);

   wire                       stream_done_s;
   wire                       stream_empty_s;
   wire                       stream_read_en_s;
   wire  [63:0]               stream_value_s;
   wire  [63:0]               stream_hash_s;
   wire  [47:0]               stream_rq_vadr_s;

   wire                       probe_phase_done_s;
   wire                       probe_phase_afull_s;
   wire  [47:0]               probe_phase_ht_rq_addr_s;
   wire  [47:0]               probe_phase_ll_rq_addr_s;
   wire                       probe_phase_output_empty_s;
   wire                       probe_phase_output_read_en_s;
   wire  [63:0]               probe_phase_output_dim_table_s;
   wire  [63:0]               probe_phase_output_fact_table_s;

   filter_rows STREAM (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (stream_done_s),

      .num_rows_in            (num_rows_in),
      .row_start_in           (row_start_in),
      .row_skip_in            (row_skip_in),
      .rows_size_in           (rows_size_in),
      .hash_mask_in           (hash_mask_in),

      .output_empty_out       (stream_empty_s),
      .output_read_en_in      (stream_read_en_s),
      .output_value_out       (stream_value_s),
      .output_hash_out        (stream_hash_s),

      .row_rq_stall_in        (row_rq_stall_in),
      .row_rq_vld_out         (row_rq_vld_out),
      .row_rq_vadr_out        (row_rq_vadr_out),
      .row_rs_stall_out       (row_rs_stall_out),
      .row_rs_vld_in          (row_rs_vld_in),
      .row_rs_data_in         (row_rs_data_in)
   );
   assign stream_read_en_s = !stream_empty_s && !probe_phase_afull_s;


   probe_phase PROBE_PHASE (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (probe_phase_done_s),
      .row_afull_out          (probe_phase_afull_s),
      .row_write_en_in        (stream_read_en_s),
      .row_value_in           (stream_value_s),
      .row_hash_value_in      (stream_hash_s),

      .ht_rq_afull_in         (ht_rq_afull_in),
      .ht_rq_vld_out          (ht_rq_vld_out),
      .ht_rq_address_out      (ht_rq_address_out),
      .ht_rs_afull_out        (ht_rs_afull_out),
      .ht_rs_write_en_in      (ht_rs_write_en_in),
      .ht_rs_data_in          (ht_rs_data_in),

      .ll_rq_0_afull_in       (ll_rq_0_afull_in),
      .ll_rq_0_vld_out        (ll_rq_0_vld_out),
      .ll_rq_0_address_out    (ll_rq_0_address_out),
      .ll_rs_0_afull_out      (ll_rs_0_afull_out),
      .ll_rs_0_write_en_in    (ll_rs_0_write_en_in),
      .ll_rs_0_data_in        (ll_rs_0_data_in),

      .ll_rq_1_afull_in       (ll_rq_1_afull_in),
      .ll_rq_1_vld_out        (ll_rq_1_vld_out),
      .ll_rq_1_address_out    (ll_rq_1_address_out),
      .ll_rs_1_afull_out      (ll_rs_1_afull_out),
      .ll_rs_1_write_en_in    (ll_rs_1_write_en_in),
      .ll_rs_1_data_in        (ll_rs_1_data_in),

      .output_empty_out       (output_empty_out),
      .output_read_en_in      (output_read_en_in),
      .output_dim_table_out   (output_dim_table_out),
      .output_fact_table_out  (output_fact_table_out)
   );

   assign done = stream_done_s && probe_phase_done_s;

endmodule

