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
reg first_pass;

always @(posedge clk) begin
    first_pass <= serial_in;
    serial_bit <= first_pass; 

    //reset to 1 since line idles high
    if (rst) begin
        first_pass <= 1'b1;
        serial_bit <= 1'b1;
    end    
end     

//shift register
always @(posedge clk) begin
        if (rst) begin
            sipo_reg <= 8'b00000000;
        end else begin
            if ((tick) && (tick_cnt == 4'b1111) && (rx_state == DATA)) begin
                //LSB added to front, after 8 serial ins, LSB will be at back
                sipo_reg <= {serial_bit, sipo_reg[7:1]};
            end    
        end        
end  

//moore finite state machine
always @(posedge clk) begin
    done <= 1'b0;
    case (rx_state)
        /*fill in later*/
        IDLE: begin
            if ((tick) && (!serial_bit)) begin
                rx_state <= START;
                done <= 1'b0;
                err_flag <= 1'b0;
            end    
        end    
        START: begin
            if ((tick) && (!serial_bit) && (tick_cnt == 4'b0111)) begin
                rx_state <= DATA;
            end else begin
                if ((tick) && (tick_cnt == 4'b0111) && (serial_bit)) begin
                    rx_state <= IDLE;
                end   
            end    
        end
        DATA: begin
            if ((tick) && (bit_cnt == 3'b111) && (tick_cnt == 4'b1111)) begin
                rx_state <= STOP;
            end    
        end
        STOP: begin
            if ((tick) && (tick_cnt == 4'b1111) && (serial_bit)) begin
                done<=1'b1;
                err_flag <= 1'b0;
                rx_state <= IDLE;
            end else begin
                if ((tick) && (tick_cnt == 4'b1111) && (!serial_bit)) begin
                    err_flag <= 1'b1;
                    done <= 1'b1;
                    rx_state <= IDLE;
                end    
            end    
        end            
        default begin
            rx_state <= IDLE;
        end    
    endcase     
    if (rst) begin
        rx_state <= IDLE;
        done <= 1'b0;
        err_flag <= 1'b0;
    end        
end    

//RX four bit counter 
//-- **IMPORTANT** DO NOT CHANGE STATES IN FOUR BIT COUNTER LOGIC --
always @(posedge clk) begin
    /*
    repackage for FSM use
    if ((tick) && (rx_state == IDLE) && (serial_in == 1'b0)) begin

    end    
    */
    if (rx_state == IDLE) begin
        tick_cnt <= 4'b0000;
    end    
    //four bit counter logic
    if ((tick) && (rx_state == START)) begin
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
    end 
    if (rst) begin
        tick_cnt <= 4'b0000;
        bit_cnt <= 3'b000;
    end    
end    


endmodule