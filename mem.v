`timescale 1ps/1ps

module mem(input clk,
    input [15:1]raddr0_, output [15:0]rdata0_,
    input wen, input [15:1]waddr, input [15:0]wdata);

    reg [15:0]data[0:16'h7fff];

    reg [15:1]raddr0;
    reg [15:0]rdata0;

    assign rdata0_ = rdata0;

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        rdata0 <= data[raddr0];
        if (wen) begin
            data[waddr] <= wdata;
        end
    end

    //WIRES FOR DEBUGGING PURPOSES
    wire [15:0]data00 = data[0];
    wire [15:0]data02 = data[1];
    wire [15:0]data04 = data[2];
    wire [15:0]data06 = data[3];

endmodule
