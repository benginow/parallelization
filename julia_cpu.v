`timescale 1ps/1ps

module main();
    integer i;

    // PC

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // clock
    wire clk;
    clock c0(clk);

    reg halt = 0;

    counter ctr(halt,clk);
    
    wire[15:1] mem_raddr0;
    wire[15:0] mem_rdata0;
    wire[15:1] mem_raddr1;
    wire[15:0] mem_rdata1;
    wire mem_wen;
    wire[15:1] mem_waddr;
    wire[15:0] mem_wdata;
    assign mem_raddr0 = fet_pc[15:1];
    assign mem_raddr1 = exr_mem_raddr1;
    assign mem_wen = wb_mem_wen;
    assign mem_waddr = wb_mem_waddr;
    assign mem_wdata = wb_mem_wdata;
    mem mem(clk,
         mem_raddr0,mem_rdata0,
         mem_raddr1, mem_rdata1,
         mem_wen, mem_waddr, mem_wdata);

    reg mem_wen_forward1 = 0;
    reg mem_wen_forward2 = 0;
    reg mem_wen_forward3 = 0;
    reg[15:1] mem_waddr_forward1 = 0;
    reg[15:1] mem_waddr_forward2 = 0;
    reg[15:1] mem_waddr_forward3 = 0;
    reg[15:0] mem_wdata_forward1 = 0;
    reg[15:0] mem_wdata_forward2 = 0;
    reg[15:0] mem_wdata_forward3 = 0;

    always @(posedge clk) begin
        mem_wen_forward1 <= mem_wen;
        mem_wen_forward2 <= mem_wen_forward1;
        mem_wen_forward3 <= mem_wen_forward2;
        mem_waddr_forward1 <= mem_waddr;
        mem_waddr_forward2 <= mem_waddr_forward1;
        mem_waddr_forward3 <= mem_waddr_forward2;
        mem_wdata_forward1 <= mem_wdata;
        mem_wdata_forward2 <= mem_wdata_forward1;
        mem_wdata_forward3 <= mem_wdata_forward2;
    end

    wire[3:0] reg_raddr0;
    wire[15:0] reg_rdata0;
    wire[3:0] reg_raddr1;
    wire[15:0] reg_rdata1;
    wire reg_wen;
    wire[3:0] reg_waddr;
    wire[15:0] reg_wdata;
    assign reg_raddr0 = dec_ra;
    assign reg_raddr1 = dec_is_sub ? dec_rb : dec_rt;
    assign reg_wen = wb_reg_wen && reg_waddr !== 0;
    assign reg_waddr = wb_reg_waddr;
    assign reg_wdata = wb_reg_wdata;
    regs regs(clk,
        reg_raddr0,reg_rdata0,
        reg_raddr1,reg_rdata1,
        reg_wen, reg_waddr, reg_wdata);

    reg reg_wen_forward1 = 0;
    reg reg_wen_forward2 = 0;
    reg[3:0] reg_waddr_forward1 = 0;
    reg[3:0] reg_waddr_forward2 = 0;
    reg[15:0] reg_wdata_forward1 = 0;
    reg[15:0] reg_wdata_forward2 = 0;

    always @(posedge clk) begin
        reg_wen_forward1 <= reg_wen;
        reg_wen_forward2 <= reg_wen_forward1;
        reg_waddr_forward1 <= reg_waddr;
        reg_waddr_forward2 <= reg_waddr_forward1;
        reg_wdata_forward1 <= reg_wdata;
        reg_wdata_forward2 <= reg_wdata_forward1;
    end


    // FETCH STAGE
    reg [15:0]fet_pc = 16'h0000;
    wire fet_flush = wb_is_flushing;
    wire fet_stall = 0;
    reg fet_invalid = 0;

    always @(posedge clk) begin
        if (!fet_stall) begin
            if (!fet_flush) begin
                fet_pc <= fet_pc+2;
            end
            fet2_pc <= fet_pc;
            fet2_invalid <= fet_flush ? 1 : fet_invalid;
        end
    end

    reg [15:0]fet2_pc;
    wire fet2_flush = wb_is_flushing;
    wire fet2_stall = 0;
    reg fet2_invalid = 1;

    always @(posedge clk) begin
        if (!fet2_stall) begin
            dec_pc <= fet2_pc;
            dec_invalid <= fet2_flush ? 1 : fet2_invalid;
        end
    end

    //DECODE STAGE
    reg[15:0] dec_pc;
    wire dec_flush = wb_is_flushing;
    wire dec_stall = 0;
    reg dec_invalid = 1;
    wire[3:0] dec_opcode = mem_rdata0[15:12];
    wire[7:0] dec_imm = mem_rdata0[11:4];
    wire[3:0] dec_ra = mem_rdata0[11:8];
    wire[3:0] dec_rb = mem_rdata0[7:4];
    wire[3:0] dec_xop = mem_rdata0[7:4];
    wire[3:0] dec_rt = mem_rdata0[3:0];
    wire dec_is_sub = (dec_opcode === 0);
    wire dec_is_movl = (dec_opcode === 8);
    wire dec_is_movh = (dec_opcode === 9);
    wire dec_is_jz = (dec_opcode === 14 && dec_xop === 0);
    wire dec_is_jnz = (dec_opcode === 14 && dec_xop === 1);
    wire dec_is_js = (dec_opcode === 14 && dec_xop === 2);
    wire dec_is_jns = (dec_opcode === 14 && dec_xop === 3);
    wire dec_is_ld = (dec_opcode === 15 && dec_xop === 0);
    wire dec_is_st = (dec_opcode === 15 && dec_xop === 1);

    wire dec_is_halt = (!dec_is_sub && !dec_is_movl && !dec_is_movh &&
                        !dec_is_jz && !dec_is_jnz && !dec_is_js && !dec_is_jns &&
                        !dec_is_ld && !dec_is_st);

    always @(posedge clk) begin
        if (!dec_stall) begin
            exr_pc <= dec_pc;
            exr_invalid <= dec_flush ? 1 : dec_invalid;

            exr_opcode <= dec_opcode;
            exr_imm <= dec_imm;
            exr_ra <= dec_ra;
            exr_rb <= dec_rb;
            exr_xop <= dec_xop;
            exr_rt <= dec_rt;
            exr_is_sub <= dec_is_sub;
            exr_is_movl <= dec_is_movl;
            exr_is_movh <= dec_is_movh;
            exr_is_jz <= dec_is_jz;
            exr_is_jnz <= dec_is_jnz;
            exr_is_js <= dec_is_js;
            exr_is_jns <= dec_is_jns;
            exr_is_ld <= dec_is_ld;
            exr_is_st <= dec_is_st;
            exr_is_halt <= dec_is_halt;
        end
    end

    //EXECUTE R STAGE -> FETCHING FROM REGISTERS
    reg[15:0] exr_pc;
    wire exr_flush = wb_is_flushing;
    wire exr_stall = 0;
    reg exr_invalid = 1; 
    reg[3:0] exr_opcode;
    reg[7:0] exr_imm;
    reg[3:0] exr_ra;
    reg[3:0] exr_rb;
    reg[3:0] exr_xop;
    reg[3:0] exr_rt;
    reg exr_is_sub;
    reg exr_is_movl;
    reg exr_is_movh;
    reg exr_is_jz;
    reg exr_is_jnz;
    reg exr_is_js;
    reg exr_is_jns;
    reg exr_is_ld;
    reg exr_is_st;
    reg exr_is_halt;
    
    wire[15:0] exr_ra_val = exr_ra === 0 ? 0 :
                            (exr_ra === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exr_ra === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exr_ra === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            reg_rdata0;
    wire[15:0] exr_rb_val = exr_rb === 0 ? 0 :
                            (exr_rb === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exr_rb === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exr_rb === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            reg_rdata1;
    wire[15:0] exr_rt_val = exr_rt === 0 ? 0 :
                            (exr_rt === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exr_rt === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exr_rt === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            reg_rdata1;

    wire[15:1] exr_mem_raddr1 = exr_ra_val[15:1];

    always @(posedge clk) begin
        
        if (!exr_stall) begin
            exm_pc <= exr_pc;
            exm_invalid <= exr_flush ? 1 : exr_invalid;

            exm_opcode <= exr_opcode;
            exm_imm <= exr_imm;
            exm_ra <= exr_ra;
            exm_rb <= exr_rb;
            exm_xop <= exr_xop;
            exm_rt <= exr_rt;
            exm_is_sub <= exr_is_sub;
            exm_is_movl <= exr_is_movl;
            exm_is_movh <= exr_is_movh;
            exm_is_jz <= exr_is_jz;
            exm_is_jnz <= exr_is_jnz;
            exm_is_js <= exr_is_js;
            exm_is_jns <= exr_is_jns;
            exm_is_ld <= exr_is_ld;
            exm_is_st <= exr_is_st;
            exm_is_halt <= exr_is_halt;
            exm_ra_val <= exr_ra_val;
            exm_rb_val <= exr_rb_val;
            exm_rt_val <= exr_rt_val;
        end
    end

    //EXECUTE M STAGE -> FETCHING FROM MEM
    reg[15:0] exm_pc;
    wire exm_flush = wb_is_flushing;
    wire exm_stall = 0;
    reg exm_invalid = 1; 
    reg[3:0] exm_opcode;
    reg[7:0] exm_imm;
    reg[3:0] exm_ra;
    reg[3:0] exm_rb;
    reg[3:0] exm_xop;
    reg[3:0] exm_rt;
    reg exm_is_sub;
    reg exm_is_movl;
    reg exm_is_movh;
    reg exm_is_jz;
    reg exm_is_jnz;
    reg exm_is_js;
    reg exm_is_jns;
    reg exm_is_ld;
    reg exm_is_st;
    reg exm_is_halt;

    reg[15:0] exm_ra_val;
    reg[15:0] exm_rb_val;
    reg[15:0] exm_rt_val;

    always @(posedge clk) begin
        if (!exm_stall) begin
            wb_pc <= exm_pc;
            wb_invalid <= exm_flush ? 1 : exm_invalid;

            wb_opcode <= exm_opcode;
            wb_imm <= exm_imm;
            wb_ra <= exm_ra;
            wb_rb <= exm_rb;
            wb_xop <= exm_xop;
            wb_rt <= exm_rt;
            wb_is_sub <= exm_is_sub;
            wb_is_movl <= exm_is_movl;
            wb_is_movh <= exm_is_movh;
            wb_is_jz <= exm_is_jz;
            wb_is_jnz <= exm_is_jnz;
            wb_is_js <= exm_is_js;
            wb_is_jns <= exm_is_jns;
            wb_is_ld <= exm_is_ld;
            wb_is_st <= exm_is_st;
            wb_is_halt <= exm_is_halt;

            wb_ra_val <= exm_ra === 0 ? 0 :
                            (exm_ra === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exm_ra === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exm_ra === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            exm_ra_val;
            wb_rb_val <= exm_rb === 0 ? 0 :
                            (exm_rb === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exm_rb === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exm_rb === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            exm_rb_val;
            wb_rt_val <= exm_rt === 0 ? 0 :
                            (exm_rt === reg_waddr && reg_wen && reg_wen !== 1'bx) ? reg_wdata :
                            (exm_rt === reg_waddr_forward1 && reg_wen_forward1 && reg_wen_forward1 !== 1'bx) ? reg_wdata_forward1 :
                            (exm_rt === reg_waddr_forward2 && reg_wen_forward2 && reg_wen_forward2 !== 1'bx) ? reg_wdata_forward2 :
                            exm_rt_val;
        end
    end

    //WRITE BACK -> WRITE TO REGS AND MEM
    reg[15:0] wb_pc;
    wire wb_flush = 0;
    wire wb_stall = 0;
    reg wb_invalid = 1; 
    reg[3:0] wb_opcode;
    reg[7:0] wb_imm;
    reg[3:0] wb_ra;
    reg[3:0] wb_rb;
    reg[3:0] wb_xop;
    reg[3:0] wb_rt;
    reg wb_is_sub;
    reg wb_is_movl;
    reg wb_is_movh;
    reg wb_is_jz;
    reg wb_is_jnz;
    reg wb_is_js;
    reg wb_is_jns;
    reg wb_is_ld;
    reg wb_is_st;
    reg wb_is_halt;

    reg[15:0] wb_ra_val;
    reg[15:0] wb_rb_val;
    reg[15:0] wb_rt_val;
    wire[15:0] wb_mem_val = (wb_ra_val[15:1] === mem_waddr && mem_wen && mem_wen !== 1'bx) ? reg_wdata :
                            (wb_ra_val[15:1] === mem_waddr_forward1 && mem_wen_forward1 && mem_wen_forward1 !== 1'bx) ? mem_wdata_forward1 :
                            (wb_ra_val[15:1] === mem_waddr_forward2 && mem_wen_forward2 && mem_wen_forward2 !== 1'bx) ? mem_wdata_forward2 :
                            (wb_ra_val[15:1] === mem_waddr_forward3 && mem_wen_forward3 && mem_wen_forward3 !== 1'bx) ? mem_wdata_forward3 :
                            mem_rdata1;

    wire wb_reg_wen = (!wb_invalid && (wb_is_sub || wb_is_movl || wb_is_movh || wb_is_ld));
    wire[3:0] wb_reg_waddr = wb_rt;
    wire[15:0] wb_reg_wdata = (wb_is_sub) ? wb_ra_val - wb_rb_val :
                        (wb_is_movl) ? {wb_imm[7] ? 8'hff : 8'h00, wb_imm} :
                        (wb_is_movh) ? {wb_imm, wb_rt_val[7:0]} :
                        (wb_is_ld) ? wb_mem_val : 0;

    wire wb_mem_wen = (!wb_invalid && wb_is_st);
    wire[15:1] wb_mem_waddr = wb_ra_val[15:1];
    wire[15:0] wb_mem_wdata = wb_rt_val;

    wire wb_is_jumping = (wb_is_jz) ? (wb_ra_val === 0 ? 1 : 0) :
                            (wb_is_jnz) ? (wb_ra_val !== 0 ? 1 : 0) :
                            (wb_is_js) ? (wb_ra_val[15] === 1 ? 1 : 0) :
                            (wb_is_jns) ? (wb_ra_val[15] === 0 ? 1 : 0) : 0;
    wire wb_reg_flush_hazard = !exm_invalid && exm_is_ld && exm_ra === wb_reg_waddr && wb_reg_wen;
    wire wb_mem_flush_hazard = wb_mem_wen && (wb_ra_val >= wb_pc && wb_ra_val <= wb_pc + 20);
    wire wb_is_flushing = !wb_invalid && 
        ((wb_is_jumping !== 1'bx && wb_is_jumping) || wb_reg_flush_hazard || wb_mem_flush_hazard);


    always @(posedge clk) begin
        if (!wb_invalid) begin
            if (wb_is_flushing) begin
                if (wb_is_jumping) begin
                    fet_pc <= wb_rt_val;
                end
                else begin
                    fet_pc <= wb_pc + 2;
                end
            end
            if (wb_reg_wen && wb_reg_waddr === 0) begin
                $write("%c", wb_reg_wdata);
            end
            if (wb_is_halt) begin
                halt <= 1;
            end
        end
    end

endmodule

