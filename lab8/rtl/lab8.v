`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/10/16 14:21:33
// Design Name: 
// Module Name: lab4
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz 
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


module lab8(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "crack           "; // Initialize the text of the second row.

reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;


localparam [2:0] S_MAIN_INIT = 0, S_MAIN_WAIT = 1,
                 S_MAIN_CRACK = 2, S_MAIN_SHOW = 3,
                 S_MAIN_TIME = 4;
           
reg [2:0] P, P_next;
wire [9:0] cracked;
wire valid;
wire [9:0] test_done;
integer d, temp, i;
wire counter_next;
wire enable;
reg [63:0] test_start [9:0];
reg [63:0] test_data [9:0];
wire [63:0] value [9:0];
reg [63:0] passwd;
reg [19:0] time_counter;
reg [31:0] ms_counter;
reg time_trans_en;
wire [27:0] bcd_time;
wire time_valid;
reg [55:0] time_ASCII;
LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);

debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);

assign counter_next = (!valid && test_done);
assign enable = (P == S_MAIN_CRACK && !valid);
assign valid = |(cracked);

always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*)begin
  case(P)
    S_MAIN_INIT:
      P_next = S_MAIN_WAIT;
    S_MAIN_WAIT:
      if(btn_pressed) P_next = S_MAIN_CRACK;
      else P_next = S_MAIN_WAIT;
    S_MAIN_CRACK:
      if(valid) P_next = S_MAIN_TIME;
      else P_next = S_MAIN_CRACK;
    S_MAIN_TIME:
      if(time_valid) P_next = S_MAIN_SHOW;
      else P_next = S_MAIN_TIME;
    S_MAIN_SHOW:
      P_next = S_MAIN_INIT;
  endcase
end

always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always@(posedge clk) begin
  if(!reset_n)
    passwd <= 0;
  else if(valid)
  begin
    case(cracked)
      10'b0000000001: passwd <= value[0];
      10'b0000000010: passwd <= value[1];
      10'b0000000100: passwd <= value[2];
      10'b0000001000: passwd <= value[3];
      10'b0000010000: passwd <= value[4];
      10'b0000100000: passwd <= value[5];
      10'b0001000000: passwd <= value[6];
      10'b0010000000: passwd <= value[7];
      10'b0100000000: passwd <= value[8];
      10'b1000000000: passwd <= value[9];
    endcase
  end
end

always @(posedge clk) begin
  if(~reset_n||P == S_MAIN_INIT)
  begin
    time_counter <= 0;
    ms_counter <= 0;
  end
  else if(P == S_MAIN_CRACK && !valid) begin
    if(time_counter < 99999)
    begin
      time_counter <= time_counter + 1;
      ms_counter <= ms_counter;
    end
    else if(time_counter >= 99999)
    begin
      time_counter <= 0;
      ms_counter <= ms_counter + 1;
    end
  end
end

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "crack           ";
  end 
  else if (P == S_MAIN_CRACK) begin
      row_A <= "cracking        ";
      row_B <= "                ";
    end
  else if (P == S_MAIN_SHOW) begin
    for(i=0;i<7;i=i+1)
    begin
      case(bcd_time[i*4+:4])
        4'b0000: time_ASCII[i*8+:8] = "0";
        4'b0001: time_ASCII[i*8+:8] = "1";
        4'b0010: time_ASCII[i*8+:8] = "2";
        4'b0011: time_ASCII[i*8+:8] = "3";
        4'b0100: time_ASCII[i*8+:8] = "4";
        4'b0101: time_ASCII[i*8+:8] = "5";
        4'b0110: time_ASCII[i*8+:8] = "6";
        4'b0111: time_ASCII[i*8+:8] = "7";
        4'b1000: time_ASCII[i*8+:8] = "8";
        4'b1001: time_ASCII[i*8+:8] = "9";
      endcase
    end
    row_A <= {"Passwd: ",passwd};
    row_B <= {"Time: ",time_ASCII[55:48],time_ASCII[47:40],time_ASCII[39:32],time_ASCII[31:24],
              time_ASCII[23:16], time_ASCII[15:8], time_ASCII[7:0], " ms"};
  end
end

testdata t0 ( .clk(clk), .reset_n(reset_n), .start_data("00000000"), .next(counter_next), .value(value[ 0]) );
testdata t1 ( .clk(clk), .reset_n(reset_n), .start_data("10000000"), .next(counter_next), .value(value[ 1]) );
testdata t2 ( .clk(clk), .reset_n(reset_n), .start_data("20000000"), .next(counter_next), .value(value[ 2]) );
testdata t3 ( .clk(clk), .reset_n(reset_n), .start_data("30000000"), .next(counter_next), .value(value[ 3]) );
testdata t4 ( .clk(clk), .reset_n(reset_n), .start_data("40000000"), .next(counter_next), .value(value[ 4]) );
testdata t5 ( .clk(clk), .reset_n(reset_n), .start_data("50000000"), .next(counter_next), .value(value[ 5]) );
testdata t6 ( .clk(clk), .reset_n(reset_n), .start_data("60000000"), .next(counter_next), .value(value[ 6]) );
testdata t7 ( .clk(clk), .reset_n(reset_n), .start_data("70000000"), .next(counter_next), .value(value[ 7]) );
testdata t8 ( .clk(clk), .reset_n(reset_n), .start_data("80000000"), .next(counter_next), .value(value[ 8]) );
testdata t9 ( .clk(clk), .reset_n(reset_n), .start_data("90000000"), .next(counter_next), .value(value[ 9]) );

md5 crack0(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[0]), .passwd_hash(passwd_hash), .test_done(test_done[0]), .cracked(cracked[0]) );
md5 crack1(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[1]), .passwd_hash(passwd_hash), .test_done(test_done[1]), .cracked(cracked[1]) );
md5 crack2(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[2]), .passwd_hash(passwd_hash), .test_done(test_done[2]), .cracked(cracked[2]) );
md5 crack3(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[3]), .passwd_hash(passwd_hash), .test_done(test_done[3]), .cracked(cracked[3]) );
md5 crack4(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[4]), .passwd_hash(passwd_hash), .test_done(test_done[4]), .cracked(cracked[4]) );
md5 crack5(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[5]), .passwd_hash(passwd_hash), .test_done(test_done[5]), .cracked(cracked[5]) );
md5 crack6(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[6]), .passwd_hash(passwd_hash), .test_done(test_done[6]), .cracked(cracked[6]) );
md5 crack7(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[7]), .passwd_hash(passwd_hash), .test_done(test_done[7]), .cracked(cracked[7]) );
md5 crack8(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[8]), .passwd_hash(passwd_hash), .test_done(test_done[8]), .cracked(cracked[8]) );
md5 crack9(.enable(enable), .reset_n(reset_n), .clk(clk), .initial_msg(value[9]), .passwd_hash(passwd_hash), .test_done(test_done[9]), .cracked(cracked[9]) );

binary_bcd t_trans(.clk(clk), .reset_n(reset_n), .enable(valid), .binary(ms_counter), .BCD(bcd_time), .valid(time_valid));

endmodule
