`timescale 1ps/1ps

//we need to pass in all of the variables from decode?
//maybe not...
//read mem in fr
module fetch_to_wb_pipe(input clk,
    input[15:0]fr_ins,
    input[15:0]fr_operand_1, input[15:0] fr_operand_2,
    input[15:0] x2_mem,
    output[15:0] x2_result, output[15:0] overflow_mod);

    // input [15:0]d_pc, input [15:0]d_ins, 
    // input [3:0]d_opcode, input [3:0]d_subcode, input d_valid,
    // input d_stallCycle,
    // input [3:0]d_ra, input [3:0]d_rb, input [3:0]d_rt, input [3:0]d_rx,
    // input d_regData0, input d_regData1,
    // input d_vregData0, input d_vregData1,
    // //these are wires
    // input [15:0]x2_ra_val, input [15:0]x2_rx_val,
    // output x2_stall, output x2_flush,
    // output x2_read_mem_addr,
    // output x2_mem_WEn,input x2_regData0, input x2_regData1,
    // input x2_vregData0, input x2_vregData1,
    // output x2_stall, output x2_flush,
    // output x2_read_mem_addr,
    // output x2_mem_WEn, 
    // output x2_stallCycle,
    //output x2_ra, output x2_rb, output x2_rt, output x2_rx, output result); //needs output from WB

    //===================EXECUTE 1=======================
    //waiting for memory fetch
    //do the arithmetic on operands, then percolate

    reg [15:0]x_ins;

    wire [3:0]x_opcode = x_ins[15:12];
    wire [3:0]x_subcode = x_ins[7:4];
    

    wire x_is_add = x_opcode === 4'b0000;
    wire x_is_sub = x_opcode === 4'b0001;
    //for dot product, we do want to multiply the things!
    //except, in coalesce, we want to 
    wire x_is_mul = x_opcode === 4'b0010 || x_opcode === 4'b1110;
    wire x_is_div = x_opcode === 4'b0011;

    wire[15:0] x_result = (x_is_div) ?  x2_ra_val / x2_rx_val:
                        (x_is_sub) ? x2_rx_val - x2_ra_val :
                        (x_is_mul) ? x2_ra_val * x2_rx_val : x2_ra_val + x2_rx_val;
    

    always @(posedge clk) begin
        x_ins <= fr_ins;
        x_operand_1 <= fr_operand_1;
    end

    //===================EXECUTE 2=======================
    //memory fetch received, so we can just output that as needed

    
    reg x2_opcode;
    reg x2_prev_result;
    wire x2_is_ld = x2_opcode === 4'b0111;

    //if it's a ld, we want to output the mem addr, in case we need
    //to coalesce it
    reg[15:0] x2_result = x2_is_ld ? x2_mem : x2_prev_result;

    
    always @(posedge clk) begin
        x2_ins <= x_ins;
    end


endmodule
