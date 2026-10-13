module BAUD_GENERATOR (
    input wire clk,
    input wire rst,
    output reg tick
);
reg [5:0] baud_cnt;

always @(posedge clk) begin
    if (rst) begin
        baud_cnt <= 6'b000000;
        tick <= 1'b0;
    end else begin
        baud_cnt <= baud_cnt + 1;
        tick <= 1'b0;
    end
    if (baud_cnt == 6'b110101) begin
        baud_cnt <= 6'b000000;
        tick <= 1'b1;
    end     
end   
endmodule