module RX_MODULE (
    input wire clk,
    input wire rst,
    input wire serial_in,
    input wire tick,
    output reg [7:0] sipo_reg,
    output reg err_flag,
    output reg done
);

//UART reciever states in accordance with 8N1 schema (no parity bit)
localparam [1:0] IDLE = 2'b00;
localparam [1:0] START = 2'b01;
localparam [1:0] DATA = 2'b10;
localparam [1:0] STOP = 2'b11;

//centralized UART state
reg [1:0] rx_state = IDLE;

//tick counter (16x oversampling)
reg [3:0] tick_cnt;

//bit counter for DATA state
reg [2:0] bit_cnt;

//serial read-in
reg serial_bit;

//prevents metastability
always @(posedge clk) begin
    reg first_pass <= serial_in;
    reg second_pass <= first_pass; 
    serial_bit <= second_pass;

    if (rst) begin
        first_pass <= 1'b0;
        second_pass <= 1'b0;
    end    
end     

//shift register
always @(posedge clk) begin
        if (rst) begin
            sipo_reg <= 7'b00000001;
        end else begin
            if (tick) begin
                //LSB added to front, after 8 serial ins, LSB will be at back
                sipo_reg <= {serial_bit, sipo_reg[6:0]}
            end    
        end        
end  

//moore finite state machine
always @(posedge clk) begin
    case (rx_state)
        /*fill in later*/
        IDLE begin
            if ((tick) && (!serial_bit)) begin
                rx_state <= START;
            end    
        end    
        START begin
            if ((tick) && (!serial_bit) && (tick_cnt == ))
        end else begin
        end    
        default begin
            rx_state = IDLE;
        end    
    endcase     
end    

//RX four bit counter 
//-- **IMPORTANT** DO NOT CHANGE STATES IN FOUR BIT COUNTER LOGIC --
always @(posedge clk) begin
    /*
    repackage for FSM use
    if ((tick) && (rx_state == IDLE) && (serial_in == 1'b0)) begin

    end    
    */

    //four bit counter logic
    if ((tick) && (rx_state == START) && (serial_bit == 1'b0)) begin
        tick_cnt <= tick_cnt + 4'b0001;

        if (tick_cnt == 4'b0111) begin
            tick_cnt <= 4'b0000;
        end    
    end
    if ((tick) && ((rx_state == DATA) || (rx_state == STOP))) begin
        tick_cnt <= tick_cnt + 4'b0001;

        if (tick_cnt == 4'b1111) begin
            tick_cnt <= 4'b0000;
        end    
    end   


    //three bit counter logic
    if ((tick) && ((rx_state == DATA))) begin
        if (tick_cnt == 4'b1111) begin
            bit_cnt <= bit_cnt + 3'b001;
        end    
        if (bit_cnt == 3'b111) begin
            bit_cnt <= 3'b000;
            rx_state = STOP;
        end    
    end 
    if (rst) begin
        tick_cnt <= 4'b0000;
        bit_cnt <= 3'b000;
    end    
end    


endmodule