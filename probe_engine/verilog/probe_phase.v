`timescale 1ns / 1ps

module probe_phase (
   input                      clk,
   input                      rst,
   output                     done,

   output                     row_afull_out,
   input                      row_write_en_in,
   input [63:0]               row_value_in,
   input [63:0]               row_hash_value_in,

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

   wire  [1:0]                row_fifo_afull_s;
   wire                       row_fifo_empty_s;
   wire                       row_fifo_read_en_s;
   wire  [63:0]               row_fifo_value_s;
   wire  [63:0]               row_fifo_hash_value_s;

   wire  [1:0]                new_job_afull_s;
   wire                       new_job_empty_s;
   wire  [63:0]               new_job_row_value_s;
   wire  [63:0]               new_job_row_ptr_s;

   wire                       search_new_job_read_en_s;
   wire                       search_done_s;


   sync_2_fifo ROW_FIFO (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (row_fifo_afull_s),
      .write_en_in            ({row_write_en_in, row_write_en_in}),
      .data_1_in              (row_value_in),
      .data_0_in              (row_hash_value_in),
      .empty_out              (row_fifo_empty_s),
      .read_en_in             (row_fifo_read_en_s),
      .data_1_out             (row_fifo_value_s),
      .data_0_out             (row_fifo_hash_value_s)
   );
   assign row_afull_out = (row_fifo_afull_s != 2'd0);


   // Phase 1 -- Read the hash table to get the head pointer. This is a new
   //             job that can enter the engine.
   assign row_fifo_read_en_s  = !row_fifo_empty_s && !ht_rq_afull_in && !new_job_afull_s[1];
   assign ht_rq_vld_out       = row_fifo_read_en_s;
   assign ht_rq_address_out   = row_fifo_hash_value_s[47:0];

   sync_2_fifo NEW_JOBS (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (new_job_afull_s),
      .write_en_in            ({row_fifo_read_en_s,  ht_rs_write_en_in}),
      .data_1_in              (row_fifo_value_s),
      .data_0_in              (ht_rs_data_in),
      .empty_out              (new_job_empty_s),
      .read_en_in             (search_new_job_read_en_s),
      .data_1_out             (new_job_row_value_s),
      .data_0_out             (new_job_row_ptr_s)
   );
   assign ht_rs_afull_out  = new_job_afull_s[0];


   wire                       new_job_rq_out_done_s;
   outstanding_requests NEW_JOB_RQ_OUT (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (new_job_rq_out_done_s),
      .rq_vld_in              (row_fifo_read_en_s),
      .rs_vld_in              (ht_rs_write_en_in)
   );


   // Phase 2 -- Search through the linked list for a match
   search_list SEARCH (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (search_done_s),

      .new_job_empty_in       (new_job_empty_s),
      .new_job_read_en_out    (search_new_job_read_en_s),
      .new_job_value_in       (new_job_row_value_s),
      .new_job_pointer_in     (new_job_row_ptr_s),

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


   assign done = row_fifo_empty_s && new_job_empty_s && new_job_rq_out_done_s && search_done_s;

endmodule

