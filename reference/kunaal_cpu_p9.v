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
    reg [15:0]memData1Cache; //used for misaligned memory operations
    always @(posedge clk) begin
        memData1Cache <= memData1;
    end

    //target predictor
    wire [15:0]predictorLastPC;
    wire [15:0]predictedNextPC;
    wire predictorWEn;
    wire [15:0]trueTag;
    wire [15:0]trueData;
    predictor predictor(clk,
        predictorLastPC, predictedNextPC,
        predictorWEn, trueTag, trueData);

    //control signals and structures
    //control precedence: halt > flush > stall
    wire haltSig;
    wire flush;
    reg uninit = 1; //initialize flag for fetch & setting r0
    always @(posedge clk) begin
        if(uninit) uninit <= 0; //initialization done after first clock
    end

    /*
    *   FETCH (f) STAGE
    *   Provides PC to memory to fetch an instruction from
    *   This stage is always valid
    */
    reg f_valid = 0;
    wire f_stall = d_valid && d_stall;
    //instructions will come from memData0
    assign memRAddr0 = uninit ? 0 : flush ? w_nextPC : f_stall ? f_pc : predictedNextPC;
    reg [15:0]f_pc = 0; //PC currently in MAR
    assign predictorLastPC = f_pc;
    always @(posedge clk) begin
        f_valid <= 1;
        f_pc <= memRAddr0;
    end

    /*
    *   DECODE (d) STAGE
    *   Determine which registers are necessary to read from
    *   Determine the type of the instruction
    */
    reg d_valid = 0;
    wire d_stall = x_valid && x_stall;
    reg [15:0]d_pc;
    reg [15:0]d_lastIns; //need to save for cycles after stall since memory output is false
    reg d_stallCycle = 0; //true if received stall signal in last cycle
    wire [15:0]d_ins = d_stallCycle ? d_lastIns : memData0;

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

    //ensure old registers are still pushed for reading if d will stall
    assign regRAddr0 = d_stall ? x_ra : d_ra;
    assign regRAddr1 = d_stall? x_rx : d_rx;

    always @(posedge clk) begin
        d_valid <= flush ? 0 : d_stall ? d_valid : f_valid;
        d_pc <= d_stall ? d_pc : f_pc;
        d_lastIns <= d_stallCycle ? d_lastIns : memData0;
        d_stallCycle <= d_stall;
    end

    /*
    *   EXECUTE (x) STAGE
    *   Calculate new register values if any and whether to jump
    */
    reg x_valid = 0;
    wire x_stuck = (x_isLd || (x_isSt && x_misaligned)) && x_stallCycle != 1;
    reg [1:0]x_stallCycle = 0; //0 = not stall cycle, 1 = final stall cycle, 2 = 2nd last
    wire x_stall = (w_valid && w_stall) || (x_valid && x_stuck);
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
    
    //reading non-pc memory uses raVal for addressing
    //aligned ld requires 1 word read and aligned st requires none
    //misaligned ld & st require the same 2 word reads
    wire x_misaligned = x_raVal[0];
    assign memRAddr1 = x_stallCycle == 2 ? x_raVal + 1 : x_raVal;

    //x_usedVal chooses the useful value sent to writeback
    //either the new value of a register or a jump location
    //Important convention: sends raVal for st instructions, which need 2 register values
    wire [15:0]x_usedVal = x_isSub ? x_subResult :
                            x_isMovl ? x_movlResult :
                            x_isMovh ? x_movhResult :
                            x_isJmp ? x_rxVal : //rxVal will be rtVal, jmp location
                            x_isMem ? x_raVal : 0;

    always @(posedge clk) begin
        x_valid <= flush ? 0 : x_stall ? x_valid : d_valid;
        x_pc <= x_stall ? x_pc : d_pc;
        x_ins <= x_stall ? x_ins : d_ins;

        //x_stallCycle simultaneously assigns the number of stall cycles & whether in one
        if(x_stallCycle == 0 && x_stall) x_stallCycle <= x_misaligned ? 2 : 1;
        else if (x_stallCycle != 0) x_stallCycle <= x_stallCycle - 1;

        x_isSub <= x_stall ? x_isSub : d_isSub;
        x_isMovl <= x_stall ? x_isMovl : d_isMovl;
        x_isMovh <= x_stall ? x_isMovh : d_isMovh;
        x_isJmp <= x_stall ? x_isJmp : d_isJmp;
        x_isMem <= x_stall ? x_isMem : d_isMem;

        x_isJz <= x_stall ? x_isJz : d_isJz;
        x_isJnz <= x_stall ? x_isJnz : d_isJnz;
        x_isJs <= x_stall ? x_isJs : d_isJs;
        x_isJns <= x_stall ? x_isJns : d_isJns;

        x_isLd <= x_stall ? x_isLd : d_isLd;
        x_isSt <= x_stall ? x_isSt : d_isSt;
    end

    /*
    *   WRITEBACK (w) STAGE
    *   Halts if ins was invalid and writes to registers and memory
    *   Connects execute results back to next_pc
    */
    reg w_valid = 0;
    wire w_stall = w_valid && w_isSt && w_misaligned && !w_stallCycle;
    reg w_stallCycle = 0;
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

    //handle pipeline control signals & communicate w/ fetch
    assign haltSig = !w_validIns; //halt when invalid instruction reaches end of pipeline
    wire [15:0]w_nextPC = w_doJmp ? w_usedVal : w_pc + 16'h2;
    //must flush if instruction behind in the pipeline is modified by store or jumped over
    //instruction modification can happen either via aligned (a) or misaligned (m) st
    wire w_aInsMod = w_isSt ? (w_usedVal == x_pc || w_usedVal == d_pc || w_usedVal == f_pc) : 0;
    wire w_mInsMod = (w_isSt && w_misaligned) ? 
                (w_usedVal-1 == x_pc || w_usedVal+1 == x_pc) ||
                (w_usedVal-1 == d_pc || w_usedVal+1 == d_pc) ||
                (w_usedVal-1 == f_pc || w_usedVal+1 == f_pc) : 0;
    assign flush = w_valid && (w_nextPC != x_pc || w_aInsMod || w_mInsMod && w_stallCycle);
    
    wire w_misaligned = w_isMem && w_usedVal[0]; //usedVal is raVal for mem ops
    //handle writing to registers
    assign regWAddr = uninit ? 0 : w_rt;
    //misalignment determines whether ldResult is contiguous or not
    wire [15:0]ldResult = w_misaligned ? {memData1Cache[7:0], memData1[15:8]} : memData1;
    assign regWData = uninit ? 0 : w_isLd ? ldResult : w_usedVal;
    wire shouldWriteReg = w_isSub || w_isMovl || w_isMovh || w_isLd;
    assign regWEn = uninit ? 1 : (w_valid && w_validIns && shouldWriteReg && w_rt != 0);

    //handle writing to memory
    //for misaligned writes, stallCycle writes lower order bits
    assign memWAddr = w_stallCycle ? w_usedVal + 1 : w_usedVal; //usedVal = raVal
    wire [15:0]misalignedStData = w_stallCycle ? {w_rtValForSt[7:0], memData1Cache[7:0]} :
                                            {memData1Cache[15:8], w_rtValForSt[15:8]};
    assign memWData = w_misaligned ? misalignedStData : w_rtValForSt;
    assign memWEn = w_valid && w_isSt; 

    //handle updating predictor
    assign predictorWEn = w_valid && w_isJmp;
    assign trueTag = w_pc;
    assign trueData = w_nextPC;

    always @(posedge clk) begin
        //halt if necessary, handle write to r0
        //ONLY occurs if this stage is in a valid state
        if(w_valid) begin
            if(haltSig) halt <= 1;
            //output for writes to r0, prevents double output on stall cycles
            if(!haltSig && w_rt == 0 && shouldWriteReg) begin
                $write("%c", w_isLd ? ldResult : w_usedVal);
            end
        end

        //prep for next writeback stage
        w_valid <= flush ? 0 : w_stall ? w_valid : (x_valid && !x_stuck);
        w_stallCycle <= w_stall;
        w_pc <= w_stall ? w_pc : x_pc;
        w_ins <= w_stall ? w_ins : x_ins;
        w_usedVal <= w_stall ? w_usedVal : x_usedVal;
        w_rtValForSt <= w_stall ? w_rtValForSt : x_rxVal; //x_rxVal = rtVal for st instruction
        w_doJmp <= w_stall ? w_doJmp : x_doJmp;

        w_isSub <= w_stall ? w_isSub : x_isSub;
        w_isMovl <= w_stall ? w_isMovl : x_isMovl;
        w_isMovh <= w_stall ? w_isMovh : x_isMovh;
        w_isJmp <= w_stall ? w_isJmp : x_isJmp;
        w_isMem <= w_stall ? w_isMem : x_isMem;

        w_isLd <= w_stall ? w_isLd : x_isLd;
        w_isSt <= w_stall ? w_isSt : x_isSt;

        w_isJz <= w_stall ? w_isJz : x_isJz;
        w_isJnz <= w_stall ? w_isJnz : x_isJnz;
        w_isJs <= w_stall ? w_isJs : x_isJs;
        w_isJns <= w_stall ? w_isJns : x_isJns;
    end


endmodule
