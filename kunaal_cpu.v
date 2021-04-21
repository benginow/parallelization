`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);

    //counter integrated with halt
    reg halt = 0;
    counter ctr(halt,clk);

    //register file - 1 clock latency
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

    //memory module - 2 clock latency reads
    wire [15:0]memRAddr0;
    wire [15:0]memData0;
    wire [15:0]memRAddr1;
    wire [15:0]memData1;
    wire memWEn;
    wire [15:0]memWAddr;
    wire [15:0]memWData;
    mem mem(clk,
         memRAddr0[15:1], memData0,
         memRAddr1[15:1], memData1,
         memWEn, memWAddr[15:1], memWData);

    //control signals and structures
    //control precedence: halt > flush > stall
    wire haltSig;
    wire flush;
    wire stall; //next cycle will be stall cycle
    reg stallCycle = 0; //stall cycle = all stages do same thing as last cycle
    reg uninitR0 = 1; //r0 must be initialized at first    

    /*
    *   FETCH (f) STAGE
    *   Provides address to memory to fetch an instruction from
    */
    reg [15:0]next_pc = 16'h0000; //modified by writeback stage
    assign memRAddr0 = stall ? f_pc : next_pc; //instructions will come from memData0
    reg f_valid = 0;
    reg [15:0]f_pc; //PC currently in MAR
    always @(posedge clk) begin
        if(!f_valid) f_valid <= 1;
        else f_valid <= flush ? 0 : 1;
        f_pc <= stall ? f_pc : next_pc;
    end

    /*
    *   DECODE (d) STAGE
    *   Determine which registers are necessary to read from
    *   Determine the type of the instruction
    */
    reg d_valid = 0;
    reg [15:0]d_pc;
    reg [15:0]d_lastIns; //need to save for stall cycles since memory output is temp. false
    wire [15:0]d_ins = stallCycle ? d_lastIns : memData0;

    //decode instruction type for future stages
    wire [3:0]d_opcode = d_ins[15:12];
    wire [3:0]d_subcode = d_ins[7:4];

    wire d_isSub = d_opcode == 4'b0000;
    wire d_isMovl = d_opcode == 4'b1000;
    wire d_isMovh = d_opcode == 4'b1001;
    wire d_isJmp = d_opcode == 4'b1110;
    wire d_isMem = d_opcode == 4'b1111;

    wire d_isJz = d_isJmp && d_subcode == 0;
    wire d_isJnz = d_isJmp && d_subcode == 1;
    wire d_isJs = d_isJmp && d_subcode == 2;
    wire d_isJns = d_isJmp && d_subcode == 3;

    wire d_isLd = d_isMem && d_subcode == 0;
    wire d_isSt = d_isMem && d_subcode == 1;
    
    //prep reg reading for execute
    wire [3:0]d_ra = d_ins[11:8];
    wire [3:0]d_rb = d_ins[7:4];
    wire [3:0]d_rt = d_ins[3:0];
    wire [3:0]d_rx; //rx: the second register whose val is needed based on instruction
    assign d_rx = (d_isSub) ? d_rb : d_rt; //only sub needs rbVal

    assign regRAddr0 = d_ra;
    assign regRAddr1 = d_rx;

    always @(posedge clk) begin
        d_valid <= flush ? 0 : stall ? d_valid : f_valid;
        d_pc <= stall ? d_pc : f_pc;
        d_lastIns <= memData0;
    end

    /*
    *   EXECUTE (x) STAGE
    *   Calculate new register values if any and whether to jump
    */
    reg x_valid = 0;
    reg [15:0]x_pc;
    reg [15:0]x_ins;

    //handled by previous decode stage
    reg x_isSub;
    reg x_isMovl;
    reg x_isMovh;
    reg x_isJmp;
    reg x_isMem;

    reg x_isJz;
    reg x_isJnz;
    reg x_isJs;
    reg x_isJns;

    reg x_isLd;
    reg x_isSt;

    //necessary for checking for RAW data hazard
    wire [3:0]x_ra = x_ins[11:8];
    wire [3:0]x_rb = x_ins[7:4];
    wire [3:0]x_rt = x_ins[3:0];
    wire [3:0]x_rx = x_isSub ? x_rb : x_rt;

    //take reg values quieried by decode, but guard against RAW data hazard
    wire [15:0]x_raVal = (regWAddr == x_ra && regWEn) ? regWData : regData0;
    wire [15:0]x_rxVal = (regWAddr == x_rx && regWEn) ? regWData : regData1;

    //handle sub
    wire [15:0] x_subResult = x_raVal - x_rxVal; //equivalent to ra-rb

    //handle movl and movh
    wire [7:0]x_ival = x_ins[11:4]; //immediate value
    wire [15:0]x_movlResult;
    assign x_movlResult[7:0] = x_ival;
    assign x_movlResult[15:8] = {8{x_movlResult[7]}}; //sign extension
    wire [15:0]x_movhResult;
    assign x_movhResult[15:8] = x_ival;
    assign x_movhResult[7:0] = x_rxVal[7:0]; //rxVal will be rtVal

    //handle jumps
    wire x_doJmp = x_isJz ? (x_raVal == 16'h0) :
                    x_isJnz ? (x_raVal != 16'h0) : 
                    x_isJs ? (x_raVal[15] == 1) :
                    x_isJns ? (x_raVal[15] != 1) : 0;
    
    //only ld requires reading non-pc memory, uses raVal as address
    //value is ready in 2 cycles, not 1, so x_isLd will trigger stallCycle
    assign memRAddr1 = x_raVal;
    assign stall = x_valid ? x_isLd && !stallCycle : 0; //prevent infinite & invalid stall

    //x_usedVal chooses the useful value sent to writeback
    //either the new value of a register or a jump location
    //Important convention: sends raVal for st instructions, which need 2 register values
    wire [15:0]x_usedVal = x_isSub ? x_subResult :
                            x_isMovl ? x_movlResult :
                            x_isMovh ? x_movhResult :
                            x_isJmp ? x_rxVal : //rxVal will be rtVal, jmp location
                            x_isMem ? x_raVal : 0;

    always @(posedge clk) begin
        x_valid <= flush ? 0 : stall ? x_valid : d_valid;
        x_pc <= stall ? x_pc : d_pc;
        x_ins <= stall ? x_ins : d_ins;

        stallCycle <= stall; //ld in valid x stage sets stall signal

        x_isSub <= stall ? x_isSub : d_isSub;
        x_isMovl <= stall ? x_isMovl : d_isMovl;
        x_isMovh <= stall ? x_isMovh : d_isMovh;
        x_isJmp <= stall ? x_isJmp : d_isJmp;
        x_isMem <= stall ? x_isMem : d_isMem;

        x_isJz <= stall ? x_isJz : d_isJz;
        x_isJnz <= stall ? x_isJnz : d_isJnz;
        x_isJs <= stall ? x_isJs : d_isJs;
        x_isJns <= stall ? x_isJns : d_isJns;

        x_isLd <= stall ? x_isLd : d_isLd;
        x_isSt <= stall ? x_isSt : d_isSt;
    end

    /*
    *   WRITEBACK (w) STAGE
    *   Halts if ins was invalid and writes to registers and memory
    *   Connects execute results back to next_pc
    */
    reg w_valid = 0;
    reg [15:0]w_pc;
    reg [15:0]w_ins;
    reg [15:0]w_usedVal; //used by all instructions
    reg [15:0]w_rtValForSt; //needed exclusively by st which needs 2 register values
    reg w_doJmp;

    //handled by previous decode stage
    reg w_isSub;
    reg w_isMovl;
    reg w_isMovh;
    reg w_isJmp;
    reg w_isMem;

    reg w_isJz;
    reg w_isJnz;
    reg w_isJs;
    reg w_isJns;

    reg w_isSt;
    reg w_isLd;

    //determine instruction validity
    wire w_validOpcode = (w_isSub || w_isMovl || w_isMovh || w_isJmp || w_isMem);
    wire w_validSubcode = !(w_isJmp || w_isMem) ? 1 :
                    w_isJmp ? (w_isJz || w_isJnz || w_isJs || w_isJns) :
                    w_isMem ? (w_isLd || w_isSt) : 0;
    wire w_validIns = w_validOpcode && w_validSubcode;

    wire [3:0]w_rt = w_ins[3:0];

    //handle control signals
    assign haltSig = !w_validIns; //halt when invalid instruction reaches end of pipeline
    //must flush if instruction behind in the pipeline is modified by store or jumped over
    wire w_insMod = w_isSt ? (w_usedVal == x_pc || w_usedVal == d_pc || w_usedVal == f_pc) : 0;
    assign flush = w_valid && (w_doJmp || w_insMod);
    
    //handle writing to registers
    assign regWAddr = uninitR0 ? 0 : w_rt;
    wire [15:0]ldResult = memData1; //ready after one stall cycle
    assign regWData = uninitR0 ? 0 : w_isLd ? ldResult : w_usedVal;
    wire shouldWriteReg = w_isSub || w_isMovl || w_isMovh || w_isLd;
    assign regWEn = uninitR0 ? 1 : (w_valid && w_validIns && shouldWriteReg && w_rt != 0);

    //handle writing to memory
    assign memWAddr = w_usedVal; //will be equal to raVal
    assign memWData = w_rtValForSt;
    assign memWEn = w_valid && w_isSt;

    always @(posedge clk) begin
        //halt, modify next_pc and flush pipeline if necessary
        //ONLY occurs if this stage is in a valid state
        if(w_valid) begin
            if(haltSig) halt <= 1;
            //update next_pc
            if(w_doJmp || w_insMod) next_pc <= w_usedVal;
            else next_pc <= stall ? next_pc : next_pc + 16'h2;
            //output for writes to r0, prevents double output on stall cycles
            if(!haltSig && !stallCycle && w_rt == 0 && shouldWriteReg) begin
                $write("%c", w_isLd ? ldResult : w_usedVal);
            end
        end
        else next_pc <= stall ? next_pc : next_pc + 16'h2;

        //stop special writing to r0 after first clock
        uninitR0 <= 0;

        //prep for next writeback stage
        w_valid <= flush ? 0 : stall ? w_valid : x_valid;
        w_pc <= stall ? w_pc : x_pc;
        w_ins <= stall ? w_ins : x_ins;
        w_usedVal <= stall ? w_usedVal : x_usedVal;
        w_rtValForSt <= stall ? w_rtValForSt : x_rxVal; //x_rxVal = rtVal for st instruction
        w_doJmp <= stall ? w_doJmp : x_doJmp;

        w_isSub <= stall ? w_isSub : x_isSub;
        w_isMovl <= stall ? w_isMovl : x_isMovl;
        w_isMovh <= stall ? w_isMovh : x_isMovh;
        w_isJmp <= stall ? w_isJmp : x_isJmp;
        w_isMem <= stall ? w_isMem : x_isMem;

        w_isLd <= stall ? w_isLd : x_isLd;
        w_isSt <= stall ? w_isSt : x_isSt;

        w_isJz <= stall ? w_isJz : x_isJz;
        w_isJnz <= stall ? w_isJnz : x_isJnz;
        w_isJs <= stall ? w_isJs : x_isJs;
        w_isJns <= stall ? w_isJns : x_isJns;
    end


endmodule
