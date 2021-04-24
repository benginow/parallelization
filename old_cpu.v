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
         memRAddr0[15:1], memData0);

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
         memRAddr0[15:1], memData0,
         mem_bank_1_wen, memWAddr[15:1], memWData);

    wire mem_bank_2_wen;
    wire[15:0] mem_bank_2_raddr;
    wire[15:0] mem_bank_2_data;
    wire[15:0] mem_bank_2_waddr;
    mem_bank2 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_2_wen, memWAddr[15:1], memWData);

    wire mem_bank_3_wen;
    wire[15:0] mem_bank_3_raddr;
    wire[15:0] mem_bank_3_data;
    wire[15:0] mem_bank_3_waddr;
    mem_bank3 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_3_wen, memWAddr[15:1], memWData);

    wire mem_bank_4_wen;
    wire[15:0] mem_bank_4_raddr;
    wire[15:0] mem_bank_4_data;
    wire[15:0] mem_bank_4_waddr;
    mem_bank4 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_4_wen, memWAddr[15:1], memWData);

    wire mem_bank_5_wen;
    wire[15:0] mem_bank_5_raddr;
    wire[15:0] mem_bank_5_data;
    wire[15:0] mem_bank_5_waddr;
    mem_bank5 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_5_wen, memWAddr[15:1], memWData);

    wire mem_bank_6_wen;
    wire[15:0] mem_bank_6_raddr;
    wire[15:0] mem_bank_6_data;
    wire[15:0] mem_bank_6_waddr;
    mem_bank6 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_6_wen, memWAddr[15:1], memWData);

    wire mem_bank_7_wen;
    wire[15:0] mem_bank_7_raddr;
    wire[15:0] mem_bank_7_data;
    wire[15:0] mem_bank_7_waddr;
    mem_bank7 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_7_wen, memWAddr[15:1], memWData);

    wire mem_bank_8_wen;
    wire[15:0] mem_bank_8_raddr;
    wire[15:0] mem_bank_8_data;
    wire[15:0] mem_bank_8_waddr;
    mem_bank8 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_8_wen, memWAddr[15:1], memWData);

    wire mem_bank_9_wen;
    wire[15:0] mem_bank_9_raddr;
    wire[15:0] mem_bank_9_data;
    wire[15:0] mem_bank_9_waddr;
    mem_bank9 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_9_wen, memWAddr[15:1], memWData);

    wire mem_bank_10_wen;
    wire[15:0] mem_bank_10_raddr;
    wire[15:0] mem_bank_10_data;
    wire[15:0] mem_bank_10_waddr;
    mem_bank10 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_10_wen, memWAddr[15:1], memWData);

    wire mem_bank_11_wen;
    wire[15:0] mem_bank_11_raddr;
    wire[15:0] mem_bank_11_data;
    wire[15:0] mem_bank_11_waddr;
    mem_bank11 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_11_wen, memWAddr[15:1], memWData);

    wire mem_bank_12_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank12 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_12_wen, memWAddr[15:1], memWData);

    wire mem_bank_13_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank13 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_13_wen, memWAddr[15:1], memWData);

    wire mem_bank_14_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank14 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_14_wen, memWAddr[15:1], memWData);

    wire mem_bank_15_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank15 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_15_wen, memWAddr[15:1], memWData);

    wire mem_bank_16_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    mem_bank16 mem(clk,
         memRAddr0[15:1], memData0,
         mem_bank_16_wen, memWAddr[15:1], memWData);
    //control signals and structures
    //control precedence: halt > flush > stall
    wire haltSig;
    wire flush;
    wire stall; //next cycle will be stall cycle
    reg stallCycle = 0; //stall cycle = all stages do same thing as last cycle
    reg uninitR0 = 1; //r0 must be initialized at first    

    /*
    *   FETCH (f) STAGE
    *   Provides address to memory to fetch an instruction from
    */
    reg [15:0]next_pc = 16'h0000; //modified by writeback stage
    assign memRAddr0 = stall ? f_pc : next_pc; //instructions will come from memData0
    reg f_valid = 0;
    reg [15:0]f_pc; //PC currently in MAR
    always @(posedge clk) begin
        if(!f_valid) f_valid <= 1;
        else f_valid <= flush ? 0 : 1;
        f_pc <= stall ? f_pc : next_pc;
    end

    /*
    *   DECODE (d) STAGE
    *   Determine which registers are necessary to read from
    *   Determine the type of the instruction
    */
    reg d_valid = 0;
    reg [15:0]d_pc;
    reg [15:0]d_lastIns; //need to save for stall cycles since memory output is temp. false
    wire [15:0]d_ins = stallCycle ? d_lastIns : memData0;

    //decode instruction type for future stages
    wire [3:0]d_opcode = d_ins[15:12];
    wire [3:0]d_subcode = d_ins[7:4];

    wire d_isSub = d_opcode == 4'b0000;
    wire d_isMovl = d_opcode == 4'b1000;
    wire d_isMovh = d_opcode == 4'b1001;
    wire d_isJmp = d_opcode == 4'b1110;
    wire d_isMem = d_opcode == 4'b1111;

    wire d_isJz = d_isJmp && d_subcode == 0;
    wire d_isJnz = d_isJmp && d_subcode == 1;
    wire d_isJs = d_isJmp && d_subcode == 2;
    wire d_isJns = d_isJmp && d_subcode == 3;

    wire d_isLd = d_isMem && d_subcode == 0;
    wire d_isSt = d_isMem && d_subcode == 1;

    wire d_isVld = d_opcode == 4'b1110;
    wire d_isVadd = d_opcode == 4'b1000;
    wire d_isVsub = d_opcode == 4'b1001;
    //just multiply each element
    wire d_isVmul = d_opcode == 4'b1010;
    wire d_isVdiv = d_opcode == 4'b
    
    //prep reg reading for execute
    wire [3:0]d_ra = d_ins[11:8];
    wire [3:0]d_rb = d_ins[7:4];
    wire [3:0]d_rt = d_ins[3:0];
    wire [3:0]d_rx; //rx: the second register whose val is needed based on instruction
    assign d_rx = (d_isSub) ? d_rb : d_rt; //only sub needs rbVal

    assign regRAddr0 = d_ra;
    assign regRAddr1 = d_rx;

    always @(posedge clk) begin
        d_valid <= flush ? 0 : stall ? d_valid : f_valid;
        d_pc <= stall ? d_pc : f_pc;
        d_lastIns <= memData0;
    end

    

endmodule
