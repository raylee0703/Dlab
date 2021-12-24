`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/12/04 21:31:52
// Design Name: 
// Module Name: md5
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


module md5(
  input enable,
  input reset_n,
  input clk,
  input [63:0] initial_msg,
  input [0:127] passwd_hash,
  output test_done,
  output reg cracked
);

reg [3:0] state, nextstate;
parameter [0 : 64*32-1] r = {32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22, 32'd7, 32'd12, 32'd17, 32'd22,
                             32'd5, 32'd9, 32'd14, 32'd20, 32'd5,  32'd9, 32'd14, 32'd20, 32'd5,  32'd9, 32'd14, 32'd20, 32'd5,  32'd9, 32'd14, 32'd20,
                             32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23, 32'd4, 32'd11, 32'd16, 32'd23,
                             32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21, 32'd6, 32'd10, 32'd15, 32'd21};
parameter [0 : 64*32-1] k = {32'hd76aa478, 32'he8c7b756, 32'h242070db, 32'hc1bdceee,
                             32'hf57c0faf, 32'h4787c62a, 32'ha8304613, 32'hfd469501,
                             32'h698098d8, 32'h8b44f7af, 32'hffff5bb1, 32'h895cd7be,
                             32'h6b901122, 32'hfd987193, 32'ha679438e, 32'h49b40821,
                             32'hf61e2562, 32'hc040b340, 32'h265e5a51, 32'he9b6c7aa,
                             32'hd62f105d, 32'h02441453, 32'hd8a1e681, 32'he7d3fbc8,
                             32'h21e1cde6, 32'hc33707d6, 32'hf4d50d87, 32'h455a14ed,
                             32'ha9e3e905, 32'hfcefa3f8, 32'h676f02d9, 32'h8d2a4c8a,
                             32'hfffa3942, 32'h8771f681, 32'h6d9d6122, 32'hfde5380c,
                             32'ha4beea44, 32'h4bdecfa9, 32'hf6bb4b60, 32'hbebfbc70,
                             32'h289b7ec6, 32'heaa127fa, 32'hd4ef3085, 32'h04881d05,
                             32'hd9d4d039, 32'he6db99e5, 32'h1fa27cf8, 32'hc4ac5665,
                             32'hf4292244, 32'h432aff97, 32'hab9423a7, 32'hfc93a039,
                             32'h655b59c3, 32'h8f0ccc92, 32'hffeff47d, 32'h85845dd1,
                             32'h6fa87e4f, 32'hfe2ce6e0, 32'ha3014314, 32'h4e0811a1,
                             32'hf7537e82, 32'hbd3af235, 32'h2ad7d2bb, 32'heb86d391};
parameter [0 : 64*32-1] c_32 = {32'd25, 32'd20, 32'd15, 32'd10, 32'd25, 32'd20, 32'd15, 32'd10, 32'd25, 32'd20, 32'd15, 32'd10, 32'd25, 32'd20, 32'd15, 32'd10,
                                32'd27, 32'd23, 32'd18, 32'd12, 32'd27, 32'd23, 32'd18, 32'd12, 32'd27, 32'd23, 32'd18, 32'd12, 32'd27, 32'd23, 32'd18, 32'd12,
                                32'd28, 32'd21, 32'd16, 32'd9, 32'd28, 32'd21, 32'd16, 32'd9, 32'd28, 32'd21, 32'd16, 32'd9, 32'd28, 32'd21, 32'd16, 32'd9,
                                32'd26, 32'd22, 32'd17, 32'd11, 32'd26, 32'd22, 32'd17, 32'd11, 32'd26, 32'd22, 32'd17, 32'd11, 32'd26, 32'd22, 32'd17, 32'd11};

reg [31:0] h0;
reg [31:0] h1;
reg [31:0] h2;
reg [31:0] h3;
reg [31:0] a;
reg [31:0] b;
reg [31:0] c;
reg [31:0] d;
reg [5:0] offset;
reg [31:0] i;
reg [31:0] temp;
integer j;
reg [31:0] f,g;
reg [31:0] w [15:0];
reg [127:0] hash;
reg [127:0] passwd_hash_r;
always@(*)begin
  case(state)
  0:
    if(enable) nextstate = 1;
    else nextstate = 0;
  1:
    nextstate = 2;
  2:
    nextstate = 8;
  8:
    nextstate = 3;
  3:
    if( i+1 >= 64 ) nextstate = 4;
    else nextstate = 2;
  4:
    nextstate = 5;
  5:
    nextstate = 6;
  6:
    if(cracked) nextstate = 7;
    else nextstate = 0;
  7:
    nextstate = 7;
  default:
    nextstate = 0;
  endcase
end

always @(posedge clk) begin
  if (~reset_n) state <= 0;
  else state <= nextstate;
end

always@(posedge clk) begin
  if(state == 0)
  begin
    cracked <= 0;
  end
  else if(state == 1)
  begin
    i<= 0;
    cracked <= 0;
    w[0] <= { initial_msg[32+:8], initial_msg[40+:8], initial_msg[48+:8], initial_msg[56+:8]};
    w[1] <= { initial_msg[ 0+:8], initial_msg[ 8+:8], initial_msg[16+:8], initial_msg[24+:8]};      
    a <= 32'h67452301;
    b <= 32'hefcdab89;
    c <= 32'h98badcfe;
    d <= 32'h10325476;
    h0 <= 32'h67452301;
    h1 <= 32'hefcdab89;
    h2 <= 32'h98badcfe;
    h3 <= 32'h10325476;
    for ( j = 0; j < 16; j = j+1) begin
      passwd_hash_r[j*8 +: 8] <= passwd_hash[j*8 +: 8];
    end
  end
  else if(state == 2)
  begin
    if(i < 16)
    begin
      f <= (b & c) | ((~b) & d);
      g <= i;
    end
    else if(i<32)
    begin
      f <= (d & b) | ((~d) & c);
      g <= (5*i + 1) % 16;
    end
    else if(i<48)
    begin
      f <= b ^ c ^ d;
      g <= (3*i + 5) % 16; 
    end
    else
    begin
      f <= c ^ (b | (~d));
      g <= (7*i) % 16;
    end
  end
  else if(state == 8)
  begin
    temp <= a + f + k[i*32 +: 32] + w[g];
  end  
  else if(state == 3)
  begin
    i <= i + 1;
    d <= c;
    c <= b;
    a <= d;
    b <= b + ((temp << r[i*32 +: 32])|(temp >> c_32[i*32 +: 32]));
  end
  else if(state == 4)
  begin
    hash[127:96] <= h3 + d;
    hash[95:64] <= h2 + c;
    hash[63:32] <= h1 + b;
    hash[31:0] <= h0 + a;
  end
  else if(state == 5)
  begin
    if(hash == passwd_hash_r) cracked <= 1;
    else cracked <= 0;
  end
 
end

assign test_done = (state == 6 || state == 7);


always@(posedge clk) begin
  w[ 2] <= 32'h00000080;
  w[ 3] <= 32'h00000000;
  w[ 4] <= 32'h00000000;
  w[ 5] <= 32'h00000000;
  w[ 6] <= 32'h00000000;
  w[ 7] <= 32'h00000000;
  w[ 8] <= 32'h00000000;
  w[ 9] <= 32'h00000000;
  w[10] <= 32'h00000000;
  w[11] <= 32'h00000000;
  w[12] <= 32'h00000000;
  w[13] <= 32'h00000000;
  w[14] <= 32'h00000040;
  w[15] <= 32'h00000000;
end

endmodule
