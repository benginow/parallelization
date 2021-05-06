`timescale 1ps/1ps

module regs(input clk,
    input [3:0]raddr0_, output [15:0]rdata0,
    input [3:0]raddr1_, output [15:0]rdata1,
    input wen, input [3:0]waddr, input [15:0]wdata);

    reg [15:0]data[0:15];

    wire[15:0] reg0 = data[0];
    wire[15:0] reg1 = data[1];
    wire[15:0] reg2 = data[2];
    wire[15:0] reg3 = data[3];
    wire[15:0] reg4 = data[4];
    wire[15:0] reg5 = data[5];
    wire[15:0] reg6 = data[6];
    wire[15:0] reg7 = data[7];
    wire[15:0] reg8 = data[8];
    wire[15:0] reg9 = data[9];
    wire[15:0] reg10 = data[10];
    wire[15:0] reg11 = data[11];
    wire[15:0] reg12 = data[12];
    wire[15:0] reg13 = data[13];
    wire[15:0] reg14 = data[14];
    wire[15:0] reg15 = data[15];


    reg [3:0]raddr0;
    reg [3:0]raddr1;

    assign rdata0 = data[raddr0];
    assign rdata1 = data[raddr1];

    always @(posedge clk) begin
        //$write("%d\n", data[0]);
        raddr0 <= raddr0_;
        raddr1 <= raddr1_;
        if (wen) begin
            data[waddr] <= wdata;
        end
    end

endmodule
