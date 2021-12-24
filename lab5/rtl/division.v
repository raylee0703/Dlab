`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/10/24 21:34:34
// Design Name: 
// Module Name: division
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


module division(
    input [15:0] A,
    input [15:0] B,
    input clk,
    input reset_n,
    input [2:0] P,
    output reg compute_done,
    output reg [15:0] Q
    );
    reg [15:0] R;
    integer i;
    always @(posedge clk) begin
      if(~reset_n)
        compute_done = 0;
      else if(P == 0)
        compute_done = 0;
      else if(P == 5)
      begin
        R = 0;
        Q = 0;
        for(i=15;i>=0;i=i-1)
        begin
          R = R << 1;
          R[0] = A[i];
          if(R >= B)
          begin
            R = R - B;
            Q[i] = 1;
          end 
        end
        if(i<0)
          compute_done = 1;
      end
    end
endmodule
