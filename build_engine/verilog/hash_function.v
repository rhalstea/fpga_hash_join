`timescale 1 ns / 1 ps

module hash_function (
   input                      clk,
   input                      rst,
   input                      valid_in,
   input    [63:0]            data_in,
   output                     valid_out,
   output   [63:0]            data_out
);


   wire  [47:0]               prime_0_s = 48'h00001E698F65;
   wire  [47:0]               prime_1_s = 48'h000024820C8D;

   wire  [47:0]               data_in_0_s;
   wire  [47:0]               data_in_1_s;
   wire  [47:0]               mul_0_s;
   wire  [47:0]               mul_1_s;
   wire  [47:0]               add_s;

   reg                        valid_out_s;

   assign data_in_0_s = {16'd0, data_in[63:32]};
   assign data_in_1_s = {16'd0, data_in[31:0]};

   mul_48 MUL_0 (
      .clk                    (clk),
      .a                      (prime_0_s),
      .b                      (data_in_0_s),
      .p                      (mul_0_s)
   );

   mul_48 MUL_1 (
      .clk                    (clk),
      .a                      (prime_1_s),
      .b                      (data_in_1_s),
      .p                      (mul_1_s)
   );

   assign add_s = mul_0_s + mul_1_s;

   always @(posedge clk)
   begin
      if (rst == 1'd1) begin
         valid_out_s <= 1'd0;
      end else begin
         valid_out_s <= valid_in;
      end

   end

   assign valid_out  = valid_out_s;
   assign data_out   = {33'd0, add_s[30:0]};

endmodule

