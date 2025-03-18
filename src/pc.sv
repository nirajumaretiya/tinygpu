`default_nettype none
`timescale 1ns/1ns

module pc #(
    parameter DATA_MEM_DATA_BITS=8,
    parameter PROGRAM_MEM_ADDR_BITS=8
)(
    input wire clk,
    input wire reset,
    input wire enable, // If current block has less threads then block size, some PC's will inactive

    // core state
    input reg [2:0] core_state,

    //  control singals
    input reg [2:0] decoded_nzp,
    input reg [DATA_MEM_DATA_BITS-1:0] decoded_immediate,
    input reg decoded_nzp_write_enable,
    input reg decoded_pc_mux,

    // ALU output used for compare with nzp register
    input reg [DATA_MEM_DATA_BITS-1:0] alu_out,

    // current and next PC
    input reg [PROGRAM_MEM_ADDR_BITS-1:0] current_pc,
    output reg [PROGRAM_MEM_ADDR_BITS-1:0] next_pc
);
    reg [2:0] nzp;

    always@(posedge clk) begin
        if(reset) begin
            nzp<=3'b000;
            next_pc<=0;
        end
        else if(enable) begin
            // update pc when core state=EXECUTE
            if(core_state==3'b101) begin
                if(decoded_pc_mux==1) begin
                    if((nzp & decoded_nzp) != 3'b000) begin
                        // on BRnzp instruction,branch to immediate if NZP case matches previous CMP
                        next_pc<=decoded_immediate;
                    end
                    else begin
                        // otherwise PC+1
                        next_pc<=current_pc+1;
                    end
                end
                else begin
                    // by default PC+1
                    next_pc<=current_pc+1;
                end
            end

            // store NZP when core_state=UPDATE
            if(core_state==3'b110) begin  
                // write to NZP register on CMP intruction 
                if(decoded_nzp_write_enable) begin
                    nzp[2]<=alu_out[2];
                    nzp[1]<=alu_out[1];
                    nzp[0]<=alu_out[0];
                end
            end  
        end
    end
endmodule