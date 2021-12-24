module binary_bcd(
    input clk,
    input reset_n,
    input enable,
    input [31:0] binary,
    output reg [7*4-1:0] BCD,
    output valid
);
    reg [31:0] binary_loader;
    reg [2:0] state, nextstate;
    
    parameter [2:0] IDLE  = 0;
    parameter [2:0] SHIF  = 1;
    parameter [2:0] LOAD  = 2;
    parameter [2:0] PROC  = 3;
    parameter [2:0] DONE  = 4;
    
    integer shift_counter = 0;
    integer i = 0;
    
    assign valid = (state == DONE);
    
    always @(posedge clk) begin
        if(~reset_n)
            state <= IDLE;
        else
            state <= nextstate;     
    end
    always @(*) begin
        case(state)
            IDLE : begin
                if( enable ) nextstate = LOAD;
                else nextstate = IDLE;
            end
            
            LOAD : begin
                nextstate = PROC;
            end
            
            PROC : begin
                nextstate = SHIF;
            end
            
            SHIF : begin
              if( shift_counter >= 31 ) nextstate = DONE;
              else nextstate = PROC;
            end
            DONE : begin
                nextstate = DONE;
            end
            default: nextstate = IDLE;
        endcase
    end
    always @(posedge clk) begin
        case(state)
            IDLE : begin
                BCD <= 0;
                shift_counter <= 0;
                i <= 0;
            end
            LOAD : begin
                BCD <= 0;
                shift_counter <= 0;
                i <= 0;
                binary_loader <= binary;
            end
            PROC : begin
                for( i=0; i<7; i=i+1) begin
                    if(BCD[i*4+:4] > 4)
                        BCD[i*4+:4] <= BCD[i*4+:4] + 3;
                end
                
            end
            SHIF : begin
                BCD <= { BCD[26:0], binary_loader[31] };
                binary_loader <= binary_loader << 1;
                shift_counter <= shift_counter + 1;
            end
        endcase
    end
endmodule