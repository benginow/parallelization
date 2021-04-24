`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end
      
    //clock
    wire clk;
    clock c0(clk);

    //counter integrated with halt
    reg halt = 0;
    counter ctr(halt,clk);

    //register file - 1 clock latency
    wire [3:0]regRAddr0;
    wire [15:0]regData0;
    wire [3:0]regRAddr1;
    wire [15:0]regData1;
    wire regWEn;
    wire [3:0]regWAddr;
    wire [15:0]regWData;
    regs regs(clk,
        regRAddr0, regData0,
        regRAddr1, regData1,
        regWEn, regWAddr, regWData);

    wire [3:0]vregRAddr0;
    wire [255:0]vregData0;
    wire [3:0]vregRAddr1;
    wire [255:0]vregData1;
    wire vregWEn;
    wire [3:0]vregWAddr;
    wire [255:0]vregWData;
     regs vregs(clk,
        vregRAddr0, vregData0,
        vregRAddr1, vregData1,
        vregWEn, vregWAddr, vregWData);


     //instr mem
     wire [15:0]instr_mem_raddr;
     wire [15:0]instr_mem_data;
    instr_bank instr_mem(clk,
         instr_mem_raddr[15:1], memData0);

     //a counter that keeps track of 
    wire counter = 0;

     wire mem_bank_0_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank0 mem(clk,
         mem_bank_0_raddr[15:1], mem_bank_0_data,
         mem_bank_0_wen, mem_bank_0_waddr[15:1], mem_bank_0_wdata);

    wire mem_bank_1_wen;
    wire[15:0] mem_bank_1_raddr;
    wire[15:0] mem_bank_1_data;
    wire[15:0] mem_bank_1_waddr;
    mem_bank1 mem(clk,
         mem_bank_1_raddr[15:1], memData0,
         mem_bank_1_wen, memWAddr[15:1], memWData);

    wire mem_bank_2_wen;
    wire[15:0] mem_bank_2_raddr;
    wire[15:0] mem_bank_2_data;
    wire[15:0] mem_bank_2_waddr;
    mem_bank2 mem(clk,
         mem_bank_2_raddr[15:1], memData0,
         mem_bank_2_wen, memWAddr[15:1], memWData);

    wire mem_bank_3_wen;
    wire[15:0] mem_bank_3_raddr;
    wire[15:0] mem_bank_3_data;
    wire[15:0] mem_bank_3_waddr;
    mem_bank3 mem(clk,
         mem_bank_3_raddr[15:1], memData0,
         mem_bank_3_wen, memWAddr[15:1], memWData);

    wire mem_bank_4_wen;
    wire[15:0] mem_bank_4_raddr;
    wire[15:0] mem_bank_4_data;
    wire[15:0] mem_bank_4_waddr;
    mem_bank4 mem(clk,
         mem_bank_4_raddr[15:1], memData0,
         mem_bank_4_wen, memWAddr[15:1], memWData);

    wire mem_bank_5_wen;
    wire[15:0] mem_bank_5_raddr;
    wire[15:0] mem_bank_5_data;
    wire[15:0] mem_bank_5_waddr;
    mem_bank5 mem(clk,
         mem_bank_5_raddr[15:1], memData0,
         mem_bank_5_wen, memWAddr[15:1], memWData);

    wire mem_bank_6_wen;
    wire[15:0] mem_bank_6_raddr;
    wire[15:0] mem_bank_6_data;
    wire[15:0] mem_bank_6_waddr;
    mem_bank6 mem(clk,
         mem_bank_6_raddr[15:1], memData0,
         mem_bank_6_wen, memWAddr[15:1], memWData);

    wire mem_bank_7_wen;
    wire[15:0] mem_bank_7_raddr;
    wire[15:0] mem_bank_7_data;
    wire[15:0] mem_bank_7_waddr;
    mem_bank7 mem(clk,
         mem_bank_7_raddr[15:1], memData0,
         mem_bank_7_wen, memWAddr[15:1], memWData);

    wire mem_bank_8_wen;
    wire[15:0] mem_bank_8_raddr;
    wire[15:0] mem_bank_8_data;
    wire[15:0] mem_bank_8_waddr;
    mem_bank8 mem(clk,
         mem_bank_8_raddr[15:1], memData0,
         mem_bank_8_wen, memWAddr[15:1], memWData);

    wire mem_bank_9_wen;
    wire[15:0] mem_bank_9_raddr;
    wire[15:0] mem_bank_9_data;
    wire[15:0] mem_bank_9_waddr;
    mem_bank9 mem(clk,
         mem_bank_9_raddr[15:1], memData0,
         mem_bank_9_wen, memWAddr[15:1], memWData);

    wire mem_bank_10_wen;
    wire[15:0] mem_bank_10_raddr;
    wire[15:0] mem_bank_10_data;
    wire[15:0] mem_bank_10_waddr;
    mem_bank10 mem(clk,
         mem_bank_10_raddr[15:1], memData0,
         mem_bank_10_wen, memWAddr[15:1], memWData);

    wire mem_bank_11_wen;
    wire[15:0] mem_bank_11_raddr;
    wire[15:0] mem_bank_11_data;
    wire[15:0] mem_bank_11_waddr;
    mem_bank11 mem(clk,
         mem_bank_11_raddr[15:1], memData0,
         mem_bank_11_wen, memWAddr[15:1], memWData);

    wire mem_bank_12_wen;
    wire[15:0] mem_bank_12_raddr;
    wire[15:0] mem_bank_12_data;
    wire[15:0] mem_bank_12_waddr;
    mem_bank12 mem(clk,
         mem_bank_12_raddr[15:1], memData0,
         mem_bank_12_wen, memWAddr[15:1], memWData);

    wire mem_bank_13_wen;
    wire[15:0] mem_bank_13_raddr;
    wire[15:0] mem_bank_13_data;
    wire[15:0] mem_bank_13_waddr;
    mem_bank13 mem(clk,
         mem_bank_13_raddr[15:1], memData0,
         mem_bank_13_wen, memWAddr[15:1], memWData);

    wire mem_bank_14_wen;
    wire[15:0] mem_bank_14_raddr;
    wire[15:0] mem_bank_14_data;
    wire[15:0] mem_bank_14_waddr;
    mem_bank14 mem(clk,
         mem_bank_14_raddr[15:1], memData0,
         mem_bank_14_wen, memWAddr[15:1], memWData);

    wire mem_bank_15_wen;
    wire[15:0] mem_bank_15_raddr;
    wire[15:0] mem_bank_15_data;
    wire[15:0] mem_bank_15_waddr;
    mem_bank15 mem(clk,
         mem_bank_15_raddr[15:1], memData0,
         mem_bank_15_wen, memWAddr[15:1], memWData);

    wire mem_bank_16_wen;
    wire[15:0] mem_bank_16_raddr;
    wire[15:0] mem_bank_16_data;
    wire[15:0] mem_bank_16_waddr;
    mem_bank16 mem(clk,
         mem_bank_16_raddr[15:1], memData0,
         mem_bank_16_wen, memWAddr[15:1], memWData);
    
    reg[15:0]f1_pc = 0;
    reg[15:0]f2_pc = 16'hffff;
    reg[15:0]d_pc = 16'hffff;

    assign instr_mem_raddr = f1_pc;

    wire[15:0]d_ins = instr_mem_data;
    
    always @(posedge clk) begin
         f1_pc <= f1_pc + 2;
    end 

    always @(posedge clk) begin
         f2_pc <= f1_pc;
    end 
    


endmodule
