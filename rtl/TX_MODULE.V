module TX_MODULE (
    input wire clk,
    input wire rst,
    input wire data,
    input wire tick,
    output wire serial_out,
    output reg busy,
    output reg done
);

//UART transmitter states in accordance with 8N1 schema (no parity bit)
localparam [1:0] IDLE = 2'b00;
localparam [1:0] START = 2'b01;
localparam [1:0] DATA = 2'b10;
localparam [1:0] STOP = 2'b11;



endmodule