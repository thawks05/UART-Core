module UART_CORE (
    input wire clk,
    input wire rst,
    input wire rx_in,
    output wire rx_err_flg,
    output wire rx_done,
    output wire tx_out,
    output wire tx_busy,
    output wire tx_done
);

wire tick;
wire [7:0] rx_out;

BAUD_GENERATOR baud (clk, rst, tick);
RX_MODULE rx (clk, rst, rx_in, tick, rx_out, rx_err_flg, rx_done);
TX_MODULE tx (clk, rst, rx_out, tick, rx_done, tx_out, tx_busy, tx_done);

endmodule
