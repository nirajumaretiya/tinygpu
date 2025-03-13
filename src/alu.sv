`default_nettype none
`timescale 1ns/1ns

module alu(
    input wire clk,
    input wire reset,
    input wire enable,
    input wire [2:0] core_state,
    input wire [1:0] decoded_alu_arithmetic_mux,
    input wire decoded_alu_output_mux,
    input wire [7:0] rs,
    input wire [7:0] rt,
    output wire [7:0] alu_out
);

localparam ADD=2'b00,
           SUB=2'b01,
           MUL=2'b10,
           DIV=2'b11;

reg [7:0] alu_out_reg;
assign alu_out=alu_out_reg;

always @(posedge clk) begin
    if(reset) alu_out_reg<=0;
    else if(enable) begin
        if(core_state==3'b101) begin
            if(decoded_alu_output_mux==1) alu_out_reg<={5'b0,(rs>rt),(rs==rt),(rs<rt)};
            else begin
                case(decoded_alu_arithmetic_mux)
                    ADD: alu_out_reg<=rs+rt;
                    SUB: alu_out_reg<=rs-rt;
                    MUL: alu_out_reg<=rs*rt;
                    DIV: alu_out_reg<=rs/rt;
                    default: alu_out_reg<=0;
                endcase
            end
        end
    end
end

endmodule
