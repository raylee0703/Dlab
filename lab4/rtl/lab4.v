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


module lab4(
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
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
integer i,j,k;
reg [27:0] count = 0;
integer c = 0;
reg scroll = 0;
reg [31:0] fib2 [24:0];
reg [15:0] number [24:0];

localparam [3:1] IDLE=3'b001, FIBO=3'b010, DISP=3'b100;
reg [3:1] Q, Q_next;
always @(posedge clk)
if (!reset_n) Q <= IDLE;
else Q <= Q_next;
always @* // next-state logic
case (Q)
IDLE: Q_next = FIBO;
FIBO: Q_next = (i < 25)? FIBO : DISP;
DISP: Q_next = DISP;
default: Q_next = Q_next;
endcase

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
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);


reg [15:0] fib [24:0];
initial begin
    fib[0] = 0;
    fib[1] = 1;
end

always @(posedge clk) begin
    case(Q)
    IDLE:
    begin
        for(j=0;j<25;j=j+1)
        begin
            fib2[j] = "";
            number[j] = "";
        end
        c = 0;
        count = 0;
        scroll = 0;
    end
    FIBO:
    begin
            for(i=2;i<25;i=i+1)
            begin
                fib[i] = fib[i-1] + fib[i-2];
            end
            for(j=0;j<25;j=j+1)
                begin
                    for(k=0;k<4;k=k+1)
                    begin
                        case(fib[j][k*4 +: 4])
                            4'b0000: fib2[j][k*8 +: 8 ] = "0";
                            4'b0001: fib2[j][k*8 +: 8 ] = "1";
                            4'b0010: fib2[j][k*8 +: 8 ] = "2";
                            4'b0011: fib2[j][k*8 +: 8 ] = "3";
                            4'b0100: fib2[j][k*8 +: 8 ] = "4";
                            4'b0101: fib2[j][k*8 +: 8 ] = "5";
                            4'b0110: fib2[j][k*8 +: 8 ] = "6";
                            4'b0111: fib2[j][k*8 +: 8 ] = "7";
                            4'b1000: fib2[j][k*8 +: 8 ] = "8";
                            4'b1001: fib2[j][k*8 +: 8 ] = "9";
                            4'b1010: fib2[j][k*8 +: 8 ] = "A";
                            4'b1011: fib2[j][k*8 +: 8 ] = "B";
                            4'b1100: fib2[j][k*8 +: 8 ] = "C";
                            4'b1101: fib2[j][k*8 +: 8 ] = "D";
                            4'b1110: fib2[j][k*8 +: 8 ] = "E";
                            4'b1111: fib2[j][k*8 +: 8 ] = "F";                
                        endcase
                    end
                    case(j)
                        0: number[j] = "01";
                        1: number[j] = "02";
                        2: number[j] = "03";
                        3: number[j] = "04";
                        4: number[j] = "05";
                        5: number[j] = "06";
                        6: number[j] = "07";
                        7: number[j] = "08";
                        8: number[j] = "09";
                        9: number[j] = "10";
                        10: number[j] = "11";
                        11: number[j] = "12";
                        12: number[j] = "13";
                        13: number[j] = "14";
                        14: number[j] = "15";
                        15: number[j] = "16";
                        16: number[j] = "17";
                        17: number[j] = "18";
                        18: number[j] = "19";
                        19: number[j] = "20";
                        20: number[j] = "21";
                        21: number[j] = "22";
                        22: number[j] = "23";
                        23: number[j] = "24";
                        24: number[j] = "25";
                    endcase
                end
    end
    DISP:
    begin
        if(btn_pressed)
        begin
            if(scroll == 0)
                scroll =1;
            else
                scroll = 0;
        end
        if(count<70000000)
        begin
            row_A = {"Fibo #",number[c], " is ",  fib2[c]};
            row_B = {"Fibo #",number[(c+1)%25], " is ", fib2[(c+1)%25]};
            count = count + 1;
        end
        else
            begin
                count = 0;
                if(scroll == 0)
                    if(c == 24)
                        c = 0;
                    else
                        c = c +1;
                else
                    if(c == 0)
                        c = 24;
                    else
                        c = c - 1;
            end
        end
endcase
end



endmodule
