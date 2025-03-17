`default_nettype none
`timescale 1ns/1ns

// INSTRUCTION FETCHER MODULE
// retrives the instruction at current pc from global data memory
// each core has it's own fetcher

module fetcher #(
    parameter PROGRAM_MEM_ADDR_BITS = 8,
    parameter PROGRAM_MEM_DATA_BITS = 16
    ) (
        input wire clk,
        input wire reset,

        input reg [2:0] core_state,
        input reg [7:0] current_pc,
        
        // program memory
        output reg mem_read_valid,
        output reg [PROGRAM_MEM_ADDR_BITS-1:0] mem_read_address,
        input reg mem_read_ready,
        input reg [PROGRAM_MEM_DATA_BITS-1:0] mem_read_data,

        // output
        output reg [2:0] fetcher_state,
        output reg [PROGRAM_MEM_DATA_BITS-1:0] instruction    

);

localparam IDLE = 3'b000,
        FETCHING = 3'b001,
        FETCHED = 3'b010;

    always @(posedge clk) begin
        if(reset) begin
            fetcher_state<=IDLE;
            mem_read_valid<=0;
            mem_read_address<=0;
            instruction<={PROGRAM_MEM_DATA_BITS{1'b0}};
        end
        else begin
            case(fetcher_state)
            IDLE:begin
                if(core_state==3'b001) begin
                    fetcher_state<=FETCHING;
                    mem_read_valid<=1;
                    mem_read_address<=current_pc;
                end
            end
            FETCHING:begin
                if(mem_read_ready) begin // wait for response from program memory
                    fetcher_state<=FETCHED;
                    instruction<=mem_read_data;
                    mem_read_valid<=0;
                end
            end
            FETCHED:begin
                if(core_state==3'b010) begin // reset when core_state=DECODE
                    fetcher_state<=IDLE
                end 
                end
            endcase
        end
        end
endmodule