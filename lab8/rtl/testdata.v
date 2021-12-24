`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/06 14:47:52
// Design Name: 
// Module Name: testdata
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


module testdata(
    input clk,
    input reset_n,
    input [63:0] start_data,
    input next,
    output [63:0] value
);

reg [63:0] test_data;
assign value = test_data;

always @(posedge clk) begin
  if(!reset_n) begin
    test_data <= start_data;
  end
  else if(next)
  begin
    test_data[63-:8] <= (test_data[63-:8]=="9"&&test_data[55-:8]=="9"&&test_data[47-:8]=="9"&&test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[63-:8]+((test_data[55-:8]=="9"&&test_data[47-:8]=="9"&&test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[55-:8] <= (test_data[55-:8]=="9"&&test_data[47-:8]=="9"&&test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[55-:8]+((test_data[47-:8]=="9"&&test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[47-:8] <= (test_data[47-:8]=="9"&&test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[47-:8]+((test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[39-:8] <= (test_data[39-:8]=="9"&&test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[39-:8]+((test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[31-:8] <= (test_data[31-:8]=="9"&&test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[31-:8]+((test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[23-:8] <= (test_data[23-:8]=="9"&&test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[23-:8]+((test_data[15-:8]=="9"&&test_data[07-:8]=="9")?1:0);
    test_data[15-:8] <= (test_data[15-:8]=="9"&&test_data[07-:8]=="9")?"0":test_data[15-:8]+((test_data[07-:8]=="9")?1:0);
    test_data[07-:8] <= (test_data[07-:8]=="9")?"0":test_data[07-:8]+1;
  end
end
endmodule
