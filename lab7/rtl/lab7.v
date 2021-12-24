`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: arty_sd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: The sample top module of lab 7: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_INIT = 3'b000, S_MAIN_IDLE = 3'b001,
                 S_MAIN_WAIT = 3'b010, S_MAIN_READ = 3'b011,
                 S_MAIN_TAG  = 3'b111, S_MAIN_SHOW = 3'b101,
				 S_MAIN_FIND = 3'b110;

// Declare system variables
wire btn_pressed;
wire btn_level;
reg  prev_btn_level;
reg  [2:0] P;
reg  [2:0] P_next;
reg  [9:0] sd_counter;
reg  [7:0] data_byte;
reg  [31:0] blk_addr;

reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
reg  done_flag; // Signals the completion of reading one SD sector.

// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// Declare the control/data signals of an SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire [8:0] sram_addr;
wire       sram_we, sram_en;


//my singal
reg[63:0]DLAB_TAG = "DLAB_TAG";
reg[63:0]DLAB_END = "DLAB_END";
reg[63:0]buffer;
reg[15:0]cnt_3_letter;
wire txt_begin;
wire txt_end;
wire three_char;
wire pun1,pun2;
reg find_tag;
reg [9:0]cmpr_cnt;
wire ch1_is_letter, ch2_is_letter, ch3_is_letter;
assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller

assign ch1_is_letter = ((buffer[55:48] >= "A" && buffer[55:48]<="Z") || (buffer[55:48] >= "a" && buffer[55:48]<="z"))?1:0;
assign ch2_is_letter = ((buffer[47:40] >= "A" && buffer[47:40]<="Z") || (buffer[47:40] >= "a" && buffer[47:40]<="z"))?1:0;
assign ch3_is_letter = ((buffer[39:32] >= "A" && buffer[39:32]<="Z") || (buffer[39:32] >= "a" && buffer[39:32]<="z"))?1:0;
assign txt_begin = (buffer == DLAB_TAG) ? 1 : 0;
assign txt_end   = (buffer == DLAB_END) ? 1 : 0;
assign three_char   = ((ch1_is_letter & ch2_is_letter & ch3_is_letter) && buffer[55:32] != "TAG" && (pun1 & pun2) && P == S_MAIN_FIND);
always@(posedge clk)begin
	DLAB_TAG <= "DLAB_TAG";
	DLAB_END <= "DLAB_END";
end
always @(posedge clk)begin
	if(~reset_n)
		find_tag <= 0;
	else if(txt_begin == 1)
		find_tag <= 1;
	else if(P == S_MAIN_IDLE)
		find_tag <= 0;
end

always @(posedge clk)begin
	if(~reset_n)
		cmpr_cnt <= 0;
	else if(P == S_MAIN_FIND || P == S_MAIN_TAG)
		cmpr_cnt <=  (cmpr_cnt == 512) ? 512 : cmpr_cnt+1;
	else 
		cmpr_cnt <= 0;
end

always @(posedge clk)begin
	if(~reset_n)
		cnt_3_letter <= 0;
	else if(P == S_MAIN_FIND && three_char)
		cnt_3_letter <= cnt_3_letter + 1;
	else if(P == S_MAIN_IDLE)
		cnt_3_letter <= 0;
end

wire [7:0]in_char;
assign in_char =  data_out;
always @(posedge clk)begin
	if(~reset_n)
		buffer <= 0;
	else if(P == S_MAIN_FIND || P == S_MAIN_TAG)
		buffer <= {buffer[55:0],in_char};
	else if(P == S_MAIN_IDLE)
		buffer <= 0;
end

assign pun1 = !((buffer[63:56] >= 65 && buffer[63:56]<=90) || (buffer[63:56] >= 97 && buffer[63:56]<=122)) && buffer[63:56] != "_" && buffer[63:56] != "'";
assign pun2 = !((buffer[31:24] >= 65 && buffer[31:24]<=90) || (buffer[31:24] >= 97 && buffer[31:24]<=122)) && buffer[31:24] != "'" && buffer[31:24] != "_";

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

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

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(sram_we),
  .en(sram_en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign sram_we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign sram_en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = (P == S_MAIN_FIND || P == S_MAIN_TAG) ? cmpr_cnt[8:0] : sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_INIT;
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished == 1) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_IDLE;
    S_MAIN_WAIT: // issue a rd_req to the SD controller until it's ready
      P_next = S_MAIN_READ;
    S_MAIN_READ: // wait for the input data to enter the SRAM buffer
      if(sd_counter == 512 && find_tag!=1) P_next = S_MAIN_TAG;
	  else if(sd_counter == 512 && find_tag == 1)P_next = S_MAIN_FIND;
      else P_next = S_MAIN_READ;
	S_MAIN_TAG:
	  if(txt_begin)P_next = S_MAIN_FIND;
	  else if(cmpr_cnt == 10)P_next = S_MAIN_WAIT;
	  else P_next = S_MAIN_TAG;
	S_MAIN_FIND:
	  if(txt_end)P_next = S_MAIN_SHOW;
	  else if(cmpr_cnt == 512)P_next = S_MAIN_WAIT;
	  else P_next = S_MAIN_FIND;  	  
    S_MAIN_SHOW:
	  P_next = S_MAIN_SHOW;
    default:
      P_next = S_MAIN_IDLE;
  endcase
end
// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(posedge clk) begin
  rd_req <= (P == S_MAIN_WAIT);
  rd_addr <= blk_addr;
end

always @(posedge clk) begin
  if (~reset_n) blk_addr <= 32'h2000;
  else if((P == S_MAIN_TAG && P_next == S_MAIN_WAIT) || (P == S_MAIN_FIND && P_next == S_MAIN_WAIT))blk_addr <= blk_addr+1;  // In lab 6, change this line to scan all blocks
end


// FSM output logic: controls the 'sd_counter' signal.
// SD card read address incrementer
always @(posedge clk) begin
  if (~reset_n)
    sd_counter <= 0;
  else if (P == S_MAIN_READ && sd_valid)
    sd_counter <= sd_counter + 1;
  else if (P == S_MAIN_TAG || P == S_MAIN_FIND)
    sd_counter <= 0;
end

// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// LCD Display function.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A = "SD card cannot  ";
    row_B = "be initialized! ";
  end
  else if (P == S_MAIN_IDLE) begin
    row_A <= "Hit BTN2 to read";
    row_B <= "the SD card ... ";
  end else if (P == S_MAIN_SHOW) begin
     row_A [127:80] <= "Found ";
     row_A [79:72] <= ((cnt_3_letter[15:12] > 9)? "7" : "0") + cnt_3_letter[15:12];
     row_A [71:64] <= ((cnt_3_letter[11:8] > 9)? "7" : "0") + cnt_3_letter[11:8];
     row_A [63:56] <= ((cnt_3_letter[7:4] > 9)? "7" : "0") + cnt_3_letter[7:4];
     row_A [55:48] <= ((cnt_3_letter[3:0] > 9)? "7" : "0") + cnt_3_letter[3:0];
     row_A [47:0] <= " words";
    row_B <= "in the test file";
  end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule

