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
    wire [3:0]vreg_len0;
    wire [3:0]vreg_raddr1;
    wire [255:0]vreg_data1;
    wire [3:0]vreg_len1;
    wire vreg_wen;
    wire [3:0]vreg_waddr;
    wire [3:0]vreg_wlen;
    wire [255:0]vreg_wdata;
    vregs vregs(clk,
        vreg_raddr0, vreg_data0, vreg_len0,
        vreg_raddr1, vreg_data1, vreg_len1,
        vreg_wen, vreg_waddr, vreg_wlen, vreg_wdata);

    
    //instr mem - 2 clock latency
    wire [15:0]instr_mem_raddr;
    wire [15:0]instr_mem_data;
    assign instr_mem_raddr = f1_pc;
    instr_mem instr_bank(clk,
        instr_mem_raddr[15:1], instr_mem_data);

    /* Data Memory
        - Split into 4 banks instead of 1 contiguous module
        - Bank X will hold addresses where address % 4 = X
    */

    wire mem_bank_0_wen;
    wire[15:0] mem_bank_0_raddr;
    wire[15:0] mem_bank_0_data;
    wire[15:0] mem_bank_0_waddr;
    wire[15:0] mem_bank_0_wdata;
    mem mem_bank0(clk,
        mem_bank_0_raddr[15:1], mem_bank_0_data,
        mem_bank_0_wen, mem_bank_0_waddr[15:1], mem_bank_0_wdata);

    wire mem_bank_1_wen;
    wire[15:0] mem_bank_1_raddr;
    wire[15:0] mem_bank_1_data;
    wire[15:0] mem_bank_1_waddr;
    wire[15:0] mem_bank_1_wdata;
    mem mem_bank1(clk,
        mem_bank_1_raddr[15:1], mem_bank_1_data,
        mem_bank_1_wen, mem_bank_1_waddr[15:1], mem_bank_1_wdata);

    wire mem_bank_2_wen;
    wire[15:0] mem_bank_2_raddr;
    wire[15:0] mem_bank_2_data;
    wire[15:0] mem_bank_2_waddr;
    wire[15:0] mem_bank_2_wdata;
    mem mem_bank2(clk,
        mem_bank_2_raddr[15:1], mem_bank_2_data,
        mem_bank_2_wen, mem_bank_2_waddr[15:1], mem_bank_2_wdata);

    wire mem_bank_3_wen;
    wire[15:0] mem_bank_3_raddr;
    wire[15:0] mem_bank_3_data;
    wire[15:0] mem_bank_3_waddr;
    wire[15:0] mem_bank_3_wdata;
    mem mem_bank3(clk,
        mem_bank_3_raddr[15:1], mem_bank_3_data,
        mem_bank_3_wen, mem_bank_3_waddr[15:1], mem_bank_3_wdata);

    //global control signal
    //we flush if a jump needs to be taken in wb
    //if we are jumping, then we are flushing
    wire flush;

    //==========================FETCH 1==========================
    reg[15:0] f1_pc = 0;
    //only fetch one begins as valid
    wire f1_valid = 1;
    //we want to stall for vector operations
    //when we stall, we just want to sent the same values back
    wire f1_stall = f2_stall;


    always @(posedge clk) begin
        if (!flush && !f1_stall) begin
            //if we are not jumping, no need to do anything fancy
            //when we jump, we set the pc in writeback to be 
            f1_pc <= flush ? wb_next_pc : f1_pc + 2;
            //if we are flushing, we want the next guy to be invalid
        end
    end

    //==========================FETCH 2==========================
    reg[15:0] f2_pc;
    wire f2_stall = d_stall;
    reg f2_valid = 0;
    
    always @(posedge clk) begin
        if (!f2_stall) begin
            f2_pc <= f1_pc;
            //f2_valid <= f1_valid && !flush;
            f2_valid <= flush ? 0 : f1_valid;
        end
    end

    //==========================DECODE==========================
    reg[15:0] d_pc;
    wire d_stall = fr_stall;
    reg d_valid = 0;
    
    //newly gathered information
    wire[15:0] d_ins = instr_mem_data;
    wire[3:0] d_opcode = d_ins[15:12];
    wire[3:0] d_subcode = d_ins[7:4];

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
    wire d_is_mem = (d_is_scalar_mem) || 
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

    wire d_is_vdot = d_opcode == 4'b1110;

    wire d_is_halt = d_opcode == 4'b1111;
    
    wire d_is_vector_op = d_is_vadd || d_is_vsub || d_is_vmul || d_is_vdiv || d_is_vld || d_is_vst || d_is_vdot;

    wire[3:0] d_ra = d_ins[11:8];
    wire[3:0] d_rb = d_ins[7:4];
    wire[3:0] d_rt = d_ins[3:0];

    wire[3:0] d_rx = (d_is_add || d_is_sub || d_is_mul || d_is_div) ||
            (d_is_vadd || d_is_vsub || d_is_vmul || d_is_vdiv) ?
            d_rb : d_rt;

    assign reg_raddr0 = d_ra;
    assign reg_raddr1 = d_rx;
    assign vreg_raddr0 = d_ra;
    assign vreg_raddr0 = d_ra;

    always @(posedge clk) begin
        //if we're stalling, we don't want to percolate any vals down
        if (!d_stall) begin
            d_pc <= f2_pc;
            //if we aren't flushing, and if the previous isn't valid
            d_valid <= f2_valid && !flush;
            d_last_ins <= d_ins;
        end
    end

    //==========================FETCH REGS==========================
    //uhhhh.. unsure if this stall logic is correct
    reg fr_valid = 0;
    reg[15:0] fr_pc;
    reg[15:0] fr_ins;
    
    reg[3:0] fr_stall_state = 0;
    wire[2:0] fr_num_stall_cycles = fr_is_vector_op ? fr_vra_size << 2 + fr_vra_size[1:0] : 0;
    wire fr_stall = fr_valid && ((fr_stall_state === 1) || (fr_stall_state !== 0) || (fr_num_stall_cycles !== 0));

    reg[3:0] fr_ra;
    reg[3:0] fr_rx;

    //we don't care too much about decoding everything
    reg fr_is_vector_op;

    wire[15:0] fr_ra_val = reg_data0;
    wire[15:0] fr_rx_val = reg_data1;

    wire[3:0] fr_vra_size = vreg_len0;
    wire[3:0] fr_vrx_size = vreg_len0;
    wire[255:0] fr_vra_val = vreg_data0;
    wire[255:0] fr_vrx_val = vreg_data1;

    always @(posedge clk) begin
        fr_stall_state <= (fr_is_vector_op && fr_valid && fr_stall_state === 0) ? fr_num_stall_cycles - 1 :
                           (fr_is_vector_op && fr_valid) ? fr_stall_state - 1 : 0;
        if (!fr_stall) begin
            fr_valid <= d_valid && !flush;
            fr_pc <= d_pc;
            fr_ins <= d_ins;
            fr_is_vector_op <= d_is_vector_op;
            fr_ra <= d_ra;
            fr_rx <= d_rx;
        end
    end

    //we need to split up our items from the vregs when pipelining
    wire [15:0]vra_entry0 = fr_vra_val[255:240];
    wire [15:0]vra_entry1 = fr_vra_val[239:224];
    wire [15:0]vra_entry2 = fr_vra_val[223:208];
    wire [15:0]vra_entry3 = fr_vra_val[207:192];
    wire [15:0]vra_entry4 = fr_vra_val[191:176];
    wire [15:0]vra_entry5 = fr_vra_val[175:160];
    wire [15:0]vra_entry6 = fr_vra_val[159:144];
    wire [15:0]vra_entry7 = fr_vra_val[143:128];
    wire [15:0]vra_entry8 = fr_vra_val[127:112];
    wire [15:0]vra_entry9 = fr_vra_val[111:96];
    wire [15:0]vra_entry10 = fr_vra_val[95:80];
    wire [15:0]vra_entry11 = fr_vra_val[79:64];
    wire [15:0]vra_entry12 = fr_vra_val[63:48];
    wire [15:0]vra_entry13 = fr_vra_val[47:32];
    wire [15:0]vra_entry14 = fr_vra_val[31:16];
    wire [15:0]vra_entry15 = fr_vra_val[15:0];

    wire [15:0]vrx_entry0 = fr_vrx_val[255:240];
    wire [15:0]vrx_entry1 = fr_vrx_val[239:224];
    wire [15:0]vrx_entry2 = fr_vrx_val[223:208];
    wire [15:0]vrx_entry3 = fr_vrx_val[207:192];
    wire [15:0]vrx_entry4 = fr_vrx_val[191:176];
    wire [15:0]vrx_entry5 = fr_vrx_val[175:160];
    wire [15:0]vrx_entry6 = fr_vrx_val[159:144];
    wire [15:0]vrx_entry7 = fr_vrx_val[143:128];
    wire [15:0]vrx_entry8 = fr_vrx_val[127:112];
    wire [15:0]vrx_entry9 = fr_vrx_val[111:96];
    wire [15:0]vrx_entry10 = fr_vrx_val[95:80];
    wire [15:0]vrx_entry11 = fr_vrx_val[79:64];
    wire [15:0]vrx_entry12 = fr_vrx_val[63:48];
    wire [15:0]vrx_entry13 = fr_vrx_val[47:32];
    wire [15:0]vrx_entry14 = fr_vrx_val[31:16];
    wire [15:0]vrx_entry15 = fr_vrx_val[15:0];

    wire[15:0] pipe_0_ra_val = fr_is_vector_op ?
                               (fr_stall_state === 0 ? vra_entry0:
                                fr_stall_state === 1 ? vra_entry4:
                                fr_stall_state === 2 ? vra_entry8:
                                fr_stall_state === 3 ? vra_entry12 : 0): fr_ra_val;
    wire[15:0] pipe_0_rx_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vrx_entry0:
                                fr_stall_state === 1 ? vrx_entry4:
                                fr_stall_state === 2 ? vrx_entry8:
                                fr_stall_state === 3 ? vrx_entry12 : 0): fr_rx_val;

    //this is the ra val we want to percolate for scalars
    //TODO: MAKE SURE ALL IS WELL HERE
    //wire[15:0] 
    wire[15:0] x2_mem_0 = mem_bank_0_data;
    wire[15:0] x2_pipe_0_result;
    //we haven't quite dealt with this yet
    wire[15:0] x2_overflow_0;

    alu pipe_0(clk, fr_pc, fr_ins, pipe_0_ra_val, pipe_0_rx_val,
        x2_mem_0, x2_pipe_0_result, x2_overflow_0);

    wire[15:0] pipe_1_ra_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vra_entry1:
                                fr_stall_state === 1 ? vra_entry5:
                                fr_stall_state === 2 ? vra_entry10:
                                fr_stall_state === 3 ? vra_entry13:0): fr_ra_val;
    wire[15:0] pipe_1_rx_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vrx_entry1:
                                fr_stall_state === 1 ? vrx_entry5:
                                fr_stall_state === 2 ? vrx_entry10:
                                fr_stall_state === 3 ? vrx_entry13:0): fr_rx_val;

    wire pipe_1_valid = fr_is_vector_op;
    wire[15:0] x2_pipe_1_result;
    wire[15:0] x2_mem_1 = mem_bank_1_data;
    wire[15:0] x2_overflow_1;

    alu pipe_1(clk, fr_pc, fr_ins, pipe_1_ra_val, pipe_1_rx_val,
        x2_mem_1, x2_pipe_1_result, x2_overflow_1);

    wire[15:0] pipe_2_ra_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vra_entry2:
                                fr_stall_state === 1 ? vra_entry6:
                                fr_stall_state === 2 ? vra_entry11:
                                fr_stall_state === 3 ? vra_entry14:0): fr_ra_val;
    wire[15:0] pipe_2_rx_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vrx_entry2:
                                fr_stall_state === 1 ? vrx_entry6:
                                fr_stall_state === 2 ? vrx_entry11:
                                fr_stall_state === 3 ? vrx_entry14:0): fr_rx_val;

    wire pipe_2_valid = fr_is_vector_op;
    wire[15:0] x2_pipe_2_result;
    wire[15:0] x2_mem_2 = mem_bank_2_data;
    wire[15:0] x2_overflow_2;
    alu pipe_2(clk, fr_pc, fr_ins, pipe_2_ra_val, pipe_2_rx_val,
        x2_mem_2, x2_pipe_2_result, x2_overflow_2);

    wire[15:0] pipe_3_ra_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vra_entry3:
                                fr_stall_state === 1 ? vra_entry7:
                                fr_stall_state === 2 ? vra_entry12:
                                fr_stall_state === 3 ? vra_entry15:0): fr_ra_val;
    wire[15:0] pipe_3_rx_val = fr_is_vector_op ? 
                               (fr_stall_state === 0 ? vrx_entry3:
                                fr_stall_state === 1 ? vrx_entry7:
                                fr_stall_state === 2 ? vrx_entry12:
                                fr_stall_state === 3 ? vrx_entry15:0): fr_rx_val;

    wire pipe_3_valid = fr_is_vector_op;
    wire[15:0] x2_pipe_3_result;
    wire[15:0] x2_mem_3 = mem_bank_3_data;
    wire[15:0] x2_overflow_3;
    alu pipe_3(clk, fr_pc, fr_ins, pipe_3_ra_val, pipe_3_rx_val,
        x2_mem_3, x2_pipe_3_result, x2_overflow_3);
    

    //==========================EXECUTE/EXECUTE2==========================

    reg[15:0] x_pc;
    reg[15:0] x_ins;
    reg x_valid = 0;
    reg[3:0] x_ra;
    reg[3:0] x_stall_state;

    reg[15:0] x2_pc;
    reg[15:0] x2_ins;
    reg x2_valid = 0;
    reg[3:0] x2_ra;
    reg[3:0] x2_stall_state;

    reg[3:0] x_vra_size;
    reg[3:0] x_vrx_size;
    reg[3:0] x2_vra_size;
    reg[3:0] x2_vrx_size;

    always @(posedge clk) begin
        x_pc <= fr_pc;
        x2_pc <= x_pc;

        x_ins <= fr_ins;
        x2_ins <= x_ins;

        x_valid <= fr_valid && !flush;
        x2_valid <= x_valid && !flush;
        
        x_stall_state <= fr_stall_state;
        x2_stall_state <= x_stall_state;

        x_vra_size <= fr_vra_size;
        x_vrx_size <= fr_vrx_size;

        x2_vra_size <= x_vra_size;
        x2_vrx_size <= x_vrx_size;
    end

    //==========================COALESCE==========================

    reg c_valid = 0;
    reg [15:0]c_pc;
    reg [15:0]c_ins;
    reg [3:0]c_stall_state;
    wire [3:0]c_opcode = c_ins[15:12];

    wire c_stall = wb_stall;

    reg[15:0] c_scalar_output;
    reg[15:0] c_pipe_0_result;
    reg[15:0] c_pipe_1_result;
    reg[15:0] c_pipe_2_result;
    reg[15:0] c_pipe_3_result;

    wire c_is_vector_op;

    reg[15:0] c_temp_vector_0;
    reg[15:0] c_temp_vector_1;
    reg[15:0] c_temp_vector_2;
    reg[15:0] c_temp_vector_3;
    reg[15:0] c_temp_vector_4;
    reg[15:0] c_temp_vector_5;
    reg[15:0] c_temp_vector_6;
    reg[15:0] c_temp_vector_7;
    reg[15:0] c_temp_vector_8;
    reg[15:0] c_temp_vector_9;
    reg[15:0] c_temp_vector_10;
    reg[15:0] c_temp_vector_11;
    reg[15:0] c_temp_vector_12;
    reg[15:0] c_temp_vector_13;
    reg[15:0] c_temp_vector_14;
    reg[15:0] c_temp_vector_15;
    reg[15:0] c_temp_vector_16;

    reg[3:0] c_vra_size;
    reg[3:0] c_vrx_size;


    always @(posedge clk) begin
        if (!c_stall) begin

            c_temp_vector_0 <= c_stall_state === 0 ? c_pipe_0_result : c_temp_vector_0;
            c_temp_vector_4 <= c_stall_state === 0 ? c_pipe_1_result : c_temp_vector_4;
            c_temp_vector_8 <= c_stall_state === 0 ? c_pipe_2_result : c_temp_vector_8;
            c_temp_vector_12 <= c_stall_state === 0 ? c_pipe_3_result : c_temp_vector_12;

            c_temp_vector_1 <= c_stall_state === 1 ? c_pipe_0_result : c_temp_vector_1;
            c_temp_vector_5 <= c_stall_state === 1 ? c_pipe_1_result : c_temp_vector_5;
            c_temp_vector_9 <= c_stall_state === 1 ? c_pipe_2_result : c_temp_vector_9;
            c_temp_vector_13 <= c_stall_state === 1 ? c_pipe_3_result : c_temp_vector_13;

            c_temp_vector_2 <= c_stall_state === 2 ? c_pipe_0_result : c_temp_vector_2;
            c_temp_vector_6 <= c_stall_state === 2 ? c_pipe_1_result : c_temp_vector_6;
            c_temp_vector_10 <= c_stall_state === 2 ? c_pipe_2_result : c_temp_vector_10;
            c_temp_vector_14 <= c_stall_state === 2 ? c_pipe_3_result : c_temp_vector_14;

            c_temp_vector_3 <= c_stall_state === 3 ? c_pipe_0_result : c_temp_vector_3;
            c_temp_vector_7 <= c_stall_state === 3 ? c_pipe_1_result : c_temp_vector_7;
            c_temp_vector_11 <= c_stall_state === 3 ? c_pipe_2_result : c_temp_vector_11;
            c_temp_vector_15 <= c_stall_state === 3 ? c_pipe_3_result : c_temp_vector_15;

            c_valid <= x2_valid && !flush;
            c_pc <= x2_pc;
            c_ins <= x2_ins;

            c_stall_state <= x2_stall_state;

            c_scalar_output <= x2_pipe_0_result;
            c_pipe_0_result <= x2_pipe_0_result;
            c_pipe_1_result <= x2_pipe_1_result;
            c_pipe_2_result <= x2_pipe_2_result;
            c_pipe_3_result <= x2_pipe_3_result;

            c_vra_size <= x2_vra_size;
            c_vrx_size <= x2_vrx_size;



        end
        
    end

    //==========================WRITEBACK==========================

    reg wb_valid = 0;
    reg [15:0]wb_pc;
    reg [15:0]wb_ins;
    reg[15:0] wb_ra_val;
    reg[15:0] wb_rx_val;
    reg[15:0] wb_scalar_output;

    wire[3:0] wb_opcode = wb_ins[15:12];
    wire[3:0] wb_subcode = wb_ins[7:4];
    
    /*
        DECODING
    */
    wire[3:0] wb_ra = wb_ins[11:8];
    wire[3:0] wb_rb = wb_ins[7:4];
    wire[3:0] wb_rt = wb_ins[3:0];
    wire wb_is_add = wb_opcode == 4'b0000;
    wire wb_is_sub = wb_opcode == 4'b0001;
    wire wb_is_mul = wb_opcode == 4'b0010;
    wire wb_is_div = wb_opcode == 4'b0011;
    wire wb_is_movl = wb_opcode == 4'b0100;
    wire wb_is_movh = wb_opcode == 4'b0101;
    wire wb_is_jmp = wb_opcode == 4'b0110;
    wire wb_is_jz = wb_is_jmp && wb_subcode == 0;
    wire wb_is_jnz = wb_is_jmp && wb_subcode == 1;
    wire wb_is_js = wb_is_jmp && wb_subcode == 2;
    wire wb_is_jns = wb_is_jmp && wb_subcode == 3;
    wire wb_is_scalar_mem = wb_opcode == 4'b0100;
    wire wb_is_mem = (wb_is_scalar_mem) || 
                (wb_opcode == 4'b1100) ||
                (wb_opcode == 4'b1101);
    wire wb_is_ld = wb_is_mem && wb_subcode == 0;
    wire wb_is_st = wb_is_mem && wb_subcode == 1;
    wire wb_is_vadd = wb_opcode == 4'b1000;
    wire wb_is_vsub = wb_opcode == 4'b1001;
    wire wb_is_vmul = wb_opcode == 4'b1010;
    wire wb_is_vdiv = wb_opcode == 4'b1011;
    wire wb_is_vld = wb_opcode == 4'b1110;
    wire wb_is_vst = wb_opcode == 4'b1101;
    wire wb_is_vdot = wb_opcode == 4'b1110;
    wire wb_is_halt = wb_opcode == 4'b1111;
    wire wb_is_vector_op = wb_is_vadd || wb_is_vsub || wb_is_vmul || wb_is_vdiv || wb_is_vld || wb_is_vst || wb_is_vdot;
    wire wb_is_invalid_op = !(wb_is_add | wb_is_sub | wb_is_mul | wb_is_div |
        wb_is_movl | wb_is_movh | wb_is_ld | wb_is_st |
        wb_is_jz | wb_is_jnz | wb_is_js | wb_is_jns |
        wb_is_vadd | wb_is_vsub | wb_is_vmul | wb_is_vdiv |
        wb_is_vld | wb_is_vst | wb_is_vdot);


    /*
        DECISION MAKING
    */
    // assign flush = wb_valid ? wb_take_jump : 0;
    wire [15:0] wb_next_pc = wb_is_jmp ? wb_scalar_output : wb_pc + 2;
    assign flush = wb_valid ? wb_next_pc !== c_pc : 0;
    // wire wb_take_jump =  (wb_is_jz) ? (wb_ra_val === 0 ? 1 :0):
    //                     (wb_is_jnz) ? (wb_ra_val !== 0 ? 1 : 0):
    //                     (wb_is_js) ? (wb_ra_val[15] === 1 ? 1 : 0):
    //                     (wb_is_jns) ? (wb_ra_val[15] === 0? 1 : 0) : 0;

    /*
        WRITING TO REG
    */
    wire wb_writes_reg = (wb_is_add || wb_is_sub || wb_is_mul || wb_is_div || wb_is_ld || wb_is_vdot || wb_is_movl || wb_is_movh);
    
    assign reg_wen = wb_valid && wb_writes_reg && wb_rt != 0;
    assign reg_wdata = wb_scalar_output;
    assign reg_waddr = wb_rt;
    wire wb_is_print = wb_writes_reg && (wb_rt === 0);

    /*
        WRITING TO VREG
    */
    wire wb_writes_vreg = (wb_is_vadd || wb_is_vsub || wb_is_vmul || wb_is_vdiv || wb_is_vld);
    assign vreg_wen = wb_valid && wb_writes_vreg && wb_rt != 0;
    assign vreg_wdata = wb_vec_reg;
    assign vreg_waddr = wb_rt;

    //WE NEED TO FORWARD THESE BADD BOYS
    reg[3:0] wb_vra_size;
    reg[3:0] wb_vrx_size;

    reg[3:0] wb_stall_state = 0;
    wire[2:0] wb_num_stall_cycles = wb_is_vector_op ? wb_vra_size << 2 + wb_vra_size[1:0] : 0;
    wire wb_stall = wb_valid && ((wb_stall_state === 1) || (wb_stall_state !== 0) || (wb_num_stall_cycles !== 0));

    // reg[3:0] wb_stall_cycle <= wb_is_vst ? wb_
    // wire wb_stall = wb_is_vst;
    // wire wb_stuck;
    /*
        MEMORY
    */
    wire wb_mem_bank_wen_0  = (wb_is_vst || (wb_is_st && ((wb_ra_val % 4) === 0)) );
    wire wb_mem_bank_wen_1 = (wb_is_vst || (wb_is_st && ((wb_ra_val % 4) === 1)) );
    wire wb_mem_bank_wen_2 = (wb_is_vst || (wb_is_st && ((wb_ra_val % 4) === 2)) );
    wire wb_mem_bank_wen_3 = (wb_is_vst || (wb_is_st && ((wb_ra_val % 4) === 3)) );

    wire[3:0] first_write = (wb_ra_val % 4);

    //stores mem at addreessees 0, 4, 8, 12  
    wire wb_mem_bank_wdata_04 = wb_stall_state === 0 ? wb_vec_reg[255:240] :
                                wb_stall_state === 1 ?  wb_vec_reg[191:176] : 
                                wb_stall_state === 2 ? wb_vec_reg[127:112] :
                                wb_stall_state === 3 ?  wb_vec_reg[63:48] : 0;
    //1, 5, 9, 13  
    wire wb_mem_bank_wdata_15 = wb_stall_state === 0 ? wb_vec_reg[239:224] :
                                wb_stall_state === 1 ?  wb_vec_reg[175:160] :
                                wb_stall_state === 2 ? wb_vec_reg[111:96] :
                                wb_stall_state === 3 ?  wb_vec_reg[47:32] : 0;
    //2, 6, 10, 14
    wire wb_mem_bank_wdata_26 = wb_stall_state === 0 ? wb_vec_reg[223:208] :
                                wb_stall_state === 1 ?  wb_vec_reg[159:144] :
                                wb_stall_state === 2 ? wb_vec_reg[95:80] :
                                wb_stall_state === 3 ?  wb_vec_reg[31:16] : 0;
    //3, 7, 11, 15
    wire wb_mem_bank_wdata_37 = wb_stall_state === 0 ? wb_vec_reg[207:192] :
                                wb_stall_state === 1 ?  wb_vec_reg[143:128] :
                                wb_stall_state === 2 ? wb_vec_reg[79:64] :
                                wb_stall_state === 3 ?  wb_vec_reg[15:0] : 0;

    //not right
    //wb_ra_val + 4*stall_state
    wire wb_mem_bank_waddr_0 = first_write === 0 ? (wb_ra_val + 4 * wb_stall_state) :
                                first_write === 1 ? (wb_ra_val + 4 * wb_stall_state) + 3 :
                                first_write === 2 ? (wb_ra_val + 4 * wb_stall_state) + 2 :
                                first_write === 3 ? (wb_ra_val + 4 * wb_stall_state) + 1: 0;

    wire wb_mem_bank_waddr_1 = first_write === 0 ? (wb_ra_val + 4 * wb_stall_state) + 1:
                                first_write === 1 ? (wb_ra_val + 4 * wb_stall_state) + 0 :
                                first_write === 2 ? (wb_ra_val + 4 * wb_stall_state) + 3 :
                                first_write === 3 ? (wb_ra_val + 4 * wb_stall_state) + 2: 0;

    wire wb_mem_bank_waddr_2 = first_write === 0 ? (wb_ra_val + 4 * wb_stall_state) + 2:
                                first_write === 1 ? (wb_ra_val + 4 * wb_stall_state) + 1 :
                                first_write === 2 ? (wb_ra_val + 4 * wb_stall_state) + 0 :
                                first_write === 3 ? (wb_ra_val + 4 * wb_stall_state) + 3: 0;

    wire wb_mem_bank_waddr_3 = first_write === 0 ? (wb_ra_val + 4 * wb_stall_state) + 3:
                                first_write === 1 ? (wb_ra_val + 4 * wb_stall_state) + 2 :
                                first_write === 2 ? (wb_ra_val + 4 * wb_stall_state) + 1 :
                                first_write === 3 ? (wb_ra_val + 4 * wb_stall_state) + 0: 0;

    //choose based on first store
    wire wb_mem_bank_wdata_0 = wb_stall_state === 0 ? wb_mem_bank_wdata_04 :
                                wb_stall_state === 1 ?  wb_mem_bank_wdata_37 : 
                                wb_stall_state === 2 ? wb_mem_bank_wdata_26 :
                                wb_stall_state === 3 ?  wb_mem_bank_wdata_15 : 0;

    wire wb_mem_bank_wdata_1 = wb_stall_state === 0 ? wb_mem_bank_wdata_15 :
                                wb_stall_state === 1 ?  wb_mem_bank_wdata_04 : 
                                wb_stall_state === 2 ? wb_mem_bank_wdata_37 :
                                wb_stall_state === 3 ?  wb_mem_bank_wdata_26 : 0;

    wire wb_mem_bank_wdata_2 = wb_stall_state === 0 ? wb_mem_bank_wdata_26 :
                                wb_stall_state === 1 ?  wb_mem_bank_wdata_15 : 
                                wb_stall_state === 2 ? wb_mem_bank_wdata_04 :
                                wb_stall_state === 3 ?  wb_mem_bank_wdata_37 : 0;

    wire wb_mem_bank_wdata_3 = wb_stall_state === 0 ? wb_mem_bank_wdata_37 :
                                wb_stall_state === 1 ?  wb_mem_bank_wdata_26 : 
                                wb_stall_state === 2 ? wb_mem_bank_wdata_15 :
                                wb_stall_state === 3 ?  wb_mem_bank_wdata_04 : 0;

    reg[255:0] wb_vec_reg;
    wire wb_vreg_mem_wen;

    always @(posedge clk) begin

        wb_valid <= c_valid && !flush;
        wb_pc <= c_pc;
        wb_ins <= c_ins;
        wb_scalar_output <= c_scalar_output;

        wb_vra_size <= c_vra_size;
        wb_vrx_size <= c_vrx_size;

        if (!wb_stall) begin
            wb_vec_reg <= {c_temp_vector_0, c_temp_vector_1, c_temp_vector_2, 
                            c_temp_vector_3, c_temp_vector_4, c_temp_vector_5, 
                            c_temp_vector_6, c_temp_vector_7, c_temp_vector_8, 
                            c_temp_vector_9, c_temp_vector_10, c_temp_vector_11, 
                            c_temp_vector_12, c_temp_vector_13, c_temp_vector_14, 
                            c_temp_vector_15};

            wb_scalar_output <= c_scalar_output;
            
            if (wb_valid) begin
                if (wb_is_halt || wb_is_invalid_op) begin
                    halt <= 1;
                    $finish;
                end

                if (wb_is_print) begin
                    $write("%c", wb_scalar_output);
                end
            end



        end
        
    end


endmodule
