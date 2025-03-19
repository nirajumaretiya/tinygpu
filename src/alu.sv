`default_nettype none
`timescale 1ns/1ns

// Arithmetic Logic Unit
// Perform operations on load-store registers
// ALU supports ADD, SUB, MUL, DIV
// Each thread in each core has it's own ALU

module alu(
    input wire clk,
    input wire reset,
    input wire enable, // If current block has less threads then block size then enable=0
    input reg [2:0] core_state, // operate when core_state=3'b101(Execute) only
    input reg [1:0] decoded_alu_arithmetic_mux, 
    input reg decoded_alu_output_mux, 
    input reg [7:0] rs,
    input reg [7:0] rt,
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
            if(decoded_alu_output_mux==1)begin
             alu_out_reg<={5'b0,(rs-rt>0),(rs-rt==0),(rs-rt<0)}; // set values for comparison
            end
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
