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
    input [3:0]rAddr0, output [255:0]rData0, output[3:0] r_len0,
    input [3:0]rAddr1, output [255:0]rData1, output[3:0] r_len1,
    input wEn, input [3:0]wAddr, input[3:0]wLen, input[255:0]wData);

    //we can store 16 8x8 matrices
    reg [255:0]data[0:15];
    reg [3:0]dataLen[0:15];

    assign rData0 = data[rAddr0];
    assign rData1 = data[rAddr1];

    assign r_len0 = dataLen[rAddr0];
    assign r_len1 = dataLen[rAddr1];

    always @(posedge clk) begin
        if (wEn) begin
            data[wAddr] <= wData;
            dataLen[wAddr] <= wLen;
        end
    end

    //WIRES FOR DEBUGGING PURPOSES
    wire[255:0]vreg0 = data[0];
    wire[255:0]vreg1 = data[1];
    wire[255:0]vreg2 = data[2];
    wire[255:0]vreg3 = data[3];
    wire[255:0]vreg4 = data[4];
    wire[255:0]vreg5 = data[5];
    wire[255:0]vreg6 = data[6];
    wire[255:0]vreg7 = data[7];
    wire[255:0]vreg8 = data[8];
    wire[255:0]vreg9 = data[9];
    wire[255:0]vreg10 = data[10];
    wire[255:0]vreg11 = data[11];
    wire[255:0]vreg12 = data[12];
    wire[255:0]vreg13 = data[13];
    wire[255:0]vreg14 = data[14];
    wire[255:0]vreg15 = data[15];

    wire[3:0]vreg0_len = dataLen[0];
    wire[3:0]vreg1_len = dataLen[1];
    wire[3:0]vreg2_len = dataLen[2];
    wire[3:0]vreg3_len = dataLen[3];
    wire[3:0]vreg4_len = dataLen[4];
    wire[3:0]vreg5_len = dataLen[5];
    wire[3:0]vreg6_len = dataLen[6];
    wire[3:0]vreg7_len = dataLen[7];
    wire[3:0]vreg8_len = dataLen[8];
    wire[3:0]vreg9_len = dataLen[9];
    wire[3:0]vreg10_len = dataLen[10];
    wire[3:0]vreg11_len = dataLen[11];
    wire[3:0]vreg12_len = dataLen[12];
    wire[3:0]vreg13_len = dataLen[13];
    wire[3:0]vreg14_len = dataLen[14];
    wire[3:0]vreg15_len = dataLen[15];

endmodule
