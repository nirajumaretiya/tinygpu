`default_nettype none
`timescale 1ns/1ns

module core #(
    parameter DATA_MEM_ADDR_BITS=8,
    parameter DATA_MEM_DATA_BITS=8,
    parameter PROFRAM_MEM_ADDR_BITS=8,
    parameter PROGRAM_MEM_DATA_BITS=16,
    parameter THREADS_PER_BLOCK=4
)(
    input wire clk,
    input wire reset,

    // kernel execution control signals
    input wire start,
    output wire done,

    // kernel execution metadata
    input wire [7:0] block_id,
    input wire [$clog2(THREADS_PER_BLOCK):0] thread_count, 

    // program memory interface
    output reg program_mem_read_valid,
    output reg [PROFRAM_MEM_ADDR_BITS-1:0] program_mem_read_address,
    input reg program_mem_read_ready,
    input reg [PROGRAM_MEM_DATA_BITS-1:0] program_mem_read_data,

    // data memory interface
    output reg [THREADS_PER_BLOCK-1:0] data_mem_read_valid,
    output reg [DATA_MEM_ADDR_BITS-1:0] data_mem_read_address [THREADS_PER_BLOCK-1:0],
    input reg [THREADS_PER_BLOCK-1:0] data_mem_read_ready,
    input reg [DATA_MEM_DATA_BITS-1:0] data_mem_read_data [THREADS_PER_BLOCK-1:0],
    output reg [THREADS_PER_BLOCK-1:0] data_mem_write_valid,
    output reg [DATA_MEM_ADDR_BITS-1:0] data_mem_write_address [THREADS_PER_BLOCK-1:0],
    output reg [DATA_MEM_DATA_BITS-1:0] data_mem_write_data [THREADS_PER_BLOCK-1:0],
    input reg [THREADS_PER_BLOCK-1:0] data_mem_write_ready,
);
    //core state
    reg [2:0] core_state;
    reg [2:0] fetcher_state;
    reg [15:0] instruction;

    // intermediate signals
    reg [7:0] current_pc;
    wire [7:0] next_pc[THREADS_PER_BLOCK-1:0]; 
    reg [7:0] rs[THREADS_PER_BLOCK-1:0];   
    reg [7:0] rt[THREADS_PER_BLOCK-1:0];
    reg [1:0] lsu_state[THREADS_PER_BLOCK-1:0];
    reg [7:0] lsu_out[THREADS_PER_BLOCK-1:0];
    wire [7:0] alu_out[THREADS_PER_BLOCK-1:0];

    // decoded instruction signals
    reg [3:0] decoded_rd_address;
    reg [3:0] decoded_rs_address;
    reg [3:0] decoded_rt_address;
    reg [2:0] decoded_nzp;
    reg [7:0] decoded_immediate;

    // decoded control signals
    reg decoded_reg_write_enable;
    reg decoded_mem_read_enable;
    reg decoded_mem_write_enable;
    reg decoded_nzp_write_enable;
    reg [1:0] decoded_reg_input_mux;
    reg [1:0] decoded_alu_arithmetic_mux;
    reg decoded_alu_output_mux;
    reg decoded_pc_mux;
    reg decoded_ret;

    //fetcher
    fetcher  #(
        .PROGRAM_MEM_ADDR_BITS(PROFRAM_MEM_ADDR_BITS),
        .PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS)
    ) fetcher_i (
        .clk(clk),
        .reset(reset),
        .core_state(core_state),
        .current_pc(current_pc),
        .mem_read_valid(program_mem_read_valid),
        .mem_read_address(program_mem_read_address),
        .mem_read_ready(program_mem_read_ready),
        .mem_read_data(program_mem_read_data),
        .fetcher_state(fetcher_state),
        .instruction(instruction),
    );

    //decoder
    decoder decoder_inst(
        .clk(clk),
        .reset(reset),
        .core_state(core_state),
        .instruction(instruction),
        .decoded_rd_address(decoded_rd_address),
        .decoded_rs_address(decoded_rs_address),
        .decoded_rt_address(decoded_rt_address),
        .decoded_nzp(decoded_nzp),
        .decoded_immediate(decoded_immediate),
        .decoded_reg_write_enable(decoded_reg_write_enable),
        .decoded_mem_read_enable(decoded_mem_read_enable),
        .decoded_mem_write_enable(decoded_mem_write_enable),
        .decoded_nzp_write_enable(decoded_nzp_write_enable),
        .decoded_reg_input_mux(decoded_reg_input_mux),
        .decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
        .decoded_alu_output_mux(decoded_alu_output_mux),
        .decoded_pc_mux(decoded_pc_mux),
        .decoded_ret(decoded_ret),
    );

    // scheduler
    scheduler #(
        .THREADS_PER_BLOCK(THREADS_PER_BLOCK)
    ) scheduler_inst (
        .clk(clk),
        .reset(reset),
        .start(start),
        .fetcher_state(fetcher_state),
        .core_state(core_state),
        .decoded_mem_read_enable(decoded_mem_read_enable),
        .decoded_mem_write_enable(decoded_mem_write_enable),
        .decoded_ret(decoded_ret),
        .lsu_state(lsu_state),
        .current_pc(current_pc),
        .next_pc(next_pc),
        .done(done) 
    );

    // dedicated alu,lsu,registers and pc for each thread this core has capacity for
    genvar i;
    generate
        for(i=0;i<THREADS_PER_BLOCK;i=i+1) begin: threads
           
           //ALU
           alu alu_inst(
            .clk(clk),
            .reset(reset),
            .enable(i<thread_count),
            .core_state(core_state),
            .decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
            .decoded_alu_output_mux(decoded_alu_output_mux),
            .rs(rs[i]),
            .rt(rt[i]),
            .alu_out(alu_out[i])
           );

           // LSU
           lsu lsu_inst(
            
           );

        end
        end
    endgenerate

endmodule