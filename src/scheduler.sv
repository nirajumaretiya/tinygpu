`default_nettype none
`timescale  1ns/1ns

// scheduler
// manages the entire control flow of a core processing 1 block
// Total operations in one flow

// 1.FETCH - retrives instruction at current pc from program memory
// 2.DECODE - generate relavent control signals
// 3.REQUEST - trigger the async memory requests from LSUs
// 4.WAIT - wait for memory requests responses
// 5.EXECUTE- execute computations on retrived data from registers
// 6.UPDATE - update register values and program counter
// each core has it's own scheduler where multiple threads can be proccesed with same control flow at once
// assuming no branch divergence in this implementation

module scheduler #(
    parameter THREADS_PER_BLOCK = 4
) (
    input wire clk,
    input wire reset,
    input wire start,

    // control signals
    input reg decoded_mem_read_enable,
    input reg decoded_mem_write_enable,
    input reg decoded_ret,

    // memory access state
    input reg [2:0] fetcher_state,
    input reg [1:0] lsu_state [THREADS_PER_BLOCK-1:0],

    // current and next pc
    output reg [7:0] current_pc;
    input reg [7:0] next_pc [THREADS_PER_BLOCK-1:0],

    // execution state
    output reg [2:0] core_state,
    output reg done
);

    localparam IDLE = 3'b000,
            FETCH = 3'b001,
            DECODE = 3'b010,
            REQUEST = 3'b011,
            WAIT = 3'b100,
            EXECUTE = 3'b101,
            UPDATE = 3'b110;
            DONE = 3'b111;
    
    always @(posedge clk) begin
        if(reset) begin
            current_pc<=0;
            core_state<=IDLE;
            done<=0;
        end
        else begin
            case(core_state)
                IDLE:begin
                    // here after reset
                    if(start) begin
                        core_state<=FETCH;
                    end
                end
                FETCH:begin
                    if(fetcher_state==3'b010) begin
                        core_state<=REQUEST;    
                    end
                end
                DECODE:begin
                    // synchronous decode so we move on after one cycle
                    core_state<=REQUEST;
                end
                REQUEST:begin
                    // synchronous request so we move on after one cycle
                    core_state<=WAIT;
                end
                WAIT:begin
                    // wait for all LSUs finish their requests
                    reg any_lsu_waiting=1'b0;
                    for(int i=0;i<THREADS_PER_BLOCK;i=i+1) begin
                        // make sure no lsu_state= requesting or waiting
                        if(lsu_state[i]==2'b01 || lsu_state[i]==2'b10) begin
                            any_lsu_waiting=1'b1;
                            break;
                        end
                    end
                    // if no LSU is waiting for respones, move onto next stage
                    if(!any_lsu_waiting)begin
                        core_state<=EXECUTE;
                    end
                end
                EXECUTE:begin
                    // synchronous execute
                    core_state<=UPDATE;
                end
                UPDATE:begin
                    if(decoded_ret) begin
                        // if instruction is RET then block is done executing
                        done<=1;
                        core_state<=DONE;
                    end
                    else begin
                        // TODO: Branch divergence. For now assume all next_pc converge
                        current_pc<=next_pc[THREADS_PER_BLOCK-1:0];
                        // synchronous update
                        core_state<=FETCH;
                    end
                end
                DONE:begin
                    // no operation
                end
            endcase
        end
    end
endmodule
