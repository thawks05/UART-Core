module TX_MODULE (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire tick,
    input wire start_data,
    output wire serial_out,
    output wire busy,
    output wire done
);

//UART transmitter states in accordance with 8N1 schema (no parity bit)
localparam [1:0] IDLE = 2'b00;
localparam [1:0] START = 2'b01;
localparam [1:0] DATA = 2'b10;
localparam [1:0] STOP = 2'b11;

//centralized UART TX state
reg [1:0] tx_state = IDLE;

//tick counter
reg [3:0] tick_cnt;

//bit counter
reg [2:0] bit_cnt;

//defines 8N1 shape of UART TX
reg [7:0] tx_piso_data_in;
reg tx_line;

//reg's for busy and done
reg busy_reg = 1'b0;
reg done_reg = 1'b0; 

//continuous reg assignment to tx serial output
assign serial_out = tx_line;
assign busy = busy_reg;
assign done = done_reg;

//piso reg set in START
always @(posedge clk) begin
    if ((tx_state == IDLE) && (start_data)) begin
        tx_piso_data_in <= data_in;
    end  
    if ((tick) && (tx_state == DATA) && (tick_cnt == 4'b1111)) begin
        tx_piso_data_in <= {1'b0, tx_piso_data_in[7:1]};
    end    
    if (rst) begin
        tx_piso_data_in <= 8'b00000000;
    end    
end    

always @(posedge clk) begin
    done_reg <= 1'b0;
    case (tx_state)
        IDLE: begin
            tx_line <= 1'b1;
            busy_reg <= 1'b0;
            if (start_data) begin
                tx_state <= START;
            end
        end    
        START: begin
            //conditional, drive line low for 16 ticks
            tx_line <= 1'b0;
            busy_reg <= 1'b1;
            if ((tick) && (tick_cnt == 4'b1111)) begin
                tx_state <= DATA;
                tx_line <= tx_piso_data_in[0];
            end
        end 
        DATA: begin
            tx_line <= tx_piso_data_in[0];
            if ((tick) && (bit_cnt == 3'b111) && (tick_cnt == 4'b1111)) begin
                tx_state <= STOP;   
            end 
        end   
        STOP: begin
            tx_line <= 1'b1;
            if ((tick) && (tick_cnt == 4'b1111)) begin
                tx_state <= IDLE;
                done_reg <= 1'b1;
            end    
        end    
    endcase
    if (rst) begin
         tx_state <= IDLE;
         tx_line <= 1'b1    ;
         busy_reg <= 1'b0;
         done_reg <= 1'b0;
    end     
end    

//tick counter module
always @(posedge clk) begin
    if (rst) begin 
        tick_cnt <= 4'b0000;
    end else begin
        if ((tick) && ((tx_state == START) || (tx_state == DATA) || (tx_state == STOP))) begin
            tick_cnt <= tick_cnt + 4'b0001;
            if (tick_cnt == 4'b1111) begin
                tick_cnt <= 4'b0000;
            end  
        end   
    end        
end    

always @(posedge clk) begin
    if (rst) begin 
        bit_cnt <= 3'b000;
    end else begin
        if ((tick) && (tx_state == DATA) && (tick_cnt == 4'b1111)) begin
            bit_cnt <= bit_cnt + 3'b001;
            if (bit_cnt == 3'b111) begin
                bit_cnt <= 3'b000;    
            end    
        end   
    end        
end    
endmodule