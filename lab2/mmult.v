`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/09/22 09:59:32
// Design Name: 
// Module Name: mmult
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


module mmult(
 input clk,
 input reset_n,
 input enable,
 
 input [0:9*8-1] A_mat,
 input [0:9*8-1] B_mat,
 
 output valid,
 output [0:9*17-1] C_mat
);
integer i = 0, j, k;
reg [0:9*17-1] C_mat;
reg valid = 0;
always @ (posedge clk)
begin
    if(enable && i<3)
    begin
        for(j=0;j<3;j=j+1)
        begin
            for(k=0;k<3;k=k+1)
            begin
                C_mat[i*17+j*51 +: 17] =  C_mat[i*17+j*51 +: 17] + A_mat[j*24+k*8 +: 8] * B_mat[i*8+k*24 +: 8];
            end  
        end
        if(i<3)
            i = i+1;
    end
    if(i==3)
        valid = 1;
end

always @ (negedge reset_n)
begin
  C_mat = 0;
end
endmodule