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
    input d_ra, input d_rb, input d_rt, input d_rx,
    input x_regData0, input x_regData1,
    input x_vregData0, input x_vregData1,
    output x_stall, output flush,
    output x_read_mem_addr,
    output x_mem_WEn); //needs output from WB

    wire x_read_mem_addr = x_regData0;

    wire x_valid = 0;
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

        //not sure if this logic is 100% correct, just writing things to write things for now
        x_stallCycle <= d_stallCycle;
    end

    //fetch 2, percolate all down
    always @(posedge clk) begin
        
    end





endmodule
