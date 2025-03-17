`default_nettype none
`timescale 1ns/1ns

module dcr(
    input wire clk,
    input wire reset,

    input wire device_control_write_enable,
    input wire [7:0] device_control_data,
    output wire [7:0] thread_count
);
    reg [7:0] device_control_register;
    assign thread_count = device_control_register[7:0];

    always @(posedge clk) begin
        if(reset) begin
            device_control_register<=8'b0;
        end
        else begin
            if(device_control_write_enable) begin
                device_control_register<=device_control_data;
            end
        end
    end
endmodule
