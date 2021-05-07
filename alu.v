`timescale 1ps/1ps

//we need to pass in all of the variables from decode?
//maybe not...
//read mem in fr
module alu(input clk, input[15:0]fr_pc, input[15:0]fr_ins,
    input[15:0]fr_operand_1, input[15:0]fr_operand_2,
    input[15:0] x2_mem,
    output[15:0] x2_result, output[15:0] x2_overflow_mod);

    //===================EXECUTE 1=======================
    //waiting for memory fetch
    //do the arithmetic on operands, then percolate

    reg [15:0]x_ins;
    reg [15:0]x_pc;

    wire [3:0]x_opcode = x_ins[15:12];
    wire [3:0]x_subcode = x_ins[7:4];
    wire [7:0]x_ival = x_ins[11:4];
    
    reg [15:0]x_operand_1;
    reg [15:0]x_operand_2;

    wire x_is_scalar_mem = x_opcode == 4'b0111;
    wire x_is_mem = (x_is_scalar_mem) || 
                (x_opcode == 4'b1100) ||
                (x_opcode == 4'b1101);
    wire x_is_st = x_is_mem && x_subcode == 1;
    wire x_is_add = x_opcode == 4'b0000;
    wire x_is_sub = x_opcode == 4'b0001;
    //for dot product, we do want to multiply the things!
    //except, in coalesce, we want to 
    wire x_is_jmp = x_opcode == 4'b0110;
    wire x_is_mul = x_opcode == 4'b0010 || x_opcode == 4'b1110;
    wire x_is_div = x_opcode == 4'b0011;
    
    wire x_is_jz = x_is_jmp && x_subcode == 0;
    wire x_is_jnz = x_is_jmp && x_subcode == 1;
    wire x_is_js = x_is_jmp && x_subcode == 2;
    wire x_is_jns = x_is_jmp && x_subcode == 3;

    wire x_is_movl = x_opcode == 4'b0100;
    wire x_is_movh = x_opcode == 4'b0101;

    wire x_is_vadd = x_opcode == 4'b1000;
    wire x_is_vsub = x_opcode == 4'b1001;
    wire x_is_vmul = x_opcode == 4'b1010;
    wire x_is_vdiv = x_opcode == 4'b1011;

    wire x_is_vld = x_opcode == 4'b1100;
    wire x_is_vst = x_opcode == 4'b1101;

    wire x_is_vdot = x_opcode == 4'b1110; //treated like vmul

    //yo who added this wire it doesn't even connect to anything
    //wire is_St = (x2_opcode === 4'b0111) && (x2_ins[7:4] === 4'b0001);

    /*  x_result is the relevant computed value:
            Arithmetic : outputs the computed value
            Jumps: outputs the next PC
            Load: outputs loaded value
            Store: output 
    */

    wire [15:0] x_movl_result;
    assign x_movl_result[7:0] = x_ival[7:0];
    assign x_movl_result[15:8] = {8{x_ival[7]}}; 

    wire[15:0] x_result = (x_is_div || x_is_vdiv) ?  x_operand_1 / x_operand_2 :
                        (x_is_sub || x_is_vsub) ? x_operand_1 - x_operand_2 :
                        (x_is_mul || x_is_vmul || x_is_vdot) ? x_operand_1 * x_operand_2 : 
                        (x_is_add || x_is_vadd) ? x_operand_1 + x_operand_2 : 
                        (x_is_jz) ? (x_operand_1 == 0 ? x_operand_2 : x_pc+2) :
                        (x_is_jnz) ? (x_operand_1 != 0 ? x_operand_2 : x_pc+2) :
                        (x_is_js) ? (x_operand_1[15] ? x_operand_2 : x_pc+2) :
                        (x_is_jns) ? (!x_operand_1[15] ? x_operand_2 : x_pc+2) :
                        (x_is_st || x_is_vst) ? x_operand_1 : 
                        (x_is_movl) ? x_movl_result :
                        (x_is_movh) ? ((x_operand_2 & 8'hff) | (x_ival << 8)):
                        0;

        // MOVL: x_is_movl? (stall_stage_2[11] ? 16'hff00 | stall_stage_2[11:4] : stall_stage_2[11:4]): 
        //MOVH: x_is_movh? (stall_stage_2_val_1 & 16'h00ff) | (stall_stage_2[11:4] << 8):
    
    always @(posedge clk) begin
        x_pc <= fr_pc;
        x_ins <= fr_ins;
        x_operand_1 <= fr_operand_1;
        x_operand_2 <= fr_operand_2;
    end

    //===================EXECUTE 2=======================
    //memory fetch received, so we can just output that as needed
    
    reg [15:0] x2_pc;
    reg [15:0] x2_ins;
    wire[3:0] x2_opcode = x2_ins[15:12];
    wire[3:0] x2_subcode = x2_ins[7:4];
    reg[15:0] x2_prev_result;
    //reg x2_take_jump;
    
    wire x2_is_ld = x2_opcode == 4'b0111 && x2_subcode == 4'b0000;
    wire x2_is_vld = x2_opcode == 4'b1100;
    
    //if it's a ld, we want to output the mem addr, in case we need
    //to coalesce it
    assign x2_result = (x2_is_ld || x2_is_vld) ? x2_mem : x2_prev_result;

    always @(posedge clk) begin
        x2_pc <= x_pc;
        x2_ins <= x_ins;
        x2_prev_result <= x_result;
    end


endmodule
