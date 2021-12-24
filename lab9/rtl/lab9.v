`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab9(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish_clock, v_fish_clock, fish_clock2, god_fish_clock, v_god_fish_clock;
wire [9:0]  pos, pos2, pos_god, vpos, vpos_god;
wire        fish_region, fish2_region, god_fish_region, god_fish2_region;
wire overlap;
assign overlap = fish2_region && god_fish2_region;
// declare SRAM control signals
wire [16:0] sram_addr,sram_addr2, sram_addr3;
wire [11:0] data_in;
wire [11:0] data_out_bg, data_out_fish2, data_out_fish;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
reg  [11:0] rgb_next_temp;
  
// Application-specific VGA signals
reg  [16:0] pixel_addr_fish, pixel_addr_bg, pixel_addr_fish2;
// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH_VPOS   = 64; // Vertical location of the fish in the sea image.
reg up_down, up_down_god;
reg [27:0] up_down_counter;
localparam FISH2_VPOS  = 128;
localparam GOD_FISH_VPOS = 175;
localparam GOD_FISH2_VPOS = 110;
localparam FISH_W      = 64; // Width of the fish.
localparam FISH_H      = 32; // Height of the fish.
localparam GOD_FISH_W  = 64;
localparam GOD_FISH_H  = 44;
reg [16:0] fish_addr [0:7];   // Address array for up to 8 fish images.
reg [16:0] god_fish_addr [0:7];
//reg [16:0] fish2_addr [0:2];
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish_addr[0] = 76800+18'd0;         /* Addr for fish image #1 */
  fish_addr[1] = 76800+FISH_W*FISH_H; /* Addr for fish image #2 */
  fish_addr[2] = 76800+FISH_W*FISH_H*2;
  fish_addr[3] = 76800+FISH_W*FISH_H*3;
  fish_addr[4] = 76800+FISH_W*FISH_H*4;
  fish_addr[5] = 76800+FISH_W*FISH_H*5;
  fish_addr[6] = 76800+FISH_W*FISH_H*6;
  fish_addr[7] = 76800+FISH_W*FISH_H*7;
  god_fish_addr[0] = 0;
  god_fish_addr[1] = GOD_FISH_W*GOD_FISH_H;
  god_fish_addr[2] = GOD_FISH_W*GOD_FISH_H*2;
  god_fish_addr[3] = GOD_FISH_W*GOD_FISH_H*3;
  god_fish_addr[4] = GOD_FISH_W*GOD_FISH_H*4;
  god_fish_addr[5] = GOD_FISH_W*GOD_FISH_H*5;
  god_fish_addr[6] = GOD_FISH_W*GOD_FISH_H*6;
  god_fish_addr[7] = GOD_FISH_W*GOD_FISH_H*7;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);
// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(22528))
  fish2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr3), .data_i(data_in), .data_o(data_out_fish2));
sram1 #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(93184))
            seabed_fish (.clk(clk), .we(sram_we), .en(sram_en),
                    .addr(sram_addr), .addr2(sram_addr2), .data_i(data_in), .data_o(data_out_bg), .data_o_2(data_out_fish));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr_bg;
assign sram_addr2 = pixel_addr_fish;
assign sram_addr3 = pixel_addr_fish2;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = fish_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign vpos = v_fish_clock[29:23]+32;
assign pos2 = fish_clock2[31:20];

assign pos_god = (VBUF_W + FISH_W)*2 - god_fish_clock[31:20];
assign vpos_god = v_god_fish_clock[29:23];

always @(posedge clk) begin
  if (~reset_n || fish_clock[31:21] > VBUF_W + FISH_W)
  begin
    fish_clock <= 0;
  end
  else
  begin
    fish_clock <= fish_clock + 1;
  end
end

always @(posedge clk) begin
  if (~reset_n)
  begin
    v_god_fish_clock <= 32'b00000000_01111111_11111111_11111111;
  end
  else
  begin
    if(~up_down)
        v_god_fish_clock <= v_fish_clock + 1;
    else
        v_god_fish_clock <= v_fish_clock - 1;
  end
end

always @(posedge clk)begin
    if(~reset_n)
        up_down <= 0;
    else if(v_fish_clock[29:23] >= 20)
        up_down <= 1;
    else if(v_fish_clock[29:23] <= 0)
        up_down <= 0;
end

always @(posedge clk) begin
  if (~reset_n)
  begin
    v_fish_clock <= 32'b00000000_01111111_11111111_11111111;
  end
  else
  begin
    if(~up_down)
        v_fish_clock <= v_fish_clock + 1;
    else
        v_fish_clock <= v_fish_clock - 1;
  end
end

always @(posedge clk)begin
    if(~reset_n)
        up_down_god <= 0;
    else if(v_fish_clock[29:23] >= 32)
        up_down_god <= 1;
    else if(v_fish_clock[29:23] <= 0)
        up_down_god <= 0;
end

always @(posedge clk) begin
    if(~reset_n || fish_clock2[31:21] > VBUF_W + FISH_W)
        fish_clock2 <= 0;
    else
        fish_clock2 <= fish_clock2 + 3;
end

always @(posedge clk) begin
    if(~reset_n || god_fish_clock[31:21] > VBUF_W + FISH_W)
        god_fish_clock <= 0;
    else
        god_fish_clock <= god_fish_clock + 2;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish_region = (pixel_y >= (vpos<<1) && pixel_y < (vpos+FISH_H)<<1 &&
                     (pixel_x + 127) >= pos && pixel_x < pos + 1);
          
assign fish2_region = (pixel_y >= ((FISH2_VPOS)<<1) && pixel_y < ((FISH2_VPOS)+FISH_H)<<1 &&
                      (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1);
assign god_fish_region = (pixel_y >= ((vpos_god+GOD_FISH_VPOS)<<1) && pixel_y < ((vpos_god+GOD_FISH_VPOS)+GOD_FISH_H)<<1 &&
                         (pixel_x + 127) >= pos_god && pixel_x < pos_god + 1);
assign god_fish2_region = (pixel_y >= ((GOD_FISH2_VPOS)<<1) && pixel_y < ((GOD_FISH2_VPOS)+GOD_FISH_H)<<1 &&
                         (pixel_x + 127) >= pos && pixel_x < pos + 1);

always @ (posedge clk) begin
  if (~reset_n)
  begin
    pixel_addr_fish <= 0;
    pixel_addr_bg <= 0;
    pixel_addr_fish2 <= 0;
  end
  else
  begin
  if (fish_region)
  begin
    pixel_addr_fish <= fish_addr[fish_clock[25:23]] +
                  ((pixel_y>>1)-vpos)*FISH_W +
                  ((pixel_x +(FISH_W*2-1)-pos)>>1);
    pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    pixel_addr_fish2 <= 0;
   end
   else if(god_fish_region)
   begin
     pixel_addr_fish <= 0;
     pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
     pixel_addr_fish2 <= god_fish_addr[fish_clock[25:23]] +
                 ((pixel_y>>1)-(GOD_FISH_VPOS+vpos_god))*GOD_FISH_W +
                 (FISH_W*2-1-(pixel_x +(GOD_FISH_W*2-1)-pos_god)>>1);
   end
   else if(~god_fish2_region && fish2_region)
   begin
     pixel_addr_fish <= fish_addr[fish_clock[25:23]] +
                   ((pixel_y>>1)-FISH2_VPOS)*FISH_W +
                   ((pixel_x +(FISH_W*2-1)-pos2)>>1);
     pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
     pixel_addr_fish2 <= 0;
   end
   else if(god_fish2_region && ~fish2_region)
   begin
     pixel_addr_fish <= 0;
     pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
     pixel_addr_fish2 <= god_fish_addr[fish_clock[25:23]] +
                        ((pixel_y>>1)-GOD_FISH2_VPOS)*FISH_W +
                        ((pixel_x +(FISH_W*2-1)-pos)>>1);
   end
   else if(god_fish2_region && fish2_region)
   begin
    pixel_addr_fish <= fish_addr[fish_clock[25:23]] +
                           ((pixel_y>>1)-FISH2_VPOS)*FISH_W +
                           ((pixel_x +(FISH_W*2-1)-pos2)>>1);
    pixel_addr_fish2 <= god_fish_addr[fish_clock[25:23]] +
                             ((pixel_y>>1)-GOD_FISH2_VPOS)*FISH_W +
                             ((pixel_x +(FISH_W*2-1)-pos)>>1);
    pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
   end
   else
   begin
     pixel_addr_fish <= 0;
     pixel_addr_fish2 <=0;
     pixel_addr_bg <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
   end
   end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else
      if(fish_region && data_out_fish != 12'h0f0)
           rgb_next = data_out_fish;
      else if(god_fish_region && data_out_fish2 != 12'h0f0)
           rgb_next = data_out_fish2;
      else if(fish2_region & ~god_fish2_region && data_out_fish != 12'h0f0)
           rgb_next = data_out_fish;
      else if(~fish2_region & god_fish2_region && data_out_fish2 != 12'h0f0)
           rgb_next = data_out_fish2;
      else if(fish2_region & god_fish2_region)
            if(data_out_fish != 12'h0f0)
                rgb_next = data_out_fish;
            else
                if(data_out_fish2 != 12'h0f0)
                    rgb_next = data_out_fish2;
                else
                    rgb_next = data_out_bg;
      else
         rgb_next = data_out_bg;
  end
endmodule
