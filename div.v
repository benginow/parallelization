 `timescale 1ps/1ps

module div(input clk, input [15:0]first_, input [15:0]second, output [15:0]out
    output[15:0] modulo);
    
    integer i;
    wire[15:0] out;
    wire[15:0] modulo;
    wire[15:0] first = first_;

    begin @(posedge clk) begin
        while (first > second) begin
            first = first - second;
        end
    end

endmodule