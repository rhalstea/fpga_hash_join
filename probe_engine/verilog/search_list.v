`timescale 1 ns / 1 ps

module search_list (
   input                      clk,
   input                      rst,
   output                     done,

   input                      new_job_empty_in,
   output                     new_job_read_en_out,
   input    [63:0]            new_job_value_in,
   input    [63:0]            new_job_pointer_in,


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

   // Searching though the Linked list will start with new jobs. Here we look
   // at the incomming jobs, and decide if the pointer location is valid. The
   // only invalid pointer location is 64'hFFFF_FFFF_FFFF_FFFF.
   localparam  LL_IDLE        = 3'd0,
               LL_READ_OLD    = 3'd1,
               LL_READ_NEW    = 3'd2;

   reg   [2:0]                ll_rq_curr_state;
   reg   [2:0]                ll_rq_next_state;
//   reg   [2:0]                ll_rs_curr_state;
//   reg   [2:0]                ll_rs_next_state;

   wire                       new_job_valid_s;
   wire                       new_job_ready_s;

   wire                       ll_rq_read_en_s;
   wire  [47:0]               ll_rq_address_s;
   wire  [63:0]               ll_rq_value_s;
//   reg   [47:0]               ll_addr_base_s;
//   reg   [47:0]               ll_addr_offset_s;
//
//   wire                       curr_job_rq_valid_s;
//   reg   [63:0]               curr_job_rq_id_s;
//   reg   [63:0]               curr_job_rq_value_s;

   wire                       rq_0_out_done_s;
   wire                       rq_1_out_done_s;

   wire  [2:0]                out_jobs_afull_s;
   wire                       out_jobs_empty_s;
   wire                       out_jobs_read_en_s;
   wire  [63:0]               out_jobs_dim_value_s;
   wire  [63:0]               out_jobs_ptr_s;
   wire  [63:0]               out_jobs_fact_value_s;

//   reg   [63:0]               ll_reg_id_s;
//   reg   [63:0]               ll_reg_val_s;
//   reg   [63:0]               ll_reg_ptr_s;
//
   wire                       decide_match_s;
   wire                       decide_last_element_s;

   wire  [1:0]                rec_jobs_afull_s;
   wire                       rec_jobs_write_en_s;
   wire                       rec_jobs_empty_s;
   wire  [63:0]               rec_jobs_value_s;
   wire  [63:0]               rec_jobs_ptr_s;
   wire                       rec_jobs_read_en_s;

   wire  [1:0]                match_jobs_afull_s;
   wire                       match_jobs_write_en_s;
   wire                       match_jobs_empty_s;

   wire                       done_s;
   reg   [3:0]                done_hold_s;

   assign new_job_valid_s     = (new_job_pointer_in != 64'hFFFF_FFFF_FFFF_FFFF);
   assign new_job_ready_s     = !new_job_empty_in && new_job_valid_s;
   assign new_job_read_en_out = (!new_job_empty_in && !new_job_valid_s) || (ll_rq_next_state == LL_READ_NEW);

   // Here is the multithreadded portion. Jobs are sent out to search though
   // the linked list. The only question is if the job is new, or is recycled
   // from a job that did not find a match.
   always @(posedge clk)
   begin
      if (rst == 1'd1)  ll_rq_curr_state <= LL_IDLE;
      else              ll_rq_curr_state <= ll_rq_next_state;
   end

   always @*
   begin
      if (ll_rq_0_afull_in || ll_rq_1_afull_in || out_jobs_afull_s[2])
         ll_rq_next_state <= LL_IDLE;
      else if  (!rec_jobs_empty_s)
         ll_rq_next_state <= LL_READ_OLD;
      else if  (new_job_ready_s)
         ll_rq_next_state <= LL_READ_NEW;
      else
         ll_rq_next_state <= LL_IDLE;
   end

   assign ll_rq_read_en_s  = (ll_rq_next_state != LL_IDLE);
   assign ll_rq_address_s  = (ll_rq_next_state == LL_READ_OLD)? rec_jobs_ptr_s[47:0] : new_job_pointer_in[47:0];
   assign ll_rq_value_s    = (ll_rq_next_state == LL_READ_OLD)? rec_jobs_value_s     : new_job_value_in;

   assign ll_rq_0_vld_out     = ll_rq_read_en_s;
   assign ll_rq_0_address_out = ll_rq_address_s * 'd2;
   outstanding_requests RQ_0_OUT (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (rq_0_out_done_s),
      .rq_vld_in              (ll_rq_read_en_s),
      .rs_vld_in              (ll_rs_0_write_en_in)
   );

   assign ll_rq_1_vld_out     = ll_rq_read_en_s;
   assign ll_rq_1_address_out = (ll_rq_address_s * 'd2) + 48'd1;
   outstanding_requests RQ_1_OUT (
      .clk                    (clk),
      .rst                    (rst),
      .done                   (rq_1_out_done_s),
      .rq_vld_in              (ll_rq_read_en_s),
      .rs_vld_in              (ll_rs_1_write_en_in)
   );


   // A data request will keep the fact table tuple, and make 2 requests
   // to the linked list. One for the dim tuple, and another for the next 
   // pointer. All this data has to be synchronized, then we can decide what
   // to do.
   sync_3_fifo OUT_JOBS (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (out_jobs_afull_s),
      .write_en_in            ({ll_rq_read_en_s, ll_rs_1_write_en_in, ll_rs_0_write_en_in}),
      .data_2_in              (ll_rq_value_s),
      .data_1_in              (ll_rs_1_data_in),
      .data_0_in              (ll_rs_0_data_in),
      .empty_out              (out_jobs_empty_s),
      .read_en_in             (out_jobs_read_en_s),
      .data_2_out             (out_jobs_fact_value_s),
      .data_1_out             (out_jobs_ptr_s),
      .data_0_out             (out_jobs_dim_value_s)
   );
   assign ll_rs_0_afull_out      = out_jobs_afull_s[0];
   assign ll_rs_1_afull_out      = out_jobs_afull_s[1];

   assign decide_match_s         = (out_jobs_dim_value_s[63:32] == out_jobs_fact_value_s[63:32]);
   assign decide_last_element_s  = (out_jobs_ptr_s == 64'hffff_ffff_ffff_ffff);


   // If jobs do not match then we need to recycle them back, and search the
   // next node in the linked list. If they do not match, and they are the
   // last element then we can drop them.
   assign out_jobs_read_en_s  = !out_jobs_empty_s;
   assign rec_jobs_write_en_s = out_jobs_read_en_s && // !decide_match_s && 
                                !decide_last_element_s && (rec_jobs_afull_s == 2'd0);
   assign rec_jobs_read_en_s  = (ll_rq_next_state == LL_READ_OLD);
   sync_2_fifo REC_JOBS (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (rec_jobs_afull_s),
      .write_en_in            ({rec_jobs_write_en_s, rec_jobs_write_en_s}),
      .data_1_in              (out_jobs_fact_value_s),
      .data_0_in              (out_jobs_ptr_s),
      .empty_out              (rec_jobs_empty_s),
      .read_en_in             (rec_jobs_read_en_s),
      .data_1_out             (rec_jobs_value_s),
      .data_0_out             (rec_jobs_ptr_s)
   );

   // If jobs do match then we output them to the next stage of the pipeline.
   assign match_jobs_write_en_s = out_jobs_read_en_s && decide_match_s && (match_jobs_afull_s == 2'd0);
   sync_2_fifo MATCH_JOBS (
      .clk                    (clk),
      .rst                    (rst),
      .afull_out              (match_jobs_afull_s),
      .write_en_in            ({match_jobs_write_en_s, match_jobs_write_en_s}),
      .data_1_in              (out_jobs_dim_value_s),
      .data_0_in              (out_jobs_fact_value_s),
      .empty_out              (match_jobs_empty_s),
      .read_en_in             (output_read_en_in),
      .data_1_out             (output_dim_table_out),
      .data_0_out             (output_fact_table_out)
   );
   assign output_empty_out = match_jobs_empty_s;

   assign done_s = new_job_empty_in && rq_0_out_done_s      && rq_1_out_done_s &&
                   out_jobs_empty_s && match_jobs_empty_s;

   always @(posedge clk)
   begin
      done_hold_s <= {done_hold_s[2:0], done_s};
   end

   assign done = (done_hold_s == 4'hF);

//
//
//   always @*
//   begin
//      case (ll_rq_curr_state)
//         LL_IDLE:
//            if (out_jobs_afull_s != 2'd0  || ll_rq_afull_in)
//               ll_rq_next_state <= LL_IDLE;
//            else if (!rec_jobs_empty_s)
//               ll_rq_next_state <= LL_READ_OLD;
//            else if (new_job_curr_state == NEW_JOB_VLD)
//               ll_rq_next_state <= LL_READ_NEW;
//            else
//               ll_rq_next_state <= LL_IDLE;
//
//         LL_READ_OLD:
//            ll_rq_next_state <= LL_READ_ID;
//
//         LL_READ_NEW:
//            ll_rq_next_state <= LL_READ_ID;
//
//         LL_READ_ID:
//            ll_rq_next_state <= LL_READ_VAL;
//
//         LL_READ_VAL:
//            ll_rq_next_state <= LL_READ_PTR;
//
//         LL_READ_PTR:
//            ll_rq_next_state <= LL_IDLE;
//
//         default:
//            ll_rq_next_state <= LL_IDLE;
//
//      endcase
//   end
//
//   always @*
//   begin
//      if (ll_rq_curr_state == LL_READ_OLD) begin
//         curr_job_rq_id_s      <= rec_jobs_id_s;
//         curr_job_rq_value_s   <= rec_jobs_val_s;
//      end
//      else begin // ll_rq_curr_state == LL_READ_NEW
//         curr_job_rq_id_s      <= new_job_id_in;
//         curr_job_rq_value_s   <= new_job_value_in;
//      end
//
//   end
//
//   assign curr_job_rq_valid_s = (ll_rq_curr_state == LL_READ_OLD) || (ll_rq_curr_state == LL_READ_NEW);
//   assign ll_read_en_s = (ll_rq_curr_state == LL_READ_ID)   || (ll_rq_curr_state == LL_READ_VAL) || 
//                         (ll_rq_curr_state == LL_READ_PTR);
//
//
//   // Get the base address based on if we read a new job, or an old (recycled)
//   // job
//   wire  [47:0]               old_base_ptr_s;
//   wire  [47:0]               new_base_ptr_s;
//   mul_48 OLD_BASE (
//      .clk                    (clk),
//      .a                      (rec_jobs_ptr_s[47:0]),
//      .b                      (48'd3),
//      .p                      (old_base_ptr_s)
//   );
//
//   mul_48 NEW_BASE (
//      .clk                    (clk),
//      .a                      (new_job_pointer_in[47:0]),
//      .b                      (48'd3),
//      .p                      (new_base_ptr_s)
//   );
//
//   //assign ll_addr_base_s = (ll_rq_curr_state == LL_READ_OLD)? old_base_ptr_s : new_base_ptr_s;
////   always @*
////   begin
////      ll_addr_base_s <= ll_addr_base_s;
////      case (ll_rq_curr_state)
////         LL_READ_OLD:   ll_addr_base_s <= old_base_ptr_s;
////         LL_READ_NEW:   ll_addr_base_s <= new_base_ptr_s;
////      endcase
////   end
//
//   always @(posedge clk)
//   begin
//      if (ll_rq_curr_state == LL_READ_OLD)
//         ll_addr_base_s <= old_base_ptr_s;
//      else if (ll_rq_curr_state == LL_READ_NEW)
//         ll_addr_base_s <= new_base_ptr_s;
//   end
//
//   reg   [47:0]      delete_me_0;
//   always @(posedge clk)
//   begin
//      if (ll_rq_curr_state == LL_READ_OLD)
//         delete_me_0 <= old_base_ptr_s;
//      else if (ll_rq_curr_state == LL_READ_NEW)
//         delete_me_0 <= new_base_ptr_s;
//   end
//
////   always @(clk)
////   begin
////      if (ll_rq_curr_state == LL_READ_OLD) begin
////         ll_addr_base_s <= 48'd3 * rec_jobs_ptr_s;
////      end
////      else if (ll_rq_curr_state == LL_READ_NEW) begin
////         ll_addr_base_s <= 48'd3 * new_job_pointer_in;
////      end
////   end
//
//   // offset is based on the state
//   always @*
//      case (ll_rq_curr_state)
//         LL_READ_ID:    ll_addr_offset_s <= 48'd0;
//         LL_READ_VAL:   ll_addr_offset_s <= 48'd1;
//         LL_READ_PTR:   ll_addr_offset_s <= 48'd2;
//         default:       ll_addr_offset_s <= 48'd0;
//      endcase
//
//
//   assign ll_rq_vld_out       = ll_read_en_s;
//   assign ll_rq_address_out   = ll_addr_base_s + ll_addr_offset_s;
//   assign ll_rs_afull_out     = 1'd0;
//
//
//   // There is too much information that needs to be kept for each job to send
//   // it out with the request. We need to keep track of the Value, and the Row
//   // ID. These are temporarillay stored in this FIFO until the job requests
//   // are returned.
//   sync_2_fifo OUT_JOBS (
//      .clk                    (clk),
//      .rst                    (rst),
//      .afull_out              (out_jobs_afull_s),
//      .write_en_in            ({curr_job_rq_valid_s, curr_job_rq_valid_s}),
//      .data_1_in              (curr_job_rq_id_s),
//      .data_0_in              (curr_job_rq_value_s),
//      .empty_out              (out_jobs_empty_s),
//      .read_en_in             (out_jobs_read_en_s),
//      .data_1_out             (out_jobs_id_s),
//      .data_0_out             (out_jobs_val_s)
//   );
//
//   outstanding_requests RQ_OUT (
//      .clk                    (clk),
//      .rst                    (rst),
//      .done                   (rq_out_done_s),
//      .rq_vld_in              (ll_read_en_s),
//      .rs_vld_in              (ll_rs_write_en_in)
//   );
//
//   always @(posedge clk)
//   begin
//      if (rst == 1)  ll_rs_curr_state <= LL_READ_ID;
//      else           ll_rs_curr_state <= ll_rs_next_state;
//   end
//  
//
//   always @*
//   begin
//      case (ll_rs_curr_state)
//         LL_READ_ID:    if (ll_rs_write_en_in)  ll_rs_next_state <= LL_READ_VAL;
//                        else                    ll_rs_next_state <= LL_READ_ID;
//
//         LL_READ_VAL:   if (ll_rs_write_en_in)  ll_rs_next_state <= LL_READ_PTR;
//                        else                    ll_rs_next_state <= LL_READ_VAL;
//
//         LL_READ_PTR:   if (ll_rs_write_en_in)  ll_rs_next_state <= LL_READ_ID;
//                        else                    ll_rs_next_state <= LL_READ_PTR;
//
//         default:       ll_rs_next_state <= LL_READ_ID;
//      endcase
//   end
//
//   // Hash results are read from memory, and registered until all 3 data
//   // points are returned.
//   always @(posedge clk)
//   begin
//      if       (ll_rs_write_en_in && ll_rs_curr_state == LL_READ_ID)    ll_reg_id_s    <= ll_rs_data_in;
//      else if  (ll_rs_write_en_in && ll_rs_curr_state == LL_READ_VAL)   ll_reg_val_s   <= ll_rs_data_in;
//      else if  (ll_rs_write_en_in && ll_rs_curr_state == LL_READ_PTR)   ll_reg_ptr_s   <= ll_rs_data_in;
//   end
//
//   always @(posedge clk)
//   begin
//      decide_valid_s = (ll_rs_curr_state == LL_READ_PTR) && (ll_rs_next_state == LL_READ_ID);
//   end
//
//   assign out_jobs_read_en_s     = decide_valid_s;
//   assign decide_match_s         = out_jobs_val_s == ll_reg_val_s;
//   assign decide_last_element_s  = ll_reg_ptr_s == 64'hffff_ffff_ffff_ffff;
//
//   reg                        didnt_write_row_s;
//   always @(posedge clk)
//   begin
//      if (rst == 1'd1)  
//         didnt_write_row_s <= 1'd0;
//      else if (decide_valid_s && !decide_match_s && !decide_last_element_s && rec_jobs_afull_s != 3'd0)
//         didnt_write_row_s <= 1'd1;
//      else if (decide_valid_s && decide_match_s && match_jobs_afull_s == 2'd0)
//         didnt_write_row_s <= 1'd1;
//   end
//   assign error_dropped_row_out = didnt_write_row_s;
//
//   // After the decision is made we will store the fifo in
//   assign rec_jobs_write_en_s = decide_valid_s && !decide_match_s && !decide_last_element_s && (rec_jobs_afull_s == 3'd0);
//   assign rec_jobs_read_en_s  = (ll_rq_curr_state == LL_READ_OLD);
//   sync_3_fifo REC_JOBS (
//      .clk                    (clk),
//      .rst                    (rst),
//      .afull_out              (rec_jobs_afull_s),
//      .write_en_in            ({rec_jobs_write_en_s, rec_jobs_write_en_s, rec_jobs_write_en_s}),
//      .data_2_in              (out_jobs_id_s),
//      .data_1_in              (out_jobs_val_s),
//      .data_0_in              (ll_reg_ptr_s),
//      .empty_out              (rec_jobs_empty_s),
//      .read_en_in             (rec_jobs_read_en_s),
//      .data_2_out             (rec_jobs_id_s),
//      .data_1_out             (rec_jobs_val_s),
//      .data_0_out             (rec_jobs_ptr_s)
//   );
//
//   assign match_jobs_write_en_s = decide_valid_s && decide_match_s && (match_jobs_afull_s == 2'd0);
//   sync_2_fifo MATCH_JOBS (
//      .clk                    (clk),
//      .rst                    (rst),
//      .afull_out              (match_jobs_afull_s),
//      .write_en_in            ({match_jobs_write_en_s, match_jobs_write_en_s}),
//      .data_1_in              (out_jobs_id_s),
//      .data_0_in              (ll_reg_id_s),
//      .empty_out              (match_jobs_empty_s),
//      .read_en_in             (output_read_en_in),
//      .data_1_out             (output_dim_table_out),
//      .data_0_out             (output_fact_table_out)
//   );
//   assign output_empty_out = match_jobs_empty_s;
//
//
//   wire                       done_s;
//   assign done_s = out_jobs_empty_s && rq_out_done_s && rec_jobs_empty_s && match_jobs_empty_s;
//
//   reg   [7:0]                done_count_s;
//   always @(posedge clk)
//   begin
//      done_count_s <= {done_count_s[6:0], done_s};
//   end
//
//   assign done = (done_count_s == 8'hFF);

endmodule

