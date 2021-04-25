`timescale 1ps/1ps

//we need to pass in all of the variables from decode?
//maybe not...
module fetch_to_wb_pipe(input clk,
    input [15:0]d_pc, input [15:0]d_ins, 
    input [3:0]d_opcode, input [3:0]d_subcode, input d_valid,
    input d_isMovh, input d_isMovl, input d_isJmp, input d_isMem,
    input d_isAdd, input d_isSub, input d_isMul, input d_isdiv,
    input d_isVdd, input d_Vsub, input d_Vmul, input d_Vdiv,
    input d_isLd, input d_isSt, input d_isVld, input d_isVst,
    input d_isJz, input d_isJnz, input d_isJs, input d_isJns,
    input d_isVdot, input d_is_vector_op, input d_isHalt,
    input d_isScalarMem,
    input d_isDiv, input d_isVadd, input d_isVsub, input d_isVmul, input d_isVdiv,
    input d_stallCycle,
    input [3:0]d_ra, input [3:0]d_rb, input [3:0]d_rt, input [3:0]d_rx,
    input d_regData0, input d_regData1,
    input d_vregData0, input d_vregData1,
    //these are wires
    input [15:0]x_ra_val, input [15:0]x_rx_val,
    output x_stall, output flush,
    output x_read_mem_addr,
    output x_mem_WEn); //needs output from WB


    //================================EXECUTE 1===========================================

    wire x_read_mem_addr = x_regData0;

    reg x_valid = 0;
    reg [15:0]x_pc;
    reg [15:0]x_ins;
    reg [3:0]x_opcode;
    reg [3:0]x_subcode;

    reg x_isAdd;
    reg x_isSub;
    reg x_isMul;
    reg x_isDiv;
    
    reg x_isMovl;
    reg x_isMovh;
    reg x_isJmp;
    reg x_isScalarMem;
    reg x_isMem;

    reg x_isJz;
    reg x_isJnz;
    reg x_isJs;
    reg x_isJns;

    reg x_isLd;
    reg x_isSt;

    reg x_isVadd;
    reg x_isVsub;
    reg x_isVmul;
    reg x_isVdiv;

    reg x_isVld;
    reg x_isVst;

    reg x_isVdot;
    reg x_isHalt;

    reg x_is_vector_op;

    reg x_ra;
    reg x_rb;
    reg x_rt;

    reg x_rx;

    reg x_stallCycle;
    
    wire x_stall;
    wire x_stuck;

    //here, we want to read from mem
    always @(posedge clk) begin
        x_valid <= d_valid;
        x_pc <= d_pc;
        x_ins <= d_ins;
        x_opcode <= d_opcode;
        x_subcode <= d_subcode;

        x_isAdd <= d_isAdd;
        x_isSub <= d_isSub;
        x_isMul <= d_isMul;
        x_isDiv <= d_isDiv;

        x_isMovl <= d_isMovl;
        x_isMovh <= d_isMovh;
        x_isJmp <= d_isJmp;
        x_isScalarMem <= d_isScalarMem;
        x_isMem <= d_isMem;

        x_isVadd <= d_isVadd;
        x_isVsub <= d_isVsub;
        x_isVmul <= d_isVmul;
        x_isVdiv <= d_isVdiv;

        x_isJz <= d_isJz;
        x_isJnz <= d_isJnz;
        x_isJs <= d_isJs;
        x_isJns <= d_isJns;

        x_isLd <= d_isLd;
        x_isSt <= d_isSt;

        x_isVld <= d_isVld;
        x_isVst <= d_isVst;

        x_isVdot <= d_isVdot;
        x_isHalt <= d_isHalt;

        x_is_vector_op <= d_is_vector_op;

        x_ra <= d_ra;
        x_rb <= d_ra;
        x_rt <= d_rt;

        x_rx <= d_rx;

        //TODO: logic to set stallCycle
    end



    //================================EXECUTE 2===========================================


    wire x2_valid = 0;
    reg [15:0]x2_pc;
    reg [15:0]x2_ins;
    reg [3:0]x2_opcode;
    reg [3:0]x2_subcode;

    reg x2_isAdd;
    reg x2_isSub;
    reg x2_isMul;
    reg x2_isDiv;
    
    reg x2_isMovl;
    reg x2_isMovh;
    reg x2_isJmp;
    reg x2_isScalarMem;
    reg x2_isMem;

    reg x2_isJz;
    reg x2_isJnz;
    reg x2_isJs;
    reg x2_isJns;

    reg x2_isLd;
    reg x2_isSt;

    reg x2_isVadd;
    reg x2_isVsub;
    reg x2_isVmul;
    reg x2_isVdiv;

    reg x2_isVld;
    reg x2_isVst;

    reg x2_isVdot;
    reg x2_isHalt;

    reg x2_is_vector_op;

    reg x2_ra;
    reg x2_rb;
    reg x2_rt;

    reg x2_rx;

    reg[15:0] x2_ra_val;
    reg[15:0] x2_rx_val;

    reg x2_stallCycle;
    
    wire x2_stall;
    wire x2_stuck;
    //fetch 2, percolate all down
    always @(posedge clk) begin
        x2_valid <= x_valid;
        x2_pc <= x_pc;
        x2_ins <= x_ins;
        x2_opcode <= x_opcode;
        x2_subcode <= x_subcode;

        x2_isAdd <= x_isAdd;
        x2_isSub <= x_isSub;
        x2_isMul <= x_isMul;
        x2_isDiv <= x_isDiv;

        x2_isMovl <= x_isMovl;
        x2_isMovh <= x_isMovh;
        x2_isJmp <= x_isJmp;
        x2_isScalarMem <= x_isScalarMem;
        x2_isMem <= x_isMem;

        x2_isVadd <= x_isVadd;
        x2_isVsub <= x_isVsub;
        x2_isVmul <= x_isVmul;
        x2_isVdiv <= x_isVdiv;

        x2_isJz <= x_isJz;
        x2_isJnz <= x_isJnz;
        x2_isJs <= x_isJs;
        x2_isJns <= x_isJns;

        x2_isLd <= x_isLd;
        x2_isSt <= x_isSt;

        x2_isVld <= x_isVld;
        x2_isVst <= x_isVst;

        x2_isVdot <= x_isVdot;
        x2_isHalt <= x_isHalt;

        x2_is_vector_op <= x_is_vector_op;

        x2_ra <= x_ra;
        x2_rb <= x_ra;
        x2_rt <= x_rt;

        x2_rx <= x_rx;

        x2_ra_val <= x_ra_val;
        x2_rx_val <= x_rx_val;
    end

    

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

    wire[15:0] result = (wb_isAdd || wb_isVadd) ? wb_ra_val + wb_rx_val :
                        (wb_isSub || wb_isVsub) ? wb_rx_val - wb_ra_val :
                        (wb_isDiv || wb_isVdiv) ? 1 :
                        (wb_isMul || wb_isVmul) ? 1 : 1;


    always @(posedge clk) begin


        //need to set load and store data as well as wen

        //need to do addn

        wb_valid <= x2_valid;
        wb_pc <= x2_pc;
        wb_ins <= x2_ins;
        wb_opcode <= x2_opcode;
        wb_subcode <= x2_subcode;

        wb_isAdd <= x2_isAdd;
        wb_isSub <= x2_isSub;
        wb_isMul <= x2_isMul;
        wb_isDiv <= x2_isDiv;

        wb_isMovl <= x2_isMovl;
        wb_isMovh <= x2_isMovh;
        wb_isJmp <= x2_isJmp;
        wb_isScalarMem <= x2_isScalarMem;
        wb_isMem <= x2_isMem;

        wb_isVadd <= x2_isVadd;
        wb_isVsub <= x2_isVsub;
        wb_isVmul <= x2_isVmul;
        wb_isVdiv <= x2_isVdiv;

        wb_isJz <= x2_isJz;
        wb_isJnz <= x2_isJnz;
        wb_isJs <= x2_isJs;
        wb_isJns <= x2_isJns;

        wb_isLd <= x2_isLd;
        wb_isSt <= x2_isSt;

        wb_isVld <= x2_isVld;
        wb_isVst <= x2_isVst;

        wb_isVdot <= x2_isVdot;
        wb_isHalt <= x2_isHalt;

        wb_is_vector_op <= x2_is_vector_op;

        wb_ra <= x2_ra;
        wb_rb <= x2_ra;
        wb_rt <= x2_rt;

        wb_rx <= x2_rx;

        wb_ra_val <= x2_ra_val;
        wb_rx_val <= x2_rx_val;
    end



endmodule
