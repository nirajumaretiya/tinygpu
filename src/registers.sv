`default_nettype none
`timescale 1ns/1ns

// Register file
// > Each thread within each core has it's own register file with 13 free registers and 3 read-only registers
// > Read-only registers are %blockIdx, %blockDim, %threadIdx which are important to SIMD

module registers #(
    parameter THREADS_PER_BLOCK = 4,
    parameter THREAD_ID = 0,
    parameter DATA_BITS = 8
) (
    input wire clk,
    input wire reset,
    input wire enable, // If current block has less threads then block size, some registers will be inactive

    // kernel execution
    input reg [7:0] block_id,

    // core state
    input reg [2:0] core_state,

    // instruction singals
    input reg [3:0] decoded_rd_address,
    input reg [3:0] decoded_rs_address,
    input reg [3:0] decoded_rt_address,

    // control signals
    input reg decoded_reg_write_enable,
    input reg [1:0] decoded_reg_input_mux,
    input reg [DATA_BITS-1:0] decoded_immediate,

    // thread unit outputs
    input reg [DATA_BITS-1:0] alu_out,
    input reg [DATA_BITS-1:0] lsu_out,

    // registers
    output reg [7:0] rs,
    output reg [7:0] rt
);
    localparam ARITHMETIC = 2'b00,
        MEMORY = 2'b01,
        CONSTANT = 2'b10;

    // total 16 registers(13 free, 3 read-only)
    reg [7:0] registers[15:0];

    always @(posedge clk) begin
        if (reset) begin
            // empty rs, rt
            rs <= 0;
            rt <= 0;
    
            registers[0] <= 8'b0;
            registers[1] <= 8'b0;
            registers[2] <= 8'b0;
            registers[3] <= 8'b0;
            registers[4] <= 8'b0;
            registers[5] <= 8'b0;
            registers[6] <= 8'b0;
            registers[7] <= 8'b0;
            registers[8] <= 8'b0;
            registers[9] <= 8'b0;
            registers[10] <= 8'b0;
            registers[11] <= 8'b0;
            registers[12] <= 8'b0;

            // initialize read-only registers
            registers[13] <= 8'b0;              // %blockIdx
            registers[14] <= THREADS_PER_BLOCK; // %blockDim
            registers[15] <= THREAD_ID;         // %threadIdx

        end else if (enable) begin 

            registers[13] <= block_id; // Update the block_id when a new block is issued from dispatcher
            
            // fill rs/rt when core_state=REQUEST
            if (core_state == 3'b011) begin 
                rs <= registers[decoded_rs_address];
                rt <= registers[decoded_rt_address];
            end

            // store rd when core_state = UPDATE
            if (core_state == 3'b110) begin 
                // mask all other than R0-R12
                if (decoded_reg_write_enable && decoded_rd_address < 13) begin
                    case (decoded_reg_input_mux)
                        ARITHMETIC: begin 
                            registers[decoded_rd_address] <= alu_out;
                        end
                        MEMORY: begin 
                            registers[decoded_rd_address] <= lsu_out;
                        end
                        CONSTANT: begin 
                            registers[decoded_rd_address] <= decoded_immediate;
                        end
                    endcase
                end
            end
        end
    end
endmodule