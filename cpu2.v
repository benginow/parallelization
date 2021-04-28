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

    //scalar register file - 1 clock latency
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

    //vector register file - 1 clock latency
    wire [3:0]vregRAddr0;
    wire [255:0]vregData0;
    wire [3:0]vregData0Len;
    wire [3:0]vregRAddr1;
    wire [255:0]vregData1;
    wire [3:0]vregData1Len;
    wire vregWEn;
    wire [3:0]vregWLen;
    wire [3:0]vregWAddr;
    wire [255:0]vregWData;
    vregs vregs(clk,
        vregRAddr0, vregData0, vregData0Len,
        vregRAddr1, vregData1, vregData1Len,
        vregWEn, vregWAddr, vregWLen, vregWData);


    //instr mem - 2 clock latency
    wire [15:0]instr_mem_raddr;
    wire [15:0]instr_mem_data;
    assign instr_mem_raddr = f1_pc;
    instr_mem instr_mem(clk,
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
    
    wire flush; //global control signal
    
    //=====================FETCH 1=====================
    reg[15:0]f1_pc = 0;
    reg f1_valid = 1;
    wire f1_stall = 0;
    always @(posedge clk) begin
        //TODO: work on the flush logic!!
        if (!f1_flush) begin
            //if we're flushing, we don't want to keep incrementing
            f1_pc <= f1_pc + 2;
        end
    end 

    //=====================FETCH 2=====================
    wire f2_stall;
    reg[15:0]f2_pc = 16'hffff;
    reg f2_valid = 0;
    always @(posedge clk) begin
        f2_pc <= f1_pc;
        //if f1 is an invalid wire, we want the next to be invalid
        f2_invalid <= f1_flush ? 1 : f1_invalid;
    end 

    //=====================DECODE======================
    reg[15:0]d_pc = 16'hffff;
    reg d_valid = 0;
    wire[15:0]d_ins = instr_mem_data;
    reg [15:0]d_lastIns;
    reg d_stallCycle = 0;
    wire d_stall;

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
    wire d_isMem = (d_isScalarMem) || 
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
    wire d_isVmul = d_opcode == 4'b1010;
    wire d_isVdiv = d_opcode == 4'b1011;

    wire d_isVld = d_opcode == 4'b1110;
    wire d_isVst = d_opcode == 4'b1101;

    wire d_isVdot = d_opcode == 4'b1110;

    wire d_isHalt = d_opcode == 4'b1111;

    wire d_is_vector_op = d_isVadd || d_isVsub || d_isVmul || d_isVdiv 
                || d_isVld || d_isVst || d_isVdot;

    wire d_ra = d_ins[11:8]; //always needed
    wire d_rb = d_ins[7:4];
    wire d_rt = d_ins[3:0];
    //second register whose value is needed may be either rb or rt
    wire d_rx = (d_isAdd || d_isSub || d_isMul || d_isDiv) ||
            (d_isVadd || d_isVsub || d_isVmul || d_isVdiv) ?
            d_rb : d_rt;

    assign regRAddr0 = d_ra;
    assign regRAddr1 = d_rx;
    assign vregRAddr0 = d_ra;
    assign vregRAddr1 = d_rx;
    assign vregWLen = d_rt;

    always @(posedge clk) begin
        d_pc <= f2_pc;
        d_invalid <= f2_invalid;
        d_lastIns <= instr_mem_data;
    end

    //================================FETCH REGS===========================================
    wire [3:0]fr_opcode = fr_ins[15:12];
    wire [3:0]fr_subcode = fr_ins[7:4];

    wire fr_isAdd = fr_opcode == 4'b0000;
    wire fr_isSub = fr_opcode == 4'b0001;
    wire fr_isMul = fr_opcode == 4'b0010;
    wire fr_isDiv = fr_opcode == 4'b0011;

    wire fr_isMovl = fr_opcode == 4'b0100;
    wire fr_isMovh = fr_opcode == 4'b0101;
    wire fr_isJmp = fr_opcode == 4'b0110;
    wire fr_isScalarMem = fr_opcode == 4'b0100;
    wire fr_isMem = (fr_isScalarMem) || 
                (fr_opcode == 4'b1100) ||
                (fr_opcode == 4'b1101);

    wire fr_isJz = fr_isJmp && fr_subcode == 0;
    wire fr_isJnz = fr_isJmp && fr_subcode == 1;
    wire fr_isJs = fr_isJmp && fr_subcode == 2;
    wire fr_isJns = fr_isJmp && fr_subcode == 3;

    wire fr_isLd = fr_isMem && fr_subcode == 0;
    wire fr_isSt = fr_isMem && fr_subcode == 1;
    
    wire fr_isVadd = fr_opcode == 4'b1000;
    wire fr_isVsub = fr_opcode == 4'b1001;
    wire fr_isVmul = fr_opcode == 4'b1010;
    wire fr_isVdiv = fr_opcode == 4'b1011;

    wire fr_isVld = fr_opcode == 4'b1110;
    wire fr_isVst = fr_opcode == 4'b1101;

    wire fr_isVdot = fr_opcode == 4'b1110;

    wire fr_isHalt = fr_opcode == 4'b1111;

    wire fr_is_vector_op = fr_isVadd || fr_isVsub || fr_isVmul || fr_isVdiv 
                || fr_isVld || fr_isVst || fr_isVdot;

    
    //we want to stall by div 4 cycles
    //if its not divisible by 4 -> ?? TODO: fix
    //stalling logic
    reg [3:0]fr_stallState; //0 = not stalling, 1 = final stall cycle, 2 = 2nd final...
    wire[2:0] fr_num_stall_cycles = fr_vra_size << 2 + fr_vra_size[1:0]; //TODO check sizes
    wire fr_stall_signal = (fr_stallState === 1 || fr_stallState !== 0); 
    
    //values percolated from decode
    reg fr_valid = 0;
    reg [15:0]fr_pc;
    reg [15:0]fr_ins;


    wire[15:0] fr_ra_val = regData0;
    wire[15:0] fr_rx_val = regData1;

    //TODO: vregs size functionality
    wire[2:0] fr_vra_size = vregData0Len;
    wire[255:0] fr_vra_val = vregData0;
    wire[2:0] fr_vrx_size = vregData1Len;
    wire[255:0] fr_vrx_val = vregData1;

    always @(posedge clk) begin

        //here, we want to decide, if this is a vector op, how many cycles to stall for
        fr_stall_cycles <= fr_stall_cycles_temp - 1;

        //percolate values
        fr_valid <= d_valid;
        fr_pc <= d_pc;
        fr_ins <= d_ins;

        fr_ra <= d_ra;
        fr_rb <= d_ra;
        fr_rt <= d_rt;

        fr_rx <= d_rx;

        fr_rx_val <= d_rx_val;
        fr_ra_val <= d_ra_val;
    end

    // we will have four pipelines
    //always valid
    wire[3:0] pipe_0_target_index = (fr_stallState - 1)*4;
    wire[15:0] pipe_0_ra_val = fr_is_vector_op ? fr_vra_val[pipe_0_target_index*16: (pipe_0_target_index+1)*16-1] : fr_va_val;
    wire[15:0] pipe_0_rx_val = fr_is_vector_op ? fr_vrx_val[pipe_0_target_index*16: (pipe_0_target_index+1)*16-1] : fr_vx_val;
    wire[15:0] x2_mem_0 = mem_bank_0_data;
    wire[15:0] x2_pipe_0_result;
    wire[15:0] x2_overflow_0;
    alu pipe_0(clk, fr_pc, fr_ins, pipe_0_ra_val, pipe_0_rx_val,
        x2_mem_0, x2_pipe_0_result, x2_overflow_0);

    //valid when it's a vector op and we want to continue doing the vector op
    //we need the vector length and then 
    wire[3:0] pipe_1_target_index = (fr_stallState-1)*4 + 1;
    wire[15:0] pipe_1_target = fr_vra_val[pipe_1_target_index*16: (pipe_1_target_index+1)*16-1];
    wire pipe_1_valid = fr_stall_signal;
    wire[15:0] pipe_1_result;
    wire[15:0] x2_mem_1 = mem_bank_1_data;
    //do some of these outputs need to be no-ops?
    alu pipe_1(clk, fr_pc, fr_ins, pipe_1_ra_val, pipe_1_rx_val,
        x2_mem_1, x2_pipe_1_result, x2_overflow_1);

    wire[3:0] pipe_2_target_index = (fr_stallState-1)*4 + 2;  
    wire[16:0] pipe_2_target_ra = fr_vra_val[pipe_2_target_index*16: (pipe_2_target_index+1)*16-1];
    wire pipe_2_valid = fr_stall_signal;
    wire[15:0] pipe_2_result;
    wire[15:0] x2_mem_2 = mem_bank_2_data;
    alu pipe_2(clk, fr_pc, fr_ins, pipe_2_ra_val, pipe_2_rx_val,
        x2_mem_2, x2_pipe_2_result, x2_overflow_2);

    wire[3:0] pipe_3_target_index = (fr_stallState-1)*4 + 3;
    wire[15:0] pipe_3_target = fr_vra_val[pipe_3_target_index*16: (pipe_3_target_index+1)*16-1];
    wire pipe_3_valid = fr_stall_signal;
    wire[15:0] pipe_3_result;
    wire[15:0] x2_mem_3 = mem_bank_3_data;
    alu pipe_3(clk, fr_pc, fr_ins, pipe_3_ra_val, pipe_3_rx_val,
        x2_mem_3, x2_pipe_3_result, x2_overflow_3);

    //we need to keep updting the vector output

    //================================COALESCE============================================
    reg c_valid;
    reg [15:0]c_pc;
    reg [3:0]c_ins;
    
    wire [3:0]c_opcode = c_ins[15:12];
    wire [3:0]c_subcode = c_ins[7:4];

    wire c_isAdd = c_opcode == 4'b0000;
    wire c_isSub = c_opcode == 4'b0001;
    wire c_isMul = c_opcode == 4'b0010;
    wire c_isDiv = c_opcode == 4'b0011;

    wire c_isMovl = c_opcode == 4'b0100;
    wire c_isMovh = c_opcode == 4'b0101;
    wire c_isJmp = c_opcode == 4'b0110;
    wire c_isScalarMem = c_opcode == 4'b0100;
    wire c_isMem = (c_isScalarMem) || 
                (c_opcode == 4'b1100) ||
                (c_opcode == 4'b1101);

    wire c_isJz = c_isJmp && c_subcode == 0;
    wire c_isJnz = c_isJmp && c_subcode == 1;
    wire c_isJs = c_isJmp && c_subcode == 2;
    wire c_isJns = c_isJmp && c_subcode == 3;

    wire c_isLd = c_isMem && c_subcode == 0;
    wire c_isSt = c_isMem && c_subcode == 1;
    
    wire c_isVadd = c_opcode == 4'b1000;
    wire c_isVsub = c_opcode == 4'b1001;
    wire c_isVmul = c_opcode == 4'b1010;
    wire c_isVdiv = c_opcode == 4'b1011;

    wire c_isVld = c_opcode == 4'b1110;
    wire c_isVst = c_opcode == 4'b1101;

    wire c_isVdot = c_opcode == 4'b1110;

    wire c_isHalt = c_opcode == 4'b1111;

    wire c_is_vector_op = c_isVadd || c_isVsub || c_isVmul || c_isVdiv 
                || c_isVld || c_isVst || c_isVdot;

    reg [255:0] c_new_vector;
    reg [15:0] c_scalar_output;
    wire[3:0] pipe_0_curr_target;
    wire[3:0] pipe_1_curr_target;
    wire[3:0] pipe_2_curr_target;
    wire[3:0] pipe_3_curr_target;

    reg[15:0] c_ra_val;
    reg[15:0] c_rx_val;

    reg[15:0] c_pipe_0_result;
    reg[15:0] c_pipe_1_result;
    reg[15:0] c_pipe_2_result;
    reg[15:0] c_pipe_3_result;

    //handle dot product 
    wire c_ins_changing = x2_pc != c_pc;
    wire [3:0] c_next_terms_left = x2_ra_val < x2_rx_val ? x2_vra_len : x2_vrx_len;
    //TODO the wires above might not exist yet lol
    wire[15:0] c_dot_prod_curr_sum = c_dot_prod_running_sum + c_to_add;
    wire [15:0] c_to_add = c_add_terms_left == 1 ? c_pipe_0_result :
            c_add_terms_left == 2 ? c_pipe_0_result + c_pipe_1_result : 
            c_add_terms_left == 3 ? c_pipe_0_result + c_pipe_1_result + c_pipe_2_result :
            c_add_terms_left >= 4 ? c_pipe_0_result + c_pipe_1_result + c_pipe_3_result + c_pipe_4_result : 0;
    reg[15:0] c_dot_prod_running_sum;
    reg[3:0] c_dot_prod_terms_left;

    always @(posedge clk) begin
        //this coalesces the value
        //if write enable, then write it

        //we want to upadte the curr sum as needed
        //number terms left in dot product is reset every time ins changes
        c_dot_prod_terms_left <= c_ins_changing ? c_dot_prod_terms_left - 4 : c_next_terms_left;
        c_dot_prod_running_sum <= c_ins_changing ? 0 : c_dot_prod_curr_sum; 

        c_valid <= x2_valid;
        c_pc <= x2_pc;
        c_ins <= x2_ins;

        c_ra <= x2_ra;
        c_rb <= x2_ra;
        c_rt <= x2_rt;

        c_rx <= x2_rx;

        c_ra_val <= x2_ra_val;
        c_rx_val <= x2_rx_val;

        c_scalar_output = pipe_0_output;
        c_new_vector[pipe_0_curr_target + 15 : pipe_0_curr_target] <= pipe_0_output;
        c_new_vector[pipe_1_curr_target + 15 : pipe_1_curr_target] <= pipe_1_output;
        c_new_vector[pipe_2_curr_target + 15 : pipe_2_curr_target] <= pipe_2_output;
        c_new_vector[pipe_3_curr_target + 15 : pipe_3_curr_target] <= pipe_3_output;
    end

    //================================WRITEBACK===========================================
    wire [3:0]wb_opcode = wb_ins[15:12];
    wire [3:0]wb_subcode = wb_ins[7:4];

    wire wb_isAdd = wb_opcode == 4'b0000;
    wire wb_isSub = wb_opcode == 4'b0001;
    wire wb_isMul = wb_opcode == 4'b0010;
    wire wb_isDiv = wb_opcode == 4'b0011;

    wire wb_isMovl = wb_opcode == 4'b0100;
    wire wb_isMovh = wb_opcode == 4'b0101;
    wire wb_isJmp = wb_opcode == 4'b0110;
    wire wb_isScalarMem = wb_opcode == 4'b0100;
    wire wb_isMem = (wb_isScalarMem) || 
                (wb_opcode == 4'b1100) ||
                (wb_opcode == 4'b1101);

    wire wb_isJz = wb_isJmp && wb_subcode == 0;
    wire wb_isJnz = wb_isJmp && wb_subcode == 1;
    wire wb_isJs = wb_isJmp && wb_subcode == 2;
    wire wb_isJns = wb_isJmp && wb_subcode == 3;

    wire wb_isLd = wb_isMem && wb_subcode == 0;
    wire wb_isSt = wb_isMem && wb_subcode == 1;
    
    wire wb_isVadd = wb_opcode == 4'b1000;
    wire wb_isVsub = wb_opcode == 4'b1001;
    //just multiply each element
    wire wb_isVmul = wb_opcode == 4'b1010;
    wire wb_isVdiv = wb_opcode == 4'b1011;

    wire wb_isVld = wb_opcode == 4'b1110;
    wire wb_isVst = wb_opcode == 4'b1101;

    wire wb_isVdot = wb_opcode == 4'b1110;

    wire wb_isHalt = wb_opcode == 4'b1111;

    wire wb_is_vector_op = wb_isVadd || wb_isVsub || wb_isVmul || wb_isVdiv 
               || wb_isVld || wb_isVst || wb_isVdot;


    wire wb_reg_scalar_wen = (wb_isAdd || wb_isSub || wb_isMul || wb_isDiv || wb_isLd || wb_isVdot || wb_isMovl || wb_isMovh);
    wire wb_reg_vector_wen = (wb_isVadd || wb_isVsub || wb_isVmul || wb_isVdiv || wb_isVld);

    wire wb_mem_wen_0  = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 0)) );
    wire wb_mem_wen_1 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 1)) );
    wire wb_mem_wen_2 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 2)) );
    wire wb_mem_wen_3 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 3)) );

    reg wb_pipe_0_result;
    // reg wb_pipe_1_output;
    // reg wb_pipe_2_output;
    // reg wb_pipe_3_output;

    wire wb_isInvalid_Op = !(wb_isAdd | wb_isSub | wb_isMul | wb_isDiv |
                            wb_isMovl | wb_isMovh | wb_isLd | wb_isSt |
                            wb_isJz | wb_isJnz | wb_isJs | wb_isJns |
                            wb_isVadd | wb_isVsub | wb_isVmul | wb_isVdiv |
                            wb_isVld | wb_isVst | wb_isVdot);


    wire wb_valid = 0;
    reg [15:0]wb_pc;
    reg [15:0]wb_ins;

    reg[3:0] wb_ra;
    reg[3:0] wb_rb;
    reg[3:0] wb_rt;

    reg[3:0] wb_rx;

    // reg[15:0] wb_ra_val;
    // reg[15:0] wb_rx_val;
    

    reg wb_stallCycle;
    
    //wb will stall for vst
    //do we want to stall or flush for st? probably stall
    //flushing -> just use for jumps
    wire wb_stall = wb_isVst;
    wire wb_stuck;

    wire wb_take_jump =  (x_isJz) ? (x_operand_1 == 0 ? 1 :0):
                        (x_isJnz) ? (x_operand_1 != 0 ? 1 : 0):
                        (x_isJs) ? (x_operand_1[15] ? 1 : 0):
                        (x_isJns) ? (!x_operand_1[15] ? 1 : 0):0;
    
    //TODO: deal with read after writes maybe?
    wire wb_flush = wb_take_jump;

    wire wb_is_print = wb_reg_scalar_wen && (wb_rt == 0);
                        

    always @(posedge clk) begin
        
        if(wb_isInvalid_Op) begin
            halt <= 1;
            $finish;
        end
        // wb_stallCycle <= wb_stall ? 

        //we need to write, given the outputs from the pipé
        wb_valid <= c_valid;
        wb_pc <= c_pc;
        wb_ins <= c_ins;

        wb_ra <= c_ra;
        wb_rb <= c_ra;
        wb_rt <= c_rt;

        wb_rx <= c_rx;

        wb_ra_val <= c_ra_val;
        wb_rx_val <= c_rx_val;

        if (wb_is_print) begin
            print("%c", result);
        end


    end
    


endmodule
