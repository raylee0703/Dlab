`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/26 15:03:31
// Design Name: 
// Module Name: lab3
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


module lab3(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output reg [3:0] usr_led   // Four yellow LEDs
);
    reg [3:0] check = 4'b0000;
    reg [19:0] duty_led = 1000000;
    reg [19:0] count0 = 0;
    reg [19:0] count1 = 0;
    reg [19:0] count2 = 0;
    reg [19:0] count3 = 0;
    
    wire btn0_state, btn0_dn;
    debounce btn0 (
        .clk(clk),
        .button_in(usr_btn[0]),
        .state(btn0_state),
        .press(btn0_dn)
    );

    wire btn1_state, btn1_dn;
    debounce btn1 (
        .clk(clk),
        .button_in(usr_btn[1]),
        .state(btn1_state),
        .press(btn1_dn)
    );

    wire btn2_state, btn2_dn;
    debounce btn2 (
        .clk(clk),
        .button_in(usr_btn[2]),
        .state(btn2_state),
        .press(btn2_dn)
    );    
    
    wire btn3_state, btn3_dn;
    debounce btn3 (
        .clk(clk),
        .button_in(usr_btn[3]),
        .state(btn3_state),
        .press(btn3_dn)
        );    
    always @ (posedge clk) 
    begin
        if (btn3_dn)
        begin
            case(duty_led)
                1000000: duty_led <= 1000000;
                750000: duty_led <= 1000000;
                500000: duty_led <= 750000;
                250000: duty_led <= 500000;
                50000: duty_led <= 250000;
            endcase
        end

        if (btn2_dn)
        begin
            case(duty_led)
                1000000: duty_led <= 750000;
                750000: duty_led <= 500000;
                500000: duty_led <= 250000;
                250000: duty_led <= 50000;
                50000: duty_led <= 50000;
            endcase
        end
        if(btn1_dn)
        begin
             if(check == 4'b1111)
                check <= 4'b0000;
             else if(check == 4'b0111)
                check <= check;
             else
                check <= check + 1;
        end
        if(btn0_dn)
        begin
             if(check == 4'b0000)
                 check <= 4'b1111;
             else if(check == 4'b1000)
                 check <= check;
             else
                 check <= check - 1;
        end
    end

    always @(posedge clk) begin
        if(check[0] == 1) begin
            if(count0<1000000) begin
                count0 <= count0 + 1;
                usr_led[0] <= (count0<duty_led);
            end
            else
                count0 <= 0;
        end
        else if(check[0] == 0)
            usr_led[0] <= 0;

    end
    
    always @(posedge clk) begin
            if(check[1] == 1) begin
                if(count1<1000000) begin
                    count1 <= count1 + 1;
                    usr_led[1] <= (count1<duty_led);
                end
                else
                    count1 <= 0; 
            end
            else if(check[1] == 0)
                 usr_led[1] <= 0;
    end
    
    always @(posedge clk) begin
            if(check[2] == 1) begin
                if(count2<1000000) begin
                    count2 <= count2 + 1;
                    usr_led[2] <= (count2<duty_led); 
                end
                else
                    count2 <= 0;
            end
            else if(check[2] == 0)
                usr_led[2] <= 0; 

    end
    
    always @(posedge clk) begin
            if(check[3] == 1) begin
                if(count3<1000000) begin
                    count3 <= count3 + 1;
                    usr_led[3] <= (count3<duty_led); 
                end
                else
                    count3 <= 0;
            end
            else if(check[3] == 0)
                usr_led[3] <= 0;
    end

endmodule

module debounce(
    input clk,
    input button_in,
    output reg state,
    output press
    );
    reg sync_0, sync_1;
    reg [18:0] counter;
    wire idle = (state == sync_1);
    wire max = &counter;
   
    always @(posedge clk) sync_0 <= button_in;
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
    
    assign press = ~idle & max & ~state;
endmodule