`default_nettype none
`timescale 1ns/1ns

// main gpu module
// uses an external async memory with multi-channel read/write
// first assumes the program is loaded into program memory, data is loaded into date memory and threads into device control register before start signal
// has memory controller to interface bw multiple cores
// configurable number of cores and thread capacity per core

module gpu #(
    parameter DATA_MEM_ADDR_BITS=8,
    parameter DATA_MEM_DATA_BITS=8,
    parameter DATA_MEM_NUM_CHANNELS=4,
    parameter PROGRAM_MEM_ADDR_BITS=8,
    parameter PROGRAM_MEM_DATA_BITS=16,
    parameter PROGRAM_MEM_NUM_CHANNELS=1,
    parameter NUM_CORES=2,
    parameter THREADS_PER_BLOCK=4
)(
    input wire clk,
    input wire reset,

    // kernel execution
    input wire start,
    input wire done,

    // device control register
    input wire device_control_write_enable,
    input wire [7:0] device_control_data,

    // program memory 
    output wire [PROGRAM_MEM_NUM_CHANNELS-1:0] program_mem_read_valid,
    output wire [PROGRAM_MEM_ADDR_BITS-1:0] program_mem_read_address [PROGRAM_MEM_NUM_CHANNELS-1:0],
    input wire [PROGRAM_MEM_NUM_CHANNELS-1:0] program_mem_read_ready,
    input wire [PROGRAM_MEM_DATA_BITS-1:0] progsram_mem_read_data [PROGRAM_MEM_NUM_CHANNELS-1:0],

    // data memory
    output wire [DATA_MEM_NUM_CHANNELS-1:0] data_mem_read_valid,
    output wire [DATA_MEM_ADDR_BITS-1:0] data_mem_read_address [DATA_MEM_NUM_CHANNELS-1:0],
    input wire [DATA_MEM_NUM_CHANNELS-1:0] data_mem_read_ready,
    input wire [DATA_MEM_DATA_BITS-1:0] data_mem_read_data [DATA_MEM_NUM_CHANNELS-1:0],
    output wire [DATA_MEM_NUM_CHANNELS-1:0] data_mem_write_valid,
    output wire [DATA_MEM_ADDR_BITS-1:0] data_mem_write_address [DATA_MEM_NUM_CHANNELS-1:0],
    output wire [DATA_MEM_DATA_BITS-1:0] data_mem_write_data [DATA_MEM_NUM_CHANNELS-1:0],
    input wire [DATA_MEM_NUM_CHANNELS-1:0] data_mem_write_ready
);

    // control
    wire [7:0] thread_count;

    // compute core state
    reg [NUM_CORES-1:0] core_start;
    reg [NUM_CORES-1:0] core_reset;
    reg [NUM_CORES-1:0] core_done;
    reg [7:0] core_block_id [NUM_CORES-1:0];
    reg [$clog2(THREADS_PER_BLOCK):0] core_thread_count[NUM_CORES-1:0];

    // LSU > data memory controller channels
    localparam NUM_LSUS = NUM_CORES*THREADS_PER_BLOCK;
    reg [NUM_LSUS-1:0] lsu_read_valid;
    reg [DATA_MEM_ADDR_BITS-1:0] lsu_read_address[NUM_LSUS-1:0];
    reg [NUM_LSUS-1:0] lsu_read_ready;
    reg [DATA_MEM_DATA_BITS-1:0] lsu_read_data [NUM_LSUS-1:0];
    reg [NUM_LSUS-1:0] lsu_write_valid;
    reg [DATA_MEM_ADDR_BITS-1:0] lsu_write_address [NUM_LSUS-1:0];
    reg [DATA_MEM_DATA_BITS-1:0] lsu_write_data [NUM_LSUS-1:0];
    reg [NUM_LSUS-1:0] lsu_write_ready; 

    // fetcher > program memory controller channels
    localparam NUM_FETCHERS = NUM_CORES;
    reg [NUM_FETCHERS-1:0] fetcher_read_valid;
    reg [PROGRAM_MEM_ADDR_BITS-1:0] fetcher_read_address [NUM_FETCHERS-1:0];
    reg [NUM_FETCHERS-1:0] fetcher_read_ready;
    reg [PROGRAM_MEM_DATA_BITS-1:0] fetcher_read_data [NUM_FETCHERS-1:0];

    // DCR
    dcr dcr_ins(
        .clk(clk),
        .reset(reset),
        .device_control_write_enable(device_control_write_enable),
        .device_control_data(device_control_data),
        .thread_count(thread_count)
    )

    // data memory controller
    controller #(
        .ADDR_BITS(DATA_MEM_ADDR_BITS),
        .DATA_BITS(DATA_MEM_DATA_BITS),
        .NUM_CONSUMERS(NUM_LSUS),
        .NUM_CHANNELS(DATA_MEM_NUM_CHANNELS)
    )(
        .clk(clk),
        .reset(reset),
        .consumer_read_valid(lsu_read_valid),
        .consumer_read_address(lsu_read_address),
        .consumer_read_ready(lsu_read_ready),
        .consumer_read_data(lsu_read_data),
        .consumer_write_valid(lsu_write_valid),
        .consumer_write_address(lsu_write_address),
        .consumer_write_data(lsu_write_data),
        .consumer_write_ready(lsu_write_ready),

        .mem_read_valid(data_mem_read_valid),
        .mem_read_address(data_mem_read_address),
        .mem_read_ready(data_mem_read_ready),
        .mem_read_data(data_mem_read_data),
        .mem_write_valid(data_mem_write_valid),
        .mem_write_address(data_mem_write_address),
        .mem_write_data(data_mem_write_data),
        .mem_write_ready(data_mem_write_ready)
    );

    // program memory controller
       controller #(
        .ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
        .DATA_BITS(PROGRAM_MEM_DATA_BITS),
        .NUM_CONSUMERS(NUM_FETCHERS),
        .NUM_CHANNELS(PROGRAM_MEM_NUM_CHANNELS),
        .WRITE_ENABLE(0)
    ) program_memory_controller (
        .clk(clk),
        .reset(reset),

        .consumer_read_valid(fetcher_read_valid),
        .consumer_read_address(fetcher_read_address),
        .consumer_read_ready(fetcher_read_ready),
        .consumer_read_data(fetcher_read_data),

        .mem_read_valid(program_mem_read_valid),
        .mem_read_address(program_mem_read_address),
        .mem_read_ready(program_mem_read_ready),
        .mem_read_data(program_mem_read_data),
    );

    // dispatcher
       dispatch #(
        .NUM_CORES(NUM_CORES),
        .THREADS_PER_BLOCK(THREADS_PER_BLOCK)
    ) dispatch_instance (
        .clk(clk),
        .reset(reset),
        .start(start),
        .thread_count(thread_count),
        .core_done(core_done),
        .core_start(core_start),
        .core_reset(core_reset),
        .core_block_id(core_block_id),
        .core_thread_count(core_thread_count),
        .done(done)
    );

    // cores
    genvar i;
    generate
        for(i=0;i<NUM_CORES;i=i+1) begin: cores
            // creating seperate signals 
            reg [THREADS_PER_BLOCK-1:0] core_lsu_read_valid;
            reg [DATA_MEM_ADDR_BITS-1:0] core_lsu_read_address [THREADS_PER_BLOCK-1:0];
            reg [THREADS_PER_BLOCK-1:0] core_lsu_read_ready;
            reg [DATA_MEM_DATA_BITS-1:0] core_lsu_read_data [THREADS_PER_BLOCK-1:0];
            reg [THREADS_PER_BLOCK-1:0] core_lsu_write_valid;
            reg [DATA_MEM_ADDR_BITS-1:0] core_lsu_write_address [THREADS_PER_BLOCK-1:0];
            reg [DATA_MEM_DATA_BITS-1:0] core_lsu_write_data [THREADS_PER_BLOCK-1:0];
            reg [THREADS_PER_BLOCK-1:0] core_lsu_write_ready;

            // Pass through signals between LSUs and data memory controller
            genvar j;
            for (j = 0; j < THREADS_PER_BLOCK; j = j + 1) begin
                localparam lsu_index = i * THREADS_PER_BLOCK + j;
                always @(posedge clk) begin 
                    lsu_read_valid[lsu_index] <= core_lsu_read_valid[j];
                    lsu_read_address[lsu_index] <= core_lsu_read_address[j];

                    lsu_write_valid[lsu_index] <= core_lsu_write_valid[j];
                    lsu_write_address[lsu_index] <= core_lsu_write_address[j];
                    lsu_write_data[lsu_index] <= core_lsu_write_data[j];
                    
                    core_lsu_read_ready[j] <= lsu_read_ready[lsu_index];
                    core_lsu_read_data[j] <= lsu_read_data[lsu_index];
                    core_lsu_write_ready[j] <= lsu_write_ready[lsu_index];
                end
            end

            // Compute Core
            core #(
                .DATA_MEM_ADDR_BITS(DATA_MEM_ADDR_BITS),
                .DATA_MEM_DATA_BITS(DATA_MEM_DATA_BITS),
                .PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
                .PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS),
                .THREADS_PER_BLOCK(THREADS_PER_BLOCK),
            ) core_instance (
                .clk(clk),
                .reset(core_reset[i]),
                .start(core_start[i]),
                .done(core_done[i]),
                .block_id(core_block_id[i]),
                .thread_count(core_thread_count[i]),
                
                .program_mem_read_valid(fetcher_read_valid[i]),
                .program_mem_read_address(fetcher_read_address[i]),
                .program_mem_read_ready(fetcher_read_ready[i]),
                .program_mem_read_data(fetcher_read_data[i]),

                .data_mem_read_valid(core_lsu_read_valid),
                .data_mem_read_address(core_lsu_read_address),
                .data_mem_read_ready(core_lsu_read_ready),
                .data_mem_read_data(core_lsu_read_data),
                .data_mem_write_valid(core_lsu_write_valid),
                .data_mem_write_address(core_lsu_write_address),
                .data_mem_write_data(core_lsu_write_data),
                .data_mem_write_ready(core_lsu_write_ready)
            );      
        end
    endgenerate
endmodule