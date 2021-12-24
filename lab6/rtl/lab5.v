`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/10/10 16:10:38
// Design Name: UART I/O example for Arty
// Module Name: lab5
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab5(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_COMPUTE = 1,
                 S_MAIN_WAIT = 2, S_MAIN_REPLY = 3,
                 S_MAIN_READ_MAT = 4;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN = 0; // length of the prompt message
localparam REPLY_STR  = 0; // starting index of the hello message
localparam REPLY_LEN  = 167; // length of the hello message
localparam MEM_SIZE   = PROMPT_LEN+REPLY_LEN;

// declare system variables
wire enter_pressed;
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg  [0:REPLY_LEN*8-1]  msg = { "\015\012The matrix multiplication result is:",
                                 "\015\012[ 00000, 00000, 00000, 00000 ]",
                                 "\015\012[ 00000, 00000, 00000, 00000 ]",
                                 "\015\012[ 00000, 00000, 00000, 00000 ]",
                                 "\015\012[ 00000, 00000, 00000, 00000 ]", 8'h00 };
reg  [15:0] num_reg;  // The key-in number register
reg  [2:0]  key_cnt;  // The key strokes counter
wire compute_done, read_done;
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [11:0] user_addr;
reg  [7:0]  user_data;
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;
reg [7:0] mat [31:0]; 
reg [19:0] mat_out [16:0];
// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal

wire is_receiving;
wire is_transmitting;
wire recv_error;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2001 :(
//
integer idx;

always @(posedge clk) begin
  if (~reset_n) begin

    for (idx = 0; idx < REPLY_LEN; idx = idx + 1) data[idx+PROMPT_LEN] = msg[idx*8 +: 8];
  end
  else if (P == S_MAIN_REPLY) begin
    data[REPLY_STR+42] <= ((mat_out[1][19:16] > 9)? "7" : "0") + mat_out[1][19:16];
    data[REPLY_STR+43] <= ((mat_out[1][15:12] > 9)? "7" : "0") + mat_out[1][15:12];
    data[REPLY_STR+44] <= ((mat_out[1][11:8] > 9)? "7" : "0") + mat_out[1][11:8];
    data[REPLY_STR+45] <= ((mat_out[1][7:4] > 9)? "7" : "0") + mat_out[1][7:4];
    data[REPLY_STR+46] <= ((mat_out[1][3:0] > 9)? "7" : "0") + mat_out[1][3:0];
    data[REPLY_STR+49] <= ((mat_out[2][19:16] > 9)? "7" : "0") + mat_out[2][19:16];
    data[REPLY_STR+50] <= ((mat_out[2][15:12] > 9)? "7" : "0") + mat_out[2][15:12];
    data[REPLY_STR+51] <= ((mat_out[2][11:8] > 9)? "7" : "0") + mat_out[2][11:8];
    data[REPLY_STR+52] <= ((mat_out[2][7:4] > 9)? "7" : "0") + mat_out[2][7:4];
    data[REPLY_STR+53] <= ((mat_out[2][3:0] > 9)? "7" : "0") + mat_out[2][3:0];
    data[REPLY_STR+56] <= ((mat_out[3][19:16] > 9)? "7" : "0") + mat_out[3][19:16];
    data[REPLY_STR+57] <= ((mat_out[3][15:12] > 9)? "7" : "0") + mat_out[3][15:12];
    data[REPLY_STR+58] <= ((mat_out[3][11:8] > 9)? "7" : "0") + mat_out[3][11:8];
    data[REPLY_STR+59] <= ((mat_out[3][7:4] > 9)? "7" : "0") + mat_out[3][7:4];
    data[REPLY_STR+60] <= ((mat_out[3][3:0] > 9)? "7" : "0") + mat_out[3][3:0];
    data[REPLY_STR+63] <= ((mat_out[4][19:16] > 9)? "7" : "0") + mat_out[4][19:16];
    data[REPLY_STR+64] <= ((mat_out[4][15:12] > 9)? "7" : "0") + mat_out[4][15:12];
    data[REPLY_STR+65] <= ((mat_out[4][11:8] > 9)? "7" : "0") + mat_out[4][11:8];
    data[REPLY_STR+66] <= ((mat_out[4][7:4] > 9)? "7" : "0") + mat_out[4][7:4];
    data[REPLY_STR+67] <= ((mat_out[4][3:0] > 9)? "7" : "0") + mat_out[4][3:0];
    data[REPLY_STR+74] <= ((mat_out[5][19:16] > 9)? "7" : "0") + mat_out[5][19:16];
    data[REPLY_STR+75] <= ((mat_out[5][15:12] > 9)? "7" : "0") + mat_out[5][15:12];
    data[REPLY_STR+76] <= ((mat_out[5][11:8] > 9)? "7" : "0") + mat_out[5][11:8];
    data[REPLY_STR+77] <= ((mat_out[5][7:4] > 9)? "7" : "0") + mat_out[5][7:4];
    data[REPLY_STR+78] <= ((mat_out[5][3:0] > 9)? "7" : "0") + mat_out[5][3:0];
    data[REPLY_STR+81] <= ((mat_out[6][19:16] > 9)? "7" : "0") + mat_out[6][19:16];
    data[REPLY_STR+82] <= ((mat_out[6][15:12] > 9)? "7" : "0") + mat_out[6][15:12];
    data[REPLY_STR+83] <= ((mat_out[6][11:8] > 9)? "7" : "0") + mat_out[6][11:8];
    data[REPLY_STR+84] <= ((mat_out[6][7:4] > 9)? "7" : "0") + mat_out[6][7:4];
    data[REPLY_STR+85] <= ((mat_out[6][3:0] > 9)? "7" : "0") + mat_out[6][3:0];
    data[REPLY_STR+88] <= ((mat_out[7][19:16] > 9)? "7" : "0") + mat_out[7][19:16];
    data[REPLY_STR+89] <= ((mat_out[7][15:12] > 9)? "7" : "0") + mat_out[7][15:12];
    data[REPLY_STR+90] <= ((mat_out[7][11:8] > 9)? "7" : "0") + mat_out[7][11:8];
    data[REPLY_STR+91] <= ((mat_out[7][7:4] > 9)? "7" : "0") + mat_out[7][7:4];
    data[REPLY_STR+92] <= ((mat_out[7][3:0] > 9)? "7" : "0") + mat_out[7][3:0];
    data[REPLY_STR+95] <= ((mat_out[8][19:16] > 9)? "7" : "0") + mat_out[8][19:16];
    data[REPLY_STR+96] <= ((mat_out[8][15:12] > 9)? "7" : "0") + mat_out[8][15:12];
    data[REPLY_STR+97] <= ((mat_out[8][11:8] > 9)? "7" : "0") + mat_out[8][11:8];
    data[REPLY_STR+98] <= ((mat_out[8][7:4] > 9)? "7" : "0") + mat_out[8][7:4];
    data[REPLY_STR+99] <= ((mat_out[8][3:0] > 9)? "7" : "0") + mat_out[8][3:0];
    data[REPLY_STR+106] <= ((mat_out[9][19:16] > 9)? "7" : "0") + mat_out[9][19:16];
    data[REPLY_STR+107] <= ((mat_out[9][15:12] > 9)? "7" : "0") + mat_out[9][15:12];
    data[REPLY_STR+108] <= ((mat_out[9][11:8] > 9)? "7" : "0") + mat_out[9][11:8];
    data[REPLY_STR+109] <= ((mat_out[9][7:4] > 9)? "7" : "0") + mat_out[9][7:4];
    data[REPLY_STR+110] <= ((mat_out[9][3:0] > 9)? "7" : "0") + mat_out[9][3:0];
    data[REPLY_STR+113] <= ((mat_out[10][19:16] > 9)? "7" : "0") + mat_out[10][19:16];
    data[REPLY_STR+114] <= ((mat_out[10][15:12] > 9)? "7" : "0") + mat_out[10][15:12];
    data[REPLY_STR+115] <= ((mat_out[10][11:8] > 9)? "7" : "0") + mat_out[10][11:8];
    data[REPLY_STR+116] <= ((mat_out[10][7:4] > 9)? "7" : "0") + mat_out[10][7:4];
    data[REPLY_STR+117] <= ((mat_out[10][3:0] > 9)? "7" : "0") + mat_out[10][3:0];
    data[REPLY_STR+120] <= ((mat_out[11][19:16] > 9)? "7" : "0") + mat_out[11][19:16];
    data[REPLY_STR+121] <= ((mat_out[11][15:12] > 9)? "7" : "0") + mat_out[11][15:12];
    data[REPLY_STR+122] <= ((mat_out[11][11:8] > 9)? "7" : "0") + mat_out[11][11:8];
    data[REPLY_STR+123] <= ((mat_out[11][7:4] > 9)? "7" : "0") + mat_out[11][7:4];
    data[REPLY_STR+124] <= ((mat_out[11][3:0] > 9)? "7" : "0") + mat_out[11][3:0];
    data[REPLY_STR+127] <= ((mat_out[12][19:16] > 9)? "7" : "0") + mat_out[12][19:16];
    data[REPLY_STR+128] <= ((mat_out[12][15:12] > 9)? "7" : "0") + mat_out[12][15:12];
    data[REPLY_STR+129] <= ((mat_out[12][11:8] > 9)? "7" : "0") + mat_out[12][11:8];
    data[REPLY_STR+130] <= ((mat_out[12][7:4] > 9)? "7" : "0") + mat_out[12][7:4];
    data[REPLY_STR+131] <= ((mat_out[12][3:0] > 9)? "7" : "0") + mat_out[12][3:0];
    data[REPLY_STR+138] <= ((mat_out[13][19:16] > 9)? "7" : "0") + mat_out[13][19:16];
    data[REPLY_STR+139] <= ((mat_out[13][15:12] > 9)? "7" : "0") + mat_out[13][15:12];
    data[REPLY_STR+140] <= ((mat_out[13][11:8] > 9)? "7" : "0") + mat_out[13][11:8];
    data[REPLY_STR+141] <= ((mat_out[13][7:4] > 9)? "7" : "0") + mat_out[13][7:4];
    data[REPLY_STR+142] <= ((mat_out[13][3:0] > 9)? "7" : "0") + mat_out[13][3:0];
    data[REPLY_STR+145] <= ((mat_out[14][19:16] > 9)? "7" : "0") + mat_out[14][19:16];
    data[REPLY_STR+146] <= ((mat_out[14][15:12] > 9)? "7" : "0") + mat_out[14][15:12];
    data[REPLY_STR+147] <= ((mat_out[14][11:8] > 9)? "7" : "0") + mat_out[14][11:8];
    data[REPLY_STR+148] <= ((mat_out[14][7:4] > 9)? "7" : "0") + mat_out[14][7:4];
    data[REPLY_STR+149] <= ((mat_out[14][3:0] > 9)? "7" : "0") + mat_out[14][3:0];
    data[REPLY_STR+152] <= ((mat_out[15][19:16] > 9)? "7" : "0") + mat_out[15][19:16];
    data[REPLY_STR+153] <= ((mat_out[15][15:12] > 9)? "7" : "0") + mat_out[15][15:12];
    data[REPLY_STR+154] <= ((mat_out[15][11:8] > 9)? "7" : "0") + mat_out[15][11:8];
    data[REPLY_STR+155] <= ((mat_out[15][7:4] > 9)? "7" : "0") + mat_out[15][7:4];
    data[REPLY_STR+156] <= ((mat_out[15][3:0] > 9)? "7" : "0") + mat_out[15][3:0];
    data[REPLY_STR+159] <= ((mat_out[16][19:16] > 9)? "7" : "0") + mat_out[16][19:16];
    data[REPLY_STR+160] <= ((mat_out[16][15:12] > 9)? "7" : "0") + mat_out[16][15:12];
    data[REPLY_STR+161] <= ((mat_out[16][11:8] > 9)? "7" : "0") + mat_out[16][11:8];
    data[REPLY_STR+162] <= ((mat_out[16][7:4] > 9)? "7" : "0") + mat_out[16][7:4];
    data[REPLY_STR+163] <= ((mat_out[16][3:0] > 9)? "7" : "0") + mat_out[16][3:0];
  end
end

// Combinational I/O logics of the top-level system
assign usr_led = 4'h00;
//assign enter_pressed = (rx_temp == 8'h0D); // don't use rx_byte here!

// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Wait for initial delay of the circuit.
	   if (init_counter < INIT_DELAY) P_next = S_MAIN_INIT;
		else P_next = S_MAIN_WAIT;
    S_MAIN_WAIT: // wait for <Enter> key.
      if (btn_pressed[1]) P_next = S_MAIN_READ_MAT;
      else P_next = S_MAIN_WAIT;
    S_MAIN_READ_MAT:
      if(read_done) P_next = S_MAIN_COMPUTE;
      else P_next = S_MAIN_READ_MAT;
    S_MAIN_COMPUTE:
      if(compute_done) P_next = S_MAIN_REPLY;
      else P_next = S_MAIN_COMPUTE;
    S_MAIN_REPLY: // Print the hello message.
      if (print_done) P_next = S_MAIN_INIT;
      else P_next = S_MAIN_REPLY;
  endcase
end

// FSM output logics: print string control signals.
assign print_enable =(P == S_MAIN_COMPUTE && P_next == S_MAIN_REPLY);
assign print_done = (tx_byte == 8'h0);

// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller that sends a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics: UART transmission control signals
assign transmit = (Q_next == S_UART_WAIT ||
                  (P == S_MAIN_WAIT && received) ||
                   print_enable);

assign tx_byte  = ((P == S_MAIN_WAIT) && received)? echo_key : data[send_counter];

// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= PROMPT_STR;
    S_MAIN_WAIT: send_counter <= REPLY_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end
// End of the UART input logic
// ------------------------------------------------------------------------
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                                       // if you set 'we' to 0, Vivado fails to synthesize
                                       // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_READ_MAT); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0;

always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we ) user_data <= data_out;
end
integer i;
always @(posedge clk) begin
  if(P == S_MAIN_INIT || ~reset_n)
  begin
    user_addr <= 12'h000;
    i<=-1;
  end
  else if(P == S_MAIN_READ_MAT)
  begin
    mat[i] <= data_out;
    if(i<32)
    begin
      i <= i + 1;
      user_addr <= user_addr + 1;
    end
  end
end
assign read_done = (i>=32);

reg [19:0] temp [3:0];
integer j, k;
always@(posedge clk) begin
  if(P == S_MAIN_INIT)
  begin
    j <= 0;
    k <= 0;
    temp[0] <= mat[0]*mat[16];
    temp[1] <= mat[4]*mat[17];
    temp[2] <= mat[8]*mat[18];
    temp[3] <= mat[12]*mat[19];
  end
  else if(P == S_MAIN_COMPUTE)
  begin
    if(j<4)
    begin
      if(k<3)
        k<=k+1;
      else
      begin
        j<=j+1;
        k<=0;
      end
      temp[0] <= mat[j]*mat[16+k*4];
      temp[1] <= mat[j+4]*mat[17+k*4];
      temp[2] <= mat[j+8]*mat[18+k*4];
      temp[3] <= mat[j+12]*mat[19+k*4];
    end
  end
end
assign compute_done = (j>=4);
integer l;
always @(posedge clk) begin
  if(P == S_MAIN_INIT)
    l <= 0;
  if(P == S_MAIN_COMPUTE)
  begin
    mat_out[l] <= temp[0] + temp[1] + temp[2] + temp[3];
    l <= l + 1;
  end
end
debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);
endmodule
