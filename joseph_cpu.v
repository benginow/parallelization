`timescale 1ps/1ps

module main();

   

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);

    reg halt = 0;

    counter ctr(halt,clk);


    //======================MEMORY=====================

    // PC
    reg [15:0]pc = 16'h0000;

    // read from memory for instruction
    wire [15:0] ins_F;

    // Second read port
    wire [15:1] memRead;
    wire [15:0] readOut;

    wire writeMem;
    wire [15:1] writeAddr;
    wire [15:0] writeData;


    // memory
    mem mem(clk,
         pc[15:1], ins_F,
         memRead, readOut,
         writeMem, writeAddr, writeData);

    //=====================REGISTERS======================

    //Wire to read from registers
    wire [3:0] reg1Adr;
    wire [15:0] reg1;

    wire [3:0] reg2Adr;
    wire [15:0] reg2;

    wire writeRegs;
    wire [3:0] regAddr;
    wire [15:0] regData;


    regs regs(clk,
        reg1Adr, reg1,
        reg2Adr, reg2,
        writeRegs, regAddr, regData);

    //We need to wait 2 cycles after the PC is set before fetch since
    //the value wont be valid till

    //Order:
    //Wait, Wait, Fetch, Decode, Read regs, Read mem, read mem 2, execute, writeback


    reg valid_wait1 = 1;

    //====================Wait 1====================
    reg valid_wait2 = 0;
    reg [15:0] pc_Wait;

    always @(posedge clk) begin
        valid_wait2 <= valid_wait1 && !flushAndRestartPipe;

        if (valid_wait1) begin
            pc_Wait <= pc;
        end
        
    end

    //====================Wait 2====================

    reg valid_F = 0;
    reg [15:0] pc_F;

    always @(posedge clk) begin
        valid_F <= valid_wait2 && !flushAndRestartPipe;
        if (valid_wait2) begin
            pc_F <= pc_Wait;
        end
    end

    //=======================FETCH========================

    reg valid_D = 0;

    reg [15:0] ins_D;
    reg [15:0] pc_D;


    //Want to set the Decode vars during fetch so they are set before decode is called
    always @(posedge clk) begin 
        valid_D <= valid_F && !flushAndRestartPipe;
        if (valid_F) begin
            ins_D <= ins_F;
            pc_D <= pc_F;
        end
    end

    //======================DECODE========================

    reg valid_R = 0;

    wire[3:0] opCode_D = ins_D[15:12];
    wire[3:0] xop_D = ins_D[7:4];

    //See which command we are
    wire isSub_D = (opCode_D == 0);
    wire isMovl_D = (opCode_D == 8);
    wire isMovh_D = (opCode_D == 9);
    wire isJz_D = (opCode_D == 14) & (xop_D == 0);
    wire isJnz_D = (opCode_D == 14) & (xop_D == 1);
    wire isJs_D = (opCode_D == 14) & (xop_D == 2);
    wire isJns_D = (opCode_D == 14) & (xop_D == 3);
    wire isLd_D = (opCode_D == 15) & (xop_D == 0);
    wire isSt_D = (opCode_D == 15) & (xop_D == 1);

    wire isInvalid_D = !(isSub_D | isMovl_D | isMovh_D | isJz_D | isJnz_D |
                         isJs_D | isJns_D | isLd_D | isSt_D);

   
    //The register numbers
    wire [3:0] ra = ins_D[11:8];
    wire [3:0] rb = ins_D[7:4];
    wire [3:0] rt = ins_D[3:0]; 


    //Update registers for the next stage which is read
    reg [15:0] ins_R;
    reg [15:0] pc_R;
    reg isInvalid_R;
    reg [3:0] reg1in_R;
    reg [3:0] reg2in_R;
    reg read1in_R;
    reg read2in_R;

    //To see if we read from memory
    reg memRead_R;

    assign reg1Adr = ra;
    assign reg2Adr = isSub_D ? rb : rt;

    always @(posedge clk) begin
        valid_R <= valid_D && !flushAndRestartPipe;
        if (valid_D) begin
            ins_R <= ins_D;
            pc_R <= pc_D;
            isInvalid_R <= isInvalid_D;
            //Address of reads
            reg1in_R <= reg1Adr;
            reg2in_R <= reg2Adr;   
            //See if we actually read from them
            //We read from A if we subtract, jump or load or store
            read1in_R <=  ((opCode_D == 0) | (opCode_D == 14) | (opCode_D == 15));
            read2in_R <=  (isSub_D | isMovh_D | (opCode_D == 14) | isSt_D);

            memRead_R <= isLd_D;
        end

    end

    


    //===============READ IN REGS=======================
    //Get the values from the registers
    //Register 0 should always return 0
    //Should read regs a and t unless substraction

    //Update the values we will feed into execute
    reg valid_M = 0;

    reg [15:0] ins_M;
    reg [15:0] pc_M;
    reg [15:0] reg1out_M;
    reg [15:0] reg2out_M;
    reg [3:0] reg1in_M;
    reg [3:0] reg2in_M;
    reg read1in_M;
    reg read2in_M;
    reg [15:0] memAddr_M;
    reg memRead_M;
    reg isInvalid_M;

    always @(posedge clk) begin
        valid_M <= valid_R && !flushAndRestartPipe;
        if (valid_R) begin
            ins_M <= ins_R;
            pc_M <= pc_R;
            reg1out_M <= (reg1in_R === 0) ? $signed(0) : reg1;
            reg2out_M <= (reg2in_R === 0) ? $signed(0) : reg2;
            reg1in_M <= reg1in_R;
            reg2in_M <= reg2in_R;
            read1in_M <= read1in_R;
            read2in_M <= read2in_R;

            memAddr_M <= (reg1in_R == 0) ? 0 : reg1;
            memRead_M <= memRead_R;

            isInvalid_M <= isInvalid_R;
        end
    end

    assign memRead = reg1out_M[15:1];


    //A cycle just so we can read from memory since it take two cycles
    //=====================READ MEM 1======================

    reg valid_M2 = 0;
    

    reg [15:0] ins_M2;
    reg [15:0] pc_M2;
    reg [15:0] reg1out_M2;
    reg [15:0] reg2out_M2;
    reg [3:0] reg1in_M2;
    reg [3:0] reg2in_M2;
    reg read1in_M2;
    reg read2in_M2;
    reg [15:0] memAddr_M2;
    reg memRead_M2;
    reg isInvalid_M2;

    always @(posedge clk) begin
        valid_M2 <= valid_M && !flushAndRestartPipe;
        if (valid_M) begin
            ins_M2 <= ins_M;
            pc_M2 <= pc_M;
            reg1out_M2 <= reg1out_M;
            reg2out_M2 <= reg2out_M;
            reg1in_M2 <= reg1in_M;
            reg2in_M2 <= reg2in_M;
            read1in_M2 <= read1in_M;
            read2in_M2 <= read2in_M;
            memAddr_M2 <= memAddr_M;
            memRead_M2 <= memRead_M;
            isInvalid_M2 <= isInvalid_M;
        end
    end

    //A cycle just so we can read from memory since it take two cycles
    //=====================READ MEM 2======================

    reg valid_X = 0;

    reg [15:0] ins_X;
    reg [15:0] pc_X;
    reg [15:0] reg1out_X;
    reg [15:0] reg2out_X;
    reg [3:0] reg1in_X;
    reg [3:0] reg2in_X;
    reg read1in_X;
    reg read2in_X;
    reg [15:0] memAddr_X;
    reg memRead_X;
    reg isInvalid_X;

    always @(posedge clk) begin
        valid_X <= valid_M2 && !flushAndRestartPipe;
        if (valid_M2) begin
            ins_X <= ins_M2;
            pc_X <= pc_M2;
            reg1out_X <= reg1out_M2;
            reg2out_X <= reg2out_M2;
            reg1in_X <= reg1in_M2;
            reg2in_X <= reg2in_M2;
            read1in_X <= read1in_M2;
            read2in_X <= read2in_M2;
            memAddr_X <= memAddr_M2;
            memRead_X <= memRead_M2;
            isInvalid_X <= isInvalid_M2;
        end
    end

    //================EXECUTE========================

    reg valid_W = 0;

    wire[3:0] opCode_X = ins_X[15:12];
    wire[3:0] xop_X = ins_X[7:4];

    //See which command we are
    wire isSub_X = (opCode_X == 0);
    wire isMovl_X = (opCode_X == 8);
    wire isMovh_X = (opCode_X == 9);
    wire isJz_X = (opCode_X == 14) & (xop_X == 0);
    wire isJnz_X = (opCode_X == 14) & (xop_X == 1);
    wire isJs_X = (opCode_X == 14) & (xop_X == 2);
    wire isJns_X = (opCode_X == 14) & (xop_X == 3);
    wire isLd_X = (opCode_X == 15) & (xop_X == 0);
    wire isSt_X = (opCode_X == 15) & (xop_X == 1);

    wire[7:0] i = ins_X[11:4];


    //Update regs to feed into writeback

    reg [15:0] ins_W;
    reg [15:0] pc_W;
    reg [15:0] reg1out_W;
    reg [15:0] reg2out_W;
    reg [3:0] reg1in_W;
    reg [3:0] reg2in_W;
    reg read1in_W;
    reg read2in_W;
    reg [15:0] out_W;
    reg isTakenJump_W;
    reg isInvalid_W;

    always @(posedge clk) begin
        valid_W <= valid_X && !flushAndRestartPipe;
        if (valid_X) begin
            ins_W <= ins_X;
            pc_W <= pc_X;
            reg1out_W <= reg1out_X;
            reg2out_W <= reg2out_X;
            reg1in_W <= reg1in_X;
            reg2in_W <= reg2in_X;
            read1in_W <= read1in_X;
            read2in_W <= read2in_X;
            isInvalid_W <= isInvalid_X;

            // The value we should assign to rt //was regoutR - reg2out_R

            //read from reg 2 because the values in reg2out_R aren't ready
            out_W <= isSub_X ? reg1out_X - reg2out_X : 
                        isMovl_X ? $signed(i) : //(i[7] ? 16'hff00 | i : i) :
                        isMovh_X ? (reg2out_X & 8'hff) | (i << 8):
                        isLd_X ? readOut : 0;

            //See if we update the pc
            isTakenJump_W <=  (isJz_X & reg1out_X == 0)  ? 1 :
                            (isJnz_X & reg1out_X != 0) ? 1 : 
                            (isJs_X & reg1out_X[15])   ? 1 :
                            (isJns_X & !reg1out_X[15]) ? 1 : 0;  

        end
    end


    //====================WRITEBACK======================
    wire[3:0] opCode_W = ins_W[15:12];
    wire[3:0] xop_W = ins_W[7:4];

    //See which command we are
    wire isSub_W = (opCode_W == 0);
    wire isMovl_W = (opCode_W == 8);
    wire isMovh_W = (opCode_W == 9);
    wire isJz_W = (opCode_W == 14) & (xop_W == 0);
    wire isJnz_W = (opCode_W == 14) & (xop_W == 1);
    wire isJs_W = (opCode_W == 14) & (xop_W == 2);
    wire isJns_W = (opCode_W == 14) & (xop_W == 3);
    wire isLd_W = (opCode_W == 15) & (xop_W == 0);
    wire isSt_W = (opCode_W == 15) & (xop_W == 1);


    // The lower values in case we need to print
    wire [7:0] lowerOut_W = out_W[7:0]; 
    wire [3:0] rt_W = ins_W[3:0];


    //Deal with storing and writing to memory
    assign writeMem = isSt_W && valid_W;
    assign writeAddr = reg1out_W[15:1]; 
    assign writeData = reg2out_W;

    //See if we update registers
    assign writeRegs = (isSub_W | isMovl_W | isMovh_W | isLd_W) && valid_W;
    assign regAddr = rt_W;
    assign regData = out_W;
    
    wire writeToR0 = writeRegs && (rt_W == 0);

    //Set after write

    //Check if the register we write to is in another stage
    wire regReadAfterWrite = writeRegs && (
        ((read1in_R && (regAddr === reg1in_R)) || (read2in_R && (regAddr === reg2in_R))) ||
        ((read1in_M && (regAddr === reg1in_M)) || (read2in_M && (regAddr === reg2in_M))) ||
        ((read1in_M2 && (regAddr === reg1in_M2)) || (read2in_M2 && (regAddr === reg2in_M2))) ||
        ((read1in_X && (regAddr === reg1in_X)) || (read2in_X && (regAddr === reg2in_X)))
    );

    //Check if the mem address we write to is in another stage
    wire memReadAfterWrite = writeMem && (
        (memRead_M && (memAddr_M === writeAddr)) ||
        (memRead_M2 && (memAddr_M2 === writeAddr)) ||
        (memRead_X && (memAddr_X === writeAddr))
    );

    wire selfModify = writeMem && (
        (pc_F[15:1] == writeAddr) ||
        (pc_D[15:1] == writeAddr) ||
        (pc_R[15:1] == writeAddr) ||
        (pc_M[15:1] == writeAddr) ||
        (pc_M2[15:1] == writeAddr) ||
        (pc_X[15:1]== writeAddr)
    );
    
    wire RAW = regReadAfterWrite || memReadAfterWrite;

    //See if there are any hazards
    wire flushAndRestartPipe = (RAW || isTakenJump_W || selfModify) && valid_W;

    reg stallForSelfMod = 0;
    reg [15:0] pc_S;

    always @(posedge clk) begin

        if (valid_W) begin       

            if (isInvalid_W) begin 
                halt <= 1;
                $finish;
            end

            //Update Regs
            if(writeToR0) begin
                $write("%s", lowerOut_W);
            end 

            //Update PC
            if (isTakenJump_W) begin
                pc <= reg2out_W;
            end else if (RAW || selfModify) begin
                pc <= pc_W + 2;
            end  
        end

        //On a normal case just update the pc by two
        if(!(flushAndRestartPipe && valid_W)) begin
           pc <= pc+2;
        end
    end

endmodule
