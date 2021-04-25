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
    wire [3:0]regRAddr0 = d_ra;
    wire [15:0]regData0;
    //reads rx
    wire [3:0]regRAddr1 = d_rx;
    wire [15:0]regData1;
    wire regWEn;
    wire [3:0]regWAddr;
    wire [15:0]regWData;
    regs regs(clk,
        regRAddr0, regData0,
        regRAddr1, regData1,
        regWEn, regWAddr, regWData);

    wire [3:0]vregRAddr0 = d_ra;
    wire [255:0]vregData0;
    wire [3:0]vregRAddr1 = d_rx;
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


    wire[15:0] fr_ra_val = regData0;
    wire[15:0] fr_rx_val = regData1;

     //TODO: vregs size functionality
     wire[2:0] fr_vra_size = vregData0_size;
    wire[255:0] fr_vra_val = vregData0;
    wire[2:0] fr_vrx_size = vregData1_size;
    wire[255:0] fr_vrx_val = vregData1;

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

        fr_rx_val <= d_rx_val;
        fr_ra_val <= d_ra_val;
    end

     // we will have four pipelines
     //always valid
     wire[3:0] pipe_0_target_index = (stallCycle-1)*4;
     wire[16:0] pipe_0_target = fr_is_vector_op ? fr_vra_val[pipe_0_target_index*16: (pipe_0_target_index+1)*16-1] : fr_va_val;
     wire[16:0] pipe_0_output;
    exec_to_wb_pipe pipe_0(,,,,);

     //valid when it's a vector op and we want to continue doing the vector op
     //we need the vector length and then 
     wire[3:0] pipe_1_target_index = (stallCycle-1)*4 + 1;
     wire[16:0] pipe_1_target = fr_vra_val[pipe_1_target_index*16: (pipe_1_target_index+1)*16-1];
    wire pipe_1_valid = fr_stall_signal;
    wire[16:0] pipe_1_output;
    exec_to_wb_pipe pipe_1(,,,,);

     wire[3:0] pipe_2_target_index = (stallCycle-1)*4 + 2;  
      wire[16:0] pipe_2_target_ra = fr_vra_val[pipe_2_target_index*16: (pipe_2_target_index+1)*16-1];
     wire pipe_2_valid = fr_stall_signal;
     wire[16:0] pipe_2_output;
    exec_to_wb_pipe pipe_2(,,,,);

     wire[3:0] pipe_3_target_index = (stallCycle-1)*4 + 3;
     wire[16:0] pipe_3_target = fr_vra_val[pipe_3_target_index*16: (pipe_3_target_index+1)*16-1]
     wire pipe_3_valid = r_stall_signal;
     wire[16:0] pipe_3_output;
    exec_to_wb_pipe pipe_3(,,,,);

     //we need to keep updting the vector output
     //wire [255:0]fr_vector_output;

    //================================COALESCE============================================
     reg [255:0] c_new_vector;
     reg [15:0] c_scalar_output;
     wire[3:0] pipe_0_curr_target;
     wire[3:0] pipe_1_curr_target;
     wire[3:0] pipe_2_curr_target;
     wire[3:0] pipe_3_curr_target;

        reg c_valid;
        reg [15:0]c_pc;
        reg [3:0]c_ins;
        reg [3:0]c_opcode;
        reg [3:0]c_subcode;

        reg c_isAdd;
        reg c_isSub;
        reg c_isMul;
        reg c_isDiv;

        reg c_isMovl;
        reg c_isMovh;
        reg c_isJmp;
        reg c_isScalarMem;
        reg c_isMem;

        reg c_isVadd;
        reg c_isVsub;
        reg c_isVmul;
        reg c_isVdiv;

        reg c_isJz;
        reg c_isJnz;
        reg c_isJs;
        reg c_isJns;

        reg c_isLd;
        reg c_isSt;

        reg c_isVld;
        reg c_isVst;

        reg c_isVdot;
        reg c_isHalt;

        reg c_is_vector_op;

        reg c_ra;
        reg c_rb;
        reg c_rt;

        reg c_rx;

        reg c_ra_val;
        reg c_rx_val;

     always @(posedge clk) begin
          //this coalesces the value
          //if write enable, then write it

          c_valid <= x2_valid;
        c_pc <= x2_pc;
        c_ins <= x2_ins;
        c_opcode <= x2_opcode;
        c_subcode <= x2_subcode;

        c_isAdd <= x2_isAdd;
        c_isSub <= x2_isSub;
        c_isMul <= x2_isMul;
        c_isDiv <= x2_isDiv;

        c_isMovl <= x2_isMovl;
        c_isMovh <= x2_isMovh;
        c_isJmp <= x2_isJmp;
        c_isScalarMem <= x2_isScalarMem;
        c_isMem <= x2_isMem;

        c_isVadd <= x2_isVadd;
        c_isVsub <= x2_isVsub;
        c_isVmul <= x2_isVmul;
        c_isVdiv <= x2_isVdiv;

        c_isJz <= x2_isJz;
        c_isJnz <= x2_isJnz;
        c_isJs <= x2_isJs;
        c_isJns <= x2_isJns;

        c_isLd <= x2_isLd;
        c_isSt <= x2_isSt;

        c_isVld <= x2_isVld;
        c_isVst <= x2_isVst;

        c_isVdot <= x2_isVdot;
        c_isHalt <= x2_isHalt;

        c_is_vector_op <= x2_is_vector_op;

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
    wire wb_reg_scalar_wen = (wb_isVadd || wb_isVsub || wb_isVmul || wb_isVdiv || wb_isVld || wb_isVdot);
    wire wb_reg_vector_wen = (wb_isAdd || wb_isSub || wb_isMul || wb_isDiv || wb_isLd);
    wire wb_mem_wen_0  = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 0)) );
    wire wb_mem_wen_1 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 1)) );
     wire wb_mem_wen_2 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 2)) );
     wire wb_mem_wen_3 = (wb_isVst || (wb_isSt && ((wb_ra_val % 4) === 3)) );

     reg wb_pipe_0_output;
     reg wb_pipe_1_output;
     reg wb_pipe_2_output;
     reg wb_pipe_3_output;
     

     wire wb_valid = 0;
    reg [15:0]wb_pc;
    reg [15:0]wb_ins;
    reg [3:0]wb_opcode;
    reg [3:0]wb_subcode;

    reg wb_isAdd;
    reg wb_isSub;
    reg wb_isMul;
    reg wb_isDiv;
    
    reg wb_isMovl;
    reg wb_isMovh;
    reg wb_isJmp;
    reg wb_isScalarMem;
    reg wb_isMem;

    reg wb_isJz;
    reg wb_isJnz;
    reg wb_isJs;
    reg wb_isJns;

    reg wb_isLd;
    reg wb_isSt;

    reg wb_isVadd;
    reg wb_isVsub;
    reg wb_isVmul;
    reg wb_isVdiv;

    reg wb_isVld;
    reg wb_isVst;

    reg wb_isVdot;
    reg wb_isHalt;

    reg wb_is_vector_op;

    reg[3:0] wb_ra;
    reg[3:0] wb_rb;
    reg[3:0] wb_rt;

    reg[3:0] wb_rx;

    reg[15:0] wb_ra_val;
    reg[15:0] wb_rx_val;

    reg wb_stallCycle;
    
    wire wb_stall;
    wire wb_stuck;


    always @(posedge clk) begin

         //we need to write, given the outputs from the pipé
        wb_valid <= c_valid;
        wb_pc <= c_pc;
        wb_ins <= c_ins;
        wb_opcode <= c_opcode;
        wb_subcode <= c_subcode;

        wb_isAdd <= c_isAdd;
        wb_isSub <= c_isSub;
        wb_isMul <= c_isMul;
        wb_isDiv <= c_isDiv;

        wb_isMovl <= c_isMovl;
        wb_isMovh <= c_isMovh;
        wb_isJmp <= c_isJmp;
        wb_isScalarMem <= c_isScalarMem;
        wb_isMem <= c_isMem;

        wb_isVadd <= c_isVadd;
        wb_isVsub <= c_isVsub;
        wb_isVmul <= c_isVmul;
        wb_isVdiv <= c_isVdiv;

        wb_isJz <= c_isJz;
        wb_isJnz <= c_isJnz;
        wb_isJs <= c_isJs;
        wb_isJns <= c_isJns;

        wb_isLd <= c_isLd;
        wb_isSt <= c_isSt;

        wb_isVld <= c_isVld;
        wb_isVst <= c_isVst;

        wb_isVdot <= c_isVdot;
        wb_isHalt <= c_isHalt;

        wb_is_vector_op <= c_is_vector_op;

        wb_ra <= c_ra;
        wb_rb <= c_ra;
        wb_rt <= c_rt;

        wb_rx <= c_rx;

        wb_ra_val <= c_ra_val;
        wb_rx_val <= c_rx_val;


    end
    


endmodule
