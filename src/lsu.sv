`default_nettype none
`timescale 1ns/1ns

// Load Store Unit
// Perform operations on load-store registers
// LSU supports LOAD, STORE
// Each thread in each core has it's own LSU

module lsu(
    input wire clk,
    input wire reset,
    input wire enable,

    input reg [2:0] core_state,

    //decoded signals for memory control
    input reg decoded_mem_read_enalbe,
    input reg decoded_mem_write_enable,

    input reg [7:0] rs,
    input reg [7:0] rt,

    //data memory
    output reg  mem_read_valid,
    output reg [7:0] mem_read_address,
    input reg mem_read_ready,
    input reg [7:0] mem_read_data,
    output reg mem_write_valid,
    output reg [7:0] mem_write_address,
    output reg [7:0] mem_write_data,
    input reg mem_write_ready,

    //LSU output
    output reg [1:0] lsu_state,
    output reg [7:0] lsu_out

);
    // possible states of LSU
    localparam IDLE=2'b00,REQUESTING=2'b01,WAITING=2'b10,DONE=2'b11;
    
    always@(posedge clk) begin
        if(reset) begin
            lsu_state<=IDLE;
            mem_read_valid<=0;
            mem_write_valid<=0;
            mem_read_address<=0;
            mem_write_address<=0;
            mem_write_data<=0;
            lsu_out<=0;
        end
        else if(enable) begin
            // If memory read is enabled(LDR operation)
            if(decoded_mem_read_enalbe) begin
                case(lsu_state)
                IDLE: begin
                    // When core_state=REQUEST  
                    if(core_state==3'b011) begin
                        lsu_state<=REQUESTING;
                    end
                end

                REQUESTING: begin
                    mem_read_valid<=1;
                    mem_read_address<=rs;
                    lsu_state<=WAITING;
                end

                WAITING:begin
                    if(mem_read_ready==1) begin
                        mem_read_valid<=0;
                        lsu_out<=mem_read_data;
                        lsu_state<=DONE;
                    end
                end

                DONE: begin
                    // Reset when core_state=UPDATE
                    if(core_state==3'b110) begin
                        lsu_state<=IDLE;
                    end
                end
                endcase 
            end

            // If memory write is enabled(STR operation)
            if(decoded_mem_write_enable) begin
                case(lsu_state)
                IDLE: begin
                    if(core_state==3'b011) begin
                        lsu_state<=REQUESTING;
                    end
                end

                REQUESTING: begin
                    mem_read_valid<=1;
                    mem_write_address<=rs;
                    mem_write_data<=rt;
                    lsu_state<=WAITING;    
                end

                WAITING: begin
                    if(mem_write_ready==1) begin
                        mem_write_valid<=0;
                        lsu_state<=DONE;
                    end
                end

                DONE: begin
                    // Reset when core_state=UPDATE
                    if(core_state==3'b110) begin
                        lsu_state<=IDLE;
                    end
                end
                endcase
            end
        end
    end
endmodule
