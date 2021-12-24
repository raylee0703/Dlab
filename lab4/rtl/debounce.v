`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/09 19:47:56
// Design Name: 
// Module Name: debounce
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    reg state;
    reg sync_0, sync_1;
    reg [18:0] counter;
    wire idle = (state == sync_1);
    wire max = &counter;
   
    always @(posedge clk) sync_0 <= btn_input;
    always @(posedge clk) sync_1 <= sync_0;
    
    
    always @(posedge clk)
    begin
        if (idle)
            counter <= 0;
        else
        begin
            counter <= counter + 1;
                if (max)
                state <= ~state;
        end
    end
    
    assign btn_output = ~idle & max & ~state;
endmodule
