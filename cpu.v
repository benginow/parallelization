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
    //reads ra
    wire [3:0]regRAddr0;
    wire [15:0]regData0;
    //reads rx
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
     assign instr_mem_raddr = f1_pc;
     wire[15:0] instr_mem_data;
    instr_bank instr_mem(clk,
         instr_mem_raddr[15:1], instr_mem_data);

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
    
     wire flush; //global control signal
    
    //===============FETCH 1===============
    reg[15:0]f1_pc = 0;
    wire f1_valid = 1;
    wire f1_stall;
    always @(posedge clk) begin
         //work on the flush logic!!
         if (!f1_flush) begin
              //if we're flushing, we don't want to keep incrementing
              f1_pc <= f1_pc + 2;
         end
    end 

    //===============FETCH 2===============
    wire f2_stall;
    reg[15:0]f2_pc = 16'hffff;
    reg f2_valid <= 0;
    always @(posedge clk) begin
          f2_pc <= f1_pc;
          //if f1 is an invalid wire, we want the next to be invalid
          f2_invalid <= f1_flush ? 1 : f1_invalid;
    end 

    //===============DECODE===============
    reg[15:0]d_pc = 16'hffff;
    reg d_valid <= 0;
    wire[15:0]d_ins = instr_mem_data;

    wire [3:0]d_opcode = d_ins[15:12];
    wire [3:0]d_subcode = d_ins[7:4];

     wire d_isAdd = d_opcode == 4'b0000;
    wire d_isSub = d_opcode == 4'b0001;
     wire d_isMul = d_opcode == 4'b0010;
     wire d_isDiv = d_opcode == 4'b0011;

    wire d_isMovl = d_opcode == 4'b0100;
    wire d_isMovh = d_opcode == 4'b0101;
    wire d_isJmp = d_opcode == 4'b0110;
    wire d_isScalarMem = d_opcode == 4'b0100;
    wire d_isMem = (isScalarMem) || 
               (d_opcode == 4'b1100) ||
               (d_opcode == 4'b1101);

    wire d_isJz = d_isJmp && d_subcode == 0;
    wire d_isJnz = d_isJmp && d_subcode == 1;
    wire d_isJs = d_isJmp && d_subcode == 2;
    wire d_isJns = d_isJmp && d_subcode == 3;

    wire d_isLd = d_isMem && d_subcode == 0;
    wire d_isSt = d_isMem && d_subcode == 1;
    
    wire d_isVadd = d_opcode == 4'b1000;
    wire d_isVsub = d_opcode == 4'b1001;
    //just multiply each element
    wire d_isVmul = d_opcode == 4'b1010;
    wire d_isVdiv = d_opcode == 4'b1011;

    wire d_isVld = d_opcode == 4'b1110;
    wire d_isVst = d_opcode == 4'b1101;

    wire d_isVdot = d_opcode == 4'1110;

    wire d_isHalt = d_opcode == 4'1111;

    wire d_is_vector_op = d_isVadd || d_isVsub || d_isVmul || d_isVdiv 
               || d_isVld || d_isVst || d_isVdot;

     wire d_ra = d_ins[11:8];
     wire d_rb = d_ins[7:4];
     wire d_rt = d_ins[3:0];

     wire d_rx = (d_isAdd || d_isSub || d_isMul || d_isDiv) ||
               (d_isVadd || d_isVsub || d_isVmul || d_isVdiv) ?
               d_rb : d_rt;

     reg [15:0]d_lastIns;
     reg d_stallCycle = 0;
     wire d_stall;
    always @(posedge clk) begin
         d_pc <= f2_pc;
         d_invalid <= f2_invalid;
          d_lastIns <= instr_mem_data;
    end

     //================================FETCH REGS===========================================

     wire[15:0] fr_ra_val;
     wire[15:0] fr_rx_val;
     //we also need 
     wire[3:0] fr_vra_size;
     wire[15:0] fr_vra_val;
     //we want to stall by div 4 cycles
     //if its not divisible by 4 -> ?? TODO: fix
     //stalling logic
     reg [3:0]fr_stallState; //0 = not stalling, 1 = final stall cycle, 2 = 2nd final...
     wire[2:0] fr_num_stall_cycles = fr_vra_size << 2 + fr_vra_size[1:0]; //TODO check sizes
     wire fr_stall_signal = (fr_stallState === 1 || fr_stallState !== 0); 

     wire[3:0] fr_vrx_size;
     wire[15:0] fr_vrx_val;

     //values percolated from decode
     wire fr_valid = 0;
    reg [15:0]fr_pc;
    reg [15:0]fr_ins;
    reg [3:0]fr_opcode;
    reg [3:0]fr_subcode;

    reg fr_isAdd;
    reg fr_isSub;
    reg fr_isMul;
    reg fr_isDiv;
    
    reg fr_isMovl;
    reg fr_isMovh;
    reg fr_isJmp;
    reg fr_isScalarMem;
    reg fr_isMem;

    reg fr_isJz;
    reg fr_isJnz;
    reg fr_isJs;
    reg fr_isJns;

    reg fr_isLd;
    reg fr_isSt;

    reg fr_isVadd;
    reg fr_isVsub;
    reg fr_isVmul;
    reg fr_isVdiv;

    reg fr_isVld;
    reg fr_isVst;

    reg fr_isVdot;
    reg fr_isHalt;

    reg fr_is_vector_op;

    reg fr_ra;
    reg fr_rx;

    reg[15:0] fr_ra_val;
    reg[15:0] fr_rx_val;

    always @(posedge clk) begin
         //here, we want to decide, if this is a vector op, how many cycles to stall for
          fr_stall_cycles <= fr_stall_cycles_temp - 1;

         //percolate values
          fr_valid <= d_valid;
        fr_pc <= d_pc;
        fr_ins <= d_ins;
        fr_opcode <= d_opcode;
        fr_subcode <= d_subcode;

        fr_isAdd <= d_isAdd;
        fr_isSub <= d_isSub;
        fr_isMul <= d_isMul;
        fr_isDiv <= d_isDiv;

        fr_isMovl <= d_isMovl;
        fr_isMovh <= d_isMovh;
        fr_isJmp <= d_isJmp;
        fr_isScalarMem <= d_isScalarMem;
        fr_isMem <= d_isMem;

        fr_isVadd <= d_isVadd;
        fr_isVsub <= d_isVsub;
        fr_isVmul <= d_isVmul;
        fr_isVdiv <= d_isVdiv;

        fr_isJz <= d_isJz;
        fr_isJnz <= d_isJnz;
        fr_isJs <= d_isJs;
        fr_isJns <= d_isJns;

        fr_isLd <= d_isLd;
        fr_isSt <= d_isSt;

        fr_isVld <= d_isVld;
        fr_isVst <= d_isVst;

        fr_isVdot <= d_isVdot;
        fr_isHalt <= d_isHalt;

        fr_is_vector_op <= d_is_vector_op;

        fr_ra <= d_ra;
        fr_rb <= d_ra;
        fr_rt <= d_rt;

        fr_rx <= d_rx;

        fr_ra_val <= d_ra_val;
        fr_rx_val <= d_rx_val;
    end

     // we will have four pipelines
    exec_to_wb_pipe pipe_0(,,,,);

     //valid when it's a vector op and we want to continue doing the vector op
     //we need the vector length and then 
    wire pipe_1_valid = fr_is_vector_op;
    exec_to_wb_pipe pipe_1(,,,,);

     wire pipe_2_valid = !fr_isScalarMem;
    exec_to_wb_pipe pipe_2(,,,,);

     wire pipe_3_valid = !fr_isScalarMem;
    exec_to_wb_pipe pipe_3(,,,,);


    //================================WRITEBACK===========================================
    always @(posedge clk) begin
         
    end
    


endmodule
