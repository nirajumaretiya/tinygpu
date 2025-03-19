`default_nettype none
module alu (
	clk,
	reset,
	enable,
	core_state,
	decoded_alu_arithmetic_mux,
	decoded_alu_output_mux,
	rs,
	rt,
	alu_out
);
	input wire clk;
	input wire reset;
	input wire enable;
	input wire [2:0] core_state;
	input wire [1:0] decoded_alu_arithmetic_mux;
	input wire decoded_alu_output_mux;
	input wire [7:0] rs;
	input wire [7:0] rt;
	output wire [7:0] alu_out;
	localparam ADD = 2'b00;
	localparam SUB = 2'b01;
	localparam MUL = 2'b10;
	localparam DIV = 2'b11;
	reg [7:0] alu_out_reg;
	assign alu_out = alu_out_reg;
	always @(posedge clk)
		if (reset)
			alu_out_reg <= 0;
		else if (enable) begin
			if (core_state == 3'b101) begin
				if (decoded_alu_output_mux == 1)
					alu_out_reg <= {5'b00000, (rs - rt) > 0, (rs - rt) == 0, (rs - rt) < 0};
				else
					case (decoded_alu_arithmetic_mux)
						ADD: alu_out_reg <= rs + rt;
						SUB: alu_out_reg <= rs - rt;
						MUL: alu_out_reg <= rs * rt;
						DIV: alu_out_reg <= rs / rt;
						default: alu_out_reg <= 0;
					endcase
			end
		end
endmodule