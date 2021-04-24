`timescale 1ps/1ps

module instr_mem(input clk,
    input [15:1]raddr0_, output [15:0]rdata0_);

    reg [15:0]data[0:16'h7fff];

    /* Simulation -- read initial content from file */
    initial begin
        $readmemh("mem.hex",data);
    end

    reg [15:1]raddr0;
    reg [15:0]rdata0;

    assign rdata0_ <= rdata0;

    always @(posedge clk) begin
        raddr0 <= raddr0_;
        rdata0 <= data[raddr0];
    end

endmodule
