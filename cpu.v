`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end
      
    //clock
    wire clk;
    clock clock(clk);

    //counter integrated with halt
    reg halt = 0;
    counter ctr(halt,clk);

    //scalar register file - 1 clock latency
    wire [3:0]reg_raddr0;
    wire [15:0]reg_data0;
    wire [3:0]reg_raddr1;
    wire [15:0]reg_data1;
    wire reg_wen;
    wire [3:0]reg_waddr;
    wire [15:0]reg_wdata;
    regs regs(clk,
        reg_raddr0, reg_data0,
        reg_raddr1, reg_data1,
        reg_wen, reg_waddr, reg_wdata);

    //vector register file - 1 clock latency
    wire [3:0]vreg_raddr0;
    wire [255:0]vreg_data0;
    wire [15:0]vreg_len0;
    wire [3:0]vreg_raddr1;
    wire [255:0]vreg_data1;
    wire [15:0]vreg_len1;
    wire vreg_wen;
    wire [3:0]vreg_waddr;
    wire [255:0]vreg_wdata;
    regs vregs(clk,
        vreg_raddr0, vreg_data0,
        vreg_raddr1, vreg_data1,
        vreg_wen, vreg_waddr, vreg_wdata);
    
    //instr mem - 2 clock latency
    wire [15:0]instr_mem_raddr;
    wire [15:0]instr_mem_data;
    assign instr_mem_raddr = f1_pc;
    instr_bank instr_mem(clk,
        instr_mem_raddr[15:1], instr_mem_data);

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
        mem_bank_1_raddr[15:1], mem_bank_1_data,
        mem_bank_1_wen, mem_bank_1_waddr[15:1], mem_bank_1_wdata);

    wire mem_bank_2_wen;
    wire[15:0] mem_bank_2_raddr;
    wire[15:0] mem_bank_2_data;
    wire[15:0] mem_bank_2_waddr;
    mem_bank2 mem(clk,
        mem_bank_2_raddr[15:1], mem_bank_2_data,
        mem_bank_2_wen, mem_bank_2_waddr[15:1], mem_bank_2_wdata);

    wire mem_bank_3_wen;
    wire[15:0] mem_bank_3_raddr;
    wire[15:0] mem_bank_3_data;
    wire[15:0] mem_bank_3_waddr;
    mem_bank3 mem(clk,
        mem_bank_3_raddr[15:1], mem_bank_3_data,
        mem_bank_3_wen, mem_bank_3_waddr[15:1], mem_bank_3_wdata);

    //global control signal
    //we flush if a jump needs to be taken in wb
    //if we are jumping, then we are flushing
    wire flush = wb_is_jmp;

    //==========================FETCH 1==========================
    reg[15:0] f1_pc = 0;
    //only fetch one begins as valid
    wire f1_valid = 1;
    //we want to stall for vector operations
    //when we stall, we just want to sent the same values back
    wire f1_stall = 2_stall;

    always @(posedge clk) begin
        if (!flush && !stall) begin
            //if we are not jumping, no need to do anything fancy
            //when we jump, we set the pc in writeback to be 
            f1_pc <= f1_pc + 2;
            //if we are flushing, we want the next guy to be invalid
            f2_valid <= 0;
        end
    end

    //==========================FETCH 2==========================
    reg[15:0] f2_pc = 16'hffff;
    wire f2_stall = d_stall;
    reg f2_valid = 0;
    
    always @(posedge clk) begin
        if (!stall) begin
            f2_pc <= f1_pc;
            f2_invalid <= f1_flush ? 1 : f1_valid;
        end
    end

    //==========================DECODE==========================
    reg[15:0] d_pc = 16'hffff;
    wire d_stall = fr_stall;
    reg d_valid = 0;
    
    //newly gathered information
    wire[15:0] d_ins = instr_mem_data;
    //if we do need to stall b/c of a vector op, we want to 
    //know how many cycles to stall for
    //div by 4, then, if the last two bits aren't 0, add 1
    reg[3:0] d_stall_cycle = 0;

    reg[15:0] d_last_ins;

    wire d_is_add = d_opcode == 4'b0000;
    wire d_is_sub = d_opcode == 4'b0001;
    wire d_is_mul = d_opcode == 4'b0010;
    wire d_is_div = d_opcode == 4'b0011;

    wire d_is_movl = d_opcode == 4'b0100;
    wire d_is_movh = d_opcode == 4'b0101;
    wire d_is_jmp = d_opcode == 4'b0110;

    wire d_is_jz = d_is_jmp && d_subcode == 0;
    wire d_is_jnz = d_is_jmp && d_subcode == 1;
    wire d_is_js = d_is_jmp && d_subcode == 2;
    wire d_is_jns = d_is_jmp && d_subcode == 3;

    wire d_is_scalar_mem = d_opcode == 4'b0100;
    wire d_is_mem = (d_isScalarMem) || 
                (d_opcode == 4'b1100) ||
                (d_opcode == 4'b1101);
    wire d_is_ld = d_is_mem && d_subcode == 0;
    wire d_is_st = d_is_mem && d_subcode == 1;
    
    wire d_is_vadd = d_opcode == 4'b1000;
    wire d_is_vsub = d_opcode == 4'b1001;
    wire d_is_vmul = d_opcode == 4'b1010;
    wire d_is_vdiv = d_opcode == 4'b1011;

    wire d_is_vld = d_opcode == 4'b1110;
    wire d_is_vst = d_opcode == 4'b1101;

    wire d_is_vdot = d_opcode == 4'1110;

    wire d_is_halt = d_opcode == 4'1111;
    
    wire d_is_vector_op = d_is_vadd || d_is_vsub || d_is_vmul || d_is_vdiv || d_is_vld || d_is_vst || d_is_vdot;

    wire[3:0] d_ra = d_ins[11:8];
    wire[3:0] d_rb = d_ins[7:4];
    wire[3:0] d_rt = d_ins[3:0];

    wire d_rx = (d_is_add || d_is_sub || d_is_mul || d_is_div) ||
            (d_is_vadd || d_is_vsub || d_is_vmul || d_is_vdiv) ?
            d_rb : d_rt;



endmodule