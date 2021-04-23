`timescale 1ps/1ps

/*  Specifications of Vector Register File
    - 16 16-element, 16-bit vector registers
    - Reads have 0 cycle latency
    - Writes have 1 cycle latency
    - 2 read ports return an entire vector register with its length
    - A third read port retuns one entry of a vector register
    - 1 write port allows writing one entry of a vector register
*/


module vregs(input clk,
    input [3:0]rAddr0, output [255:0]rData0, output rLen0,
    input [3:0]rAddr1, output [255:0]rData1, output rLen1,
    //input [3:0]rAddr2, input [3:0]rInd2, output [15:0]rData2, 
    input wEn, input [3:0]wAddr, input [3:0]wInd, input[15:0]wData);


    reg [255:0]data[0:15];

    assign rData0 = data[rAddr0];
    assign rData1 = data[rAddr1];
    wire rBitNum = rInd2 * 16;
    assign rdata2 = (data[raddr2])[rbitNum+15:rbitNum];

    wire wBitNum = wind * 16;
    always @(posedge clk) begin
        //$write("%d\n", data[0]);
        if (wen) begin
            (data[waddr])[wBitNum+15:wBitNum] <= wData;
        end
    end

endmodule
