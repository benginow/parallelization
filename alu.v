`timescale 1ps/1ps

//we need to pass in all of the variables from decode?
//maybe not...
//read mem in fr
module alu(input clk,  
    input fr_pc, input[15:0]fr_ins,
    input[15:0]fr_operand_1, input[15:0] fr_operand_2,
    input[15:0] x2_mem,
    output[15:0] x2_result, output[15:0] overflow_mod);

    //===================EXECUTE 1=======================
    //waiting for memory fetch
    //do the arithmetic on operands, then percolate

    reg [15:0]x_ins;
    reg [15:0]x_pc;

    wire [3:0]x_opcode = x_ins[15:12];
    wire [3:0]x_subcode = x_ins[7:4];
    

    wire x_isScalarMem = x_opcode == 4'b0100;
    wire x_isMem = (x_isScalarMem) || 
                (x_opcode == 4'b1100) ||
                (x_opcode == 4'b1101);
    wire x_isSt = x_isMem && x_subcode == 1;
    wire x_is_add = x_opcode === 4'b0000;
    wire x_is_sub = x_opcode === 4'b0001;
    //for dot product, we do want to multiply the things!
    //except, in coalesce, we want to 
    wire x_isJmp = x_opcode == 4'b0110;
    wire x_is_mul = x_opcode === 4'b0010 || x_opcode === 4'b1110;
    wire x_is_div = x_opcode === 4'b0011;
    
    wire x_isJz = x_isJmp && x_subcode == 0;
    wire x_isJnz = x_isJmp && x_subcode == 1;
    wire x_isJs = x_isJmp && x_subcode == 2;
    wire x_isJns = x_isJmp && x_subcode == 3;

    /*  x_result is the relevant computed value:
            Arithmetic : outputs the computed value
            Jumps: outputs the next PC
            Load: outputs loaded value
            Store: output 
    */

    wire[15:0] x_result = (x_is_div) ?  x_operand_1 / x_operand_2:
                        (x_is_sub) ? x_operand_1 - x_operand_2 :
                        (x_is_mul) ? x_operand_1 * x_operand_2 : 
                        (x_is_add) ? x_operand_1 + x_operand_2: 
                        (x_isJz) ? (x_operand_1 == 0 ? x_operand_2 : x_pc+2):
                        (x_isJnz) ? (x_operand_1 != 0 ? x_operand_2 : x_pc+2):
                        (x_isJs) ? (x_operand_1[15] ? x_operand_2 : x_pc+2):
                        (x_isJns) ? (!x_operand_1[15] ? x_operand_2 : x_pc+2):
                        (x_isSt) ? x_operand_1:0;

    wire x_take_jump =  (x_isJz) ? (x_operand_1 == 0 ? 1 :0):
                        (x_isJnz) ? (x_operand_1 != 0 ? 1 : 0):
                        (x_isJs) ? (x_operand_1[15] ? 1 : 0):
                        (x_isJns) ? (!x_operand_1[15] ? 1 : 0):0;
    
    always @(posedge clk) begin
        x_ins <= fr_ins;
        x_operand_1 <= fr_operand_1; //QUESTION: should this be percolated?
        x_pc <= fr_pc;
    end

    //===================EXECUTE 2=======================
    //memory fetch received, so we can just output that as needed

    
    reg[3:0] x2_opcode;
    reg[15:0] x2_prev_result;
    reg x2_take_jump;
    wire x2_is_ld = x2_opcode === 4'b0111;

    //if it's a ld, we want to output the mem addr, in case we need
    //to coalesce it
    x2_result = x2_is_ld ? x2_mem : x2_prev_result;

    always @(posedge clk) begin
        x2_prev_result <= x_result;
        x2_take_jump <= x_take_jump;
        x2_ins <= x_ins;
    end


endmodule
