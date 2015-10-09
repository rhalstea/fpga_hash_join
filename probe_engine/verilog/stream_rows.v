`timescale 1 ns / 1 ps

// This component will be given the number of rows, and the size of each row
// (assume each row is the same size). With this information it will request
// all rows, and filter out the column of interest. 
 
module stream_rows (
   input                clk,
   input                rst,
   output               done,

   input    [63:0]      num_rows_in,
   input    [63:0]      rows_size_in,  // size is passed in bytes

   input    [63:0]      row_start_in,  // what row should it start at
   input    [63:0]      row_skip_in,   // how many rows should be skipped when
                                       // incrementing

   output               output_empty_out,
   input                output_read_en_in,
   output   [63:0]      output_value_out,

   input                row_rq_stall_in,
   output               row_rq_vld_out,
   output   [47:0]      row_rq_vadr_out,

   output               row_rs_stall_out,
   input                row_rs_vld_in,
   input    [63:0]      row_rs_data_in
);

   wire                       curr_row_done_s;
   reg   [7:0]                curr_row_done_hold_s;
   wire                       curr_row_read_en_s;
   wire  [63:0]               curr_row_data_out_s;

   wire                       req_fifo_afull_s;
   wire                       req_fifo_empty_s;

   wire  [47:0]               row_base_address_s;

   wire                       mem_rq_vld_s;
   wire  [47:0]               mem_rq_addr_s;
   wire                       mem_rq_out_done_s;

   wire                       row_fifo_empty_s;
   


   // The counter will tell us how many rows we need to request.
   generic_counter CURR_ROW (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (curr_row_done_s),
      .start_in               (row_start_in),
      .end_in                 (num_rows_in),
      .step_in                (row_skip_in),
      .read_in                (curr_row_read_en_s),
      .count_out              (curr_row_data_out_s)
   );
   assign curr_row_read_en_s = !rst && !req_fifo_afull_s && !curr_row_done_s;

   always @(posedge clk)
   begin
      curr_row_done_hold_s <= {curr_row_done_hold_s[6:0], curr_row_done_s};
   end

   wire                       curr_row_read_en_reg;
   wire  [47:0]               curr_row_data_out_reg;
   wire  [47:0]               curr_row_size_out_reg;

   generic_register_chain #(
      .DATA_WIDTH             (1),
      .CHAIN_LENGTH           (6)
   ) RE_CHAIN (
      .clk                    (clk),
      .rst                    (rst),
      .data_in                (curr_row_read_en_s),
      .data_out               (curr_row_read_en_reg)
   );

   generic_register_chain #(
      .DATA_WIDTH             (48),
      .CHAIN_LENGTH           (5)
   ) DATA_CHAIN (
      .clk                    (clk),
      .rst                    (rst),
      .data_in                (curr_row_data_out_s[47:0]),
      .data_out               (curr_row_data_out_reg)
   );

//   generic_register_chain #(
//      .DATA_WIDTH             (48),
//      .CHAIN_LENGTH           (5)
//   ) SIZE_CHAIN (
//      .clk                    (clk),
//      .rst                    (rst),
//      .data_in                (rows_size_in[47:0]),
//      .data_out               (curr_row_size_out_reg)
//   );

   // For each row we need to compute where it starts from. For simplicity
   // I calculate the base address in Bytes. However, the memory request has
   // to be word addressable (64-bits).
   mul_48 ROW_BASE (
      .clk                    (clk),
      .a                      (curr_row_data_out_reg),
      .b                      (rows_size_in[47:0]),
      .p                      (row_base_address_s)
   );
   
   generic_fifo #(
      .DATA_WIDTH             (48),
      .DATA_DEPTH             (32),
      .AFULL_POS              (12)
   ) REQ_FIFO (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (req_fifo_afull_s),
      .write_en_in            (curr_row_read_en_reg),
      .data_in                ({3'd0, row_base_address_s[47:3]}),
      .empty_out              (req_fifo_empty_s),
      .read_en_in             (mem_rq_vld_s),
      .data_out               (mem_rq_addr_s)
   );
   assign mem_rq_vld_s = !req_fifo_empty_s && !row_rq_stall_in;

   outstanding_requests MEM_RQ_OUT (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (mem_rq_out_done_s),
      .rq_vld_in              (mem_rq_vld_s),
      .rs_vld_in              (row_rs_vld_in)
   );

   assign row_rq_vld_out      = mem_rq_vld_s;
   assign row_rq_vadr_out     = mem_rq_addr_s;

   generic_fifo #(
      .DATA_WIDTH             (64),
      .DATA_DEPTH             (32),
      .AFULL_POS              (24)
   ) ROW_FIFO (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (row_rs_stall_out),
      .write_en_in            (row_rs_vld_in),
      .data_in                (row_rs_data_in),
      .empty_out              (row_fifo_empty_s),
      .read_en_in             (output_read_en_in),
      .data_out               (output_value_out)
   );
   assign output_empty_out = row_fifo_empty_s;

   assign done = (curr_row_done_hold_s == 8'hFF) && req_fifo_empty_s && 
                  mem_rq_out_done_s && row_fifo_empty_s;

endmodule
