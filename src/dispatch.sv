`default_nettype none
`timescale 1ns/1ns


module dispatch#(
    parameter NUM_CORES=2,
    parameter THREADS_PER_BLOCK=4
)(
    input wire clk,
    input wire reset,
    input wire start,

    // kernel metadata
    input wire [7:0] thread_count,

    // core state
    input reg [NUM_CORES-1:0] core_done,
    output reg [NUM_CORES-1:0] core_start,
    output reg [NUM_CORES-1:0] core_reset,
    output reg [7:0] core_block_id [NUM_CORES-1:0],
    output reg [$clog2(THREADS_PER_BLOCK):0] core_thread_count[NUM_CORES-1:0],

    // kernel execution
    output reg done
);
    // total no. of blocks based on total threads and threads per block
    wire [7:0] total_blocks;
    assign total_blocks=(thread_count+THREADS_PER_BLOCK-1)/THREADS_PER_BLOCK;

    // tracking on how many blocks have been processed
    reg [7:0] blocks_dispatched;
    reg [7:0] blocks_done;
    reg start_execution;

    always @(posedge clk) begin
        if(reset) begin
            done<=0;
            blocks_dispatched<=0;
            blocks_done<=0;
            start_execution<=0;
        end


    end
endmodule


