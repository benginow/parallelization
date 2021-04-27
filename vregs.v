`timescale 1ps/1ps

/*  Specifications of Vector Register File
    - 16 16-element, 16-bit vector registers
    - Reads have 0 cycle latency
    - Writes have 1 cycle latency
    - 2 read ports return an entire vector register with its length
    - A third read port retuns one entry of a vector register
    - 1 write port allows writing one entry of a vector register
*/

//fart
//this should take one clock cycle
module vregs(input clk, 
    input [3:0]rAddr0, output [255:0]rData0, output rLen0,
    input [3:0]rAddr1, output [255:0]rData1, output rLen1,
    input wEn, input [3:0]wAddr, input[255:0]wData);

    //we can store 16 8x8 matrices
    reg [255:0]data[0:15];

    assign rData0 = data[rAddr0];
    assign rData1 = data[rAddr1];

    //wire wBitNum = wind * 16;
    always @(posedge clk) begin
        if (wEn) begin
            data[wAddr] <= wData;
        end
    end

endmodule
