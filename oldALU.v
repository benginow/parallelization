`timescale 1ps/1ps

//we need to pass in all of the variables from decode?
//maybe not...
module fetch_to_wb_pipe(input clk,
    input [15:0]fr_pc, input [15:0]fr_ins, 
    input [3:0]fr_opcode, input [3:0]fr_subcode, input fr_valid,
    input fr_stallCycle,
    input [3:0]fr_ra, input [3:0]fr_rb, input [3:0]fr_rt, input [3:0]fr_rx,
    input fr_regData0, input fr_regData1,
    input fr_vregData0, input fr_vregData1,
    input fr_memData,
    //these are wires
    // input [15:0]x2_ra_val, input [15:0]x2_rx_val,
    // output x2_stall, output x2_flush,
    // output x2_read_mem_addr,
    // output x2_mem_WEn,input x2_regData0, input x2_regData1,
    // input x2_vregData0, input x2_vregData1,
    // output x2_stall, output x2_flush,
    // output x2_read_mem_addr,
    // output x2_mem_WEn, 
    // output x2_stallCycle,
    // output x2_ra, output x2_rb, output x2_rt, output x2_rx, 
    output result); //needs output from WB


    //================================EXECUTE 1===========================================
    wire [3:0]x_opcode = x_ins[15:12];
    wire [3:0]x_subcode = x_ins[7:4];

    wire [7:0]x_ival = x_ins[11:4];

    wire x_isAdd = x_opcode == 4'b0000;
    wire x_isSub = x_opcode == 4'b0001;
    wire x_isMul = x_opcode == 4'b0010;
    wire x_isDiv = x_opcode == 4'b0011;

    wire x_isMovl = x_opcode == 4'b0100;
    wire x_isMovh = x_opcode == 4'b0101;
    wire x_isJmp = x_opcode == 4'b0110;
    wire x_isScalarMem = x_opcode == 4'b0100;
    wire x_isMem = (x_isScalarMem) || 
                (x_opcode == 4'b1100) ||
                (x_opcode == 4'b1101);

    wire x_isJz = x_isJmp && x_subcode == 0;
    wire x_isJnz = x_isJmp && x_subcode == 1;
    wire x_isJs = x_isJmp && x_subcode == 2;
    wire x_isJns = x_isJmp && x_subcode == 3;

    wire x_isLd = x_isMem && x_subcode == 0;
    wire x_isSt = x_isMem && x_subcode == 1;

    wire x_isVadd = x_opcode == 4'b1000;
    wire x_isVsub = x_opcode == 4'b1001;
    //just multiply each element
    wire x_isVmul = x_opcode == 4'b1010;
    wire x_isVdiv = x_opcode == 4'b1011;

    wire x_isVld = x_opcode == 4'b1110;
    wire x_isVst = x_opcode == 4'b1101;

    wire x_isVdot = x_opcode == 4'1110;

    wire x_isHalt = x_opcode == 4'1111;

    wire x_is_vector_op = x_isVadd || x_isVsub || x_isVmul || x_isVdiv 
                || x_isVld || x_isVst || x_isVdot;


    wire x_read_mem_addr = x_regData0;

    reg x_valid = 0;
    reg [15:0]x_pc;
    reg [15:0]x_ins;
    reg [3:0]x_opcode;
    reg [3:0]x_subcode;

    reg x_ra;
    reg x_rb;
    reg x_rt;

    reg x_rx;

    reg x_stallCycle;

    wire x_stall;
    wire x_stuck;
    wire x_read_val = x_ra_val;

    //handle arithmetic
    //TODO: handle overflow and modulo later
    wire [15:0]x_add_result = x_ra_val + x_rx_val;
    wire [15:0]x_sub_result = x_ra_val - x_rx_val;
    wire [15:0]x_mul_result = x_ra_val * x_rx_val;
    wire [15:0]x_div_result = x_ra_val / x_rx_val;

    //handle movs with immediate values
    wire [15:0]x_movl_result = {8{x_ival[7]}, x_ival};
    wire [15:0]x_movh_result = {x_ival, x_rx_val};

    //handle jumps
    wire x_do_jmp = (x_is_jz) (x_ra_val == 16'h0) ? :
                    (x_is_jnz) ? (x_ra_val != 16'h0) : 
                    (x_is_js) ? (x_ra_val[15] == 1) :
                    (x_is_jns) ? (x_ra_val[15] == 0) : 0;
    
    

    //here, we want to read from mem
    always @(posedge clk) begin
        x_valid <= d_valid;
        x_pc <= d_pc;
        x_ins <= d_ins;
        x_opcode <= d_opcode;
        x_subcode <= d_subcode;

        x_ra <= d_ra;
        x_rb <= d_ra;
        x_rt <= d_rt;

        x_rx <= d_rx;

        //TODO: logic to set stallCycle
    end



    //================================EXECUTE 2===========================================
    wire [3:0]x2_opcode = x2_ins[15:12];
    wire [3:0]x2_subcode = x2_ins[7:4];

    wire x2_isAdd = x2_opcode == 4'b0000;
    wire x2_isSub = x2_opcode == 4'b0001;
    wire x2_isMul = x2_opcode == 4'b0010;
    wire x2_isDiv = x2_opcode == 4'b0011;

    wire x2_isMovl = x2_opcode == 4'b0100;
    wire x2_isMovh = x2_opcode == 4'b0101;
    wire x2_isJmp = x2_opcode == 4'b0110;
    wire x2_isScalarMem = x2_opcode == 4'b0100;
    wire x2_isMem = (x2_isScalarMem) || 
                (x2_opcode == 4'b1100) ||
                (x2_opcode == 4'b1101);

    wire x2_isJz = x2_isJmp && x2_subcode == 0;
    wire x2_isJnz = x2_isJmp && x2_subcode == 1;
    wire x2_isJs = x2_isJmp && x2_subcode == 2;
    wire x2_isJns = x2_isJmp && x2_subcode == 3;

    wire x2_isLd = x2_isMem && x2_subcode == 0;
    wire x2_isSt = x2_isMem && x2_subcode == 1;

    wire x2_isVadd = x2_opcode == 4'b1000;
    wire x2_isVsub = x2_opcode == 4'b1001;
    //just multiply each element
    wire x2_isVmul = x2_opcode == 4'b1010;
    wire x2_isVdiv = x2_opcode == 4'b1011;

    wire x2_isVld = x2_opcode == 4'b1110;
    wire x2_isVst = x2_opcode == 4'b1101;

    wire x2_isVdot = x2_opcode == 4'1110;

    wire x2_isHalt = x2_opcode == 4'1111;

    wire x2_is_vector_op = x2_isVadd || x2_isVsub || x2_isVmul || x2_isVdiv 
                || x2_isVld || x2_isVst || x2_isVdot;


    wire x2_valid = 0;
    reg [15:0]x2_pc;
    reg [15:0]x2_ins;
    reg [3:0]x2_opcode;
    reg [3:0]x2_subcode;

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
        x2_ra <= x_ra;
        x2_rb <= x_ra;
        x2_rt <= x_rt;

        x2_rx <= x_rx;

        x2_ra_val <= x_ra_val;
        x2_rx_val <= x_rx_val;
    end

    wire[15:0] result = (wb_isAdd || wb_isVadd) ? x2_ra_val + x2_rx_val :
                        (wb_isSub || wb_isVsub) ? x2_rx_val - x2_ra_val :
                        (wb_isDiv || wb_isVdiv) ? 1 :
                        (wb_isMul || wb_isVmul) ? 1 : 0;


endmodule
