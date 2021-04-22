`timescale 1ps/1ps

/*  Specifications
    - 16 64-element, 16-bit vector registers
*/

module vregs(input clk,
    input [5:0]raddr0_, output [1023:0]rdata0,
    input [5:0]raddr1_, output [1023:0]rdata1,
    input wen, input [5:0]waddr, input [1023:0]wdata);


    reg [63:0]data[0:63][0:15];

    reg [3:0]raddr0;
    reg [3:0]raddr1;

    assign rdata0 = data[raddr0][0];
    assign rdata1 = data[raddr1][0];

    always @(posedge clk) begin
        //$write("%d\n", data[0]);
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
        if (wen) begin
            data[waddr][0] <= wdata;
        end
    end

endmodule
