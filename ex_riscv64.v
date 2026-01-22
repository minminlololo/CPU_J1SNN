`include "/home/IC/Desktop/risc_cpu/src/defines.v"

// EX模块定义
module EX
(
    // 来自id_ex模块的输入
    input wire [31:0]  inst_i          , // 指令输入
    input wire [63:0]  inst_addr_i     , // 指令地址
    input wire [63:0]  op1_i           , // 操作数1
    input wire [63:0]  op2_i           , // 操作数2
    input wire [4 :0]  rd_addr_i       , // 目标寄存器地址
    input wire         rd_wen_i        , // 目标寄存器写使能
    input wire [63:0]  base_addr_i     , // 基地址
    input wire [63:0]  addr_offset_i   , // 地址偏移量
    input wire         csr_we_i        , // CSR写使能
    input wire [63:0]  csr_rdata_i     , // CSR读数据
    input wire [63:0]  csr_waddr_i     , // CSR写地址
    input wire [31:0]  id_axi_araddr_i , // AXI读地址
    input wire         read_ram_i      , // 读内存信号
    input wire         write_ram_i     , // 写内存信号
    
    // 来自clint模块的输入
    input wire         int_assert_i    , // 中断信号
    input wire [63:0]  int_addr_i      , // 中断处理程序入口地址
    
    // 输出到ex_mem模块
    output wire [4 :0] rd_addr_o       , // 目标寄存器地址
    output wire [63:0] rd_data_o       , // 目标寄存器数据
    output wire        rd_wen_o        , // 目标寄存器写使能
    output wire [31:0] id_axi_araddr_o , // AXI读地址输出
    output wire        read_ram_o      , // 读内存信号输出
    output wire        write_ram_o     , // 写内存信号输出
    output wire [31:0] inst_o          , // 指令输出
    output wire [63:0] inst_addr_o     , // 指令地址输出
    output wire [63:0] op2_o           , // 操作数2输出
    
    // 输出到CSR寄存器
    output wire        csr_we_o        , // CSR写使能输出
    output reg  [63:0] csr_wdata_o     , // CSR写数据
    output wire [63:0] csr_waddr_o     , // CSR写地址输出
    
    // 输出到控制模块和clint
    output wire [63:0] jump_addr_o     , // 跳转地址
    output wire        jump_en_o       , // 跳转使能信号
    output wire        hold_flag_o     , // 流水线暂停信号
    
    // 来自除法器的输入
    input wire         div_finish_i    , // 除法完成信号
    input wire [63:0]  div_rem_data_i  , // 除法余数结果
    input wire         div_busy_i      , // 除法器忙信号
    
    // 输出到除法器
    output reg         div_ready_o     , // 除法器就绪信号
    output reg  [63:0] div_dividend_o  , // 被除数
    output reg  [63:0] div_divisor_o   , // 除数
    output reg  [9 :0] div_op_o        , // 除法操作码
    
    // 来自乘法器的输入
    input wire         mult_finish_i   , // 乘法完成信号
    input wire [63:0]  mult_product_val, // 乘积结果
    input wire         mult_busy_i     , // 乘法器忙信号
    
    // 输出到乘法器
    output reg         mult_ready_o    , // 乘法器就绪信号
    output reg [63:0]  mult_op1_o      , // 乘数1
    output reg [63:0]  mult_op2_o      , // 乘数2
    output reg [9 :0]  mult_op_o       // 乘法操作码
);

    // 指令字段解析
    wire [6 :0] opcode;  // 操作码（7位）
    wire [4 :0] rd;      // 目标寄存器
    wire [2 :0] funct3;  // 功能码3位
    wire [4 :0] rs1;     // 源寄存器1
    wire [4 :0] rs2;     // 源寄存器2
    wire [6 :0] funct7;  // 功能码7位
    wire [11:0] imm;     // 立即数12位
    wire [5 :0] shamt;   // 移位位数
    wire [4 :0] uimm;    // 无符号立即数5位

    // 指令字段赋值
    assign opcode = inst_i[6 :0 ];  // 提取操作码
    assign rd     = inst_i[11:7 ];  // 提取目标寄存器
    assign funct3 = inst_i[14:12];  // 提取funct3
    assign rs1    = inst_i[19:15];  // 提取rs1
    assign rs2    = inst_i[24:20];  // 提取rs2
    assign funct7 = inst_i[31:25];  // 提取funct7
    assign imm    = inst_i[31:20];  // 提取立即数
    assign shamt  = inst_i[25:20];  // 提取移位位数
    assign uimm   = inst_i[19:15];  // 提取无符号立即数

    // 直接传递的信号
    assign read_ram_o      = read_ram_i     ;  // 读内存信号传递
    assign write_ram_o     = write_ram_i    ;  // 写内存信号传递
    assign inst_o          = inst_i         ;  // 指令传递
    assign inst_addr_o     = inst_addr_i    ;  // 指令地址传递
    assign id_axi_araddr_o = id_axi_araddr_i;  // AXI读地址传递
    assign op2_o           = op2_i          ;  // 操作数2传递

    // 比较器：用于分支指令
    wire        op1_i_equal_op2_i        ;  // 操作数1等于操作数2
    wire        op1_i_less_op2_i_signed  ;  // 操作数1小于操作数2（有符号）
    wire        op1_i_less_op2_i_unsigned;  // 操作数1小于操作数2（无符号）

    // 比较器赋值
    assign op1_i_equal_op2_i         = (op1_i == op2_i)?1'b1:1'b0                 ;  // 等于比较
    assign op1_i_less_op2_i_signed   = ($signed(op1_i) < $signed(op2_i))?1'b1:1'b0;  // 有符号小于比较
    assign op1_i_less_op2_i_unsigned = (op1_i < op2_i)?1'b1:1'b0                  ;  // 无符号小于比较
    
    // ALU运算单元
    wire [63:0] op1_i_add_op2_i          ;  // 加法结果
    wire [63:0] op1_i_sub_op2_i          ;  // 减法结果
    wire [63:0] op1_i_and_op2_i          ;  // 与运算结果
    wire [63:0] op1_i_xor_op2_i          ;  // 异或运算结果
    wire [63:0] op1_i_or_op2_i           ;  // 或运算结果
    wire [63:0] op1_i_shift_left_op2_i   ;  // 左移结果
    wire [63:0] op1_i_shift_right_op2_i  ;  // 逻辑右移结果
    wire [63:0] base_addr_add_addr_offset;  // 基地址加偏移量

    // ALU运算赋值
    assign op1_i_add_op2_i           = op1_i + op2_i              ;  // 加法器
    assign op1_i_sub_op2_i           = op1_i - op2_i              ;  // 减法器
    assign op1_i_and_op2_i           = op1_i & op2_i              ;  // 与运算
    assign op1_i_xor_op2_i           = op1_i ^ op2_i              ;  // 异或运算
    assign op1_i_or_op2_i            = op1_i | op2_i              ;  // 或运算
    assign op1_i_shift_left_op2_i    = op1_i << op2_i             ;  // 左移
    assign op1_i_shift_right_op2_i   = op1_i >> op2_i             ;  // 逻辑右移
    assign base_addr_add_addr_offset = base_addr_i + addr_offset_i;  // 地址计算

    // 算术右移掩码
    wire [63:0] SRA_mask;
    assign SRA_mask = 64'hffff_ffff_ffff_ffff >> op2_i[5:0];  // 生成算术右移掩码

    // 加载/存储索引
    wire [2:0] load_index = base_addr_add_addr_offset[2:0];   // 加载索引
    wire [2:0] store_index = base_addr_add_addr_offset[2:0];  // 存储索引
    
    // 乘法相关信号
    reg  [63 :0] op1_mul     ;  // 乘法操作数1
    reg  [63 :0] op2_mul     ;  // 乘法操作数2
    wire [127:0] mul_temp    ;  // 乘法临时结果
    wire [127:0] mul_temp_inv;  // 乘法临时结果取反
    
    // 除法相关信号
    reg  [63 :0] op1_div_op2_res  ;  // 除法结果
    reg  [63 :0] op1_rem_op2_res  ;  // 余数结果
    reg  [31 :0] op1_div_op2_res_w;  // 32位除法结果
    reg  [31 :0] op1_rem_op2_res_w;  // 32位余数结果
    
    // 操作数取反
    wire [63 :0] op1_i_inv;  // 操作数1取反
    wire [63 :0] op2_i_inv;  // 操作数2取反
    assign op1_i_inv = ~op1_i + 1;  // 操作数1取反加1（补码）
    assign op2_i_inv = ~op2_i + 1;  // 操作数2取反加1（补码）
    
    // 乘法结果计算
    assign mul_temp     = op1_i * op2_i;      // 乘法结果
    assign mul_temp_inv = ~mul_temp + 1;      // 乘法结果取反加1（补码）
    
    // 移位操作相关信号
    wire [63 :0] sli_shift               ;  // 移位结果
    wire [31 :0] op1_lower32bit_mask     ;  // 低32位掩码
    wire [31 :0] op1_lower32bit_rlshift  ;  // 低32位逻辑右移
    wire [31 :0] op1_lower32bit_rashift  ;  // 低32位算术右移
    wire [31 :0] op1_lower32bit_srawmask ;  // 低32位算术右移掩码
    wire [31 :0] op1_lower32bit_srlwshift;  // 低32位逻辑右移（字）
    wire [31 :0] op1_lower32bit_srawshift;  // 低32位算术右移（字）
    wire [31 :0] sllw_temp               ;  // 低32位左移（字）
    
    // 除法和乘法寄存器地址
    reg [4:0] div_reg_waddr ;  // 除法结果寄存器地址
    reg [4:0] mult_reg_waddr;  // 乘法结果寄存器地址
    
    // 移位操作赋值
    assign sli_shift                = op1_i << {58'b0,op2_i[5:0]};  // 移位操作
    assign op1_lower32bit_mask      = ~(32'hffff_ffff >> {59'b0,op2_i[4:0]});  // 生成掩码
    assign op1_lower32bit_rlshift   = op1_i[31:0] >> {59'b0,op2_i[4:0]};  // 逻辑右移
    assign op1_lower32bit_rashift   = (op1_i[31] == 1)?op1_lower32bit_mask|op1_lower32bit_rlshift:op1_lower32bit_rlshift;  // 算术右移
    assign op1_lower32bit_srawmask  = ~(32'hffff_ffff >> op2_i[4:0]);  // 算术右移掩码
    assign op1_lower32bit_srlwshift = op1_i[31:0] >> op2_i[4:0];  // 逻辑右移（字）
    assign op1_lower32bit_srawshift = (op1_i[31] == 1)?op1_lower32bit_srawmask|op1_lower32bit_srlwshift:op1_lower32bit_srlwshift;  // 算术右移（字）
    assign sllw_temp                = op1_i[31:0] << op2_i[4:0];  // 左移（字）
    
    // CSR写使能（中断时不写CSR）
    assign csr_we_o    = (int_assert_i == 1'b1) ? 1'b0 : csr_we_i;  // CSR写使能
    assign csr_waddr_o = csr_waddr_i                             ;  // CSR写地址
    
    // 寄存器写相关信号
    reg [63:0] reg_wdata;  // 寄存器写数据
    reg        reg_we   ;  // 寄存器写使能
    reg [4 :0] reg_waddr;  // 寄存器写地址
    reg        hold_flag;  // 暂停标志
    reg        jump_flag;  // 跳转标志
    reg [63:0] jump_addr;  // 跳转地址
    
    // 除法相关寄存器
    reg [63:0] div_wdata    ;  // 除法写数据
    reg        div_we       ;  // 除法写使能
    reg [4 :0] div_waddr    ;  // 除法写地址
    reg        div_hold_flag;  // 除法暂停标志
    reg [63:0] div_jump_addr;  // 除法跳转地址
    reg        div_jump_flag;  // 除法跳转标志
    
    // 乘法相关寄存器
    reg [63:0] mult_wdata    ;  // 乘法写数据
    reg        mult_we       ;  // 乘法写使能
    reg [4 :0] mult_waddr    ;  // 乘法写地址
    reg        mult_hold_flag;  // 乘法暂停标志
    reg [63:0] mult_jump_addr;  // 乘法跳转地址
    reg        mult_jump_flag;  // 乘法跳转标志
    
    // 输出信号赋值
    assign rd_data_o   = reg_wdata | div_wdata | mult_wdata                                                    ;  // 寄存器写数据
    assign rd_wen_o    = (int_assert_i == 1'b1) ? 1'b0 : (reg_we || div_we || mult_we)                         ;  // 寄存器写使能
    assign rd_addr_o   = reg_waddr | div_waddr | mult_waddr                                                    ;  // 寄存器写地址
    assign hold_flag_o = hold_flag || div_hold_flag || mult_hold_flag                                          ;  // 暂停标志
    assign jump_en_o   = jump_flag || div_jump_flag || mult_jump_flag || ((int_assert_i == 1'b1) ? 1'b1 : 1'b0);  // 跳转使能
    assign jump_addr_o = (int_assert_i == 1'b1) ? int_addr_i : (jump_addr | div_jump_addr | mult_jump_addr)    ;  // 跳转地址
    
    // 除法器控制逻辑
    always @ (*) begin
        if((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            div_we         = 1'b0            ;  // 除法写使能
            div_wdata      = 64'b0           ;  // 除法写数据
            div_waddr      = 5'b0            ;  // 除法写地址
            div_dividend_o = op1_i           ;  // 被除数
            div_divisor_o  = op2_i           ;  // 除数
            div_op_o       = {opcode, funct3};  // 除法操作码
            div_reg_waddr  = rd_addr_i       ;  // 除法结果寄存器地址
            case (funct3)
                `INST_DIV, `INST_DIVU, `INST_REM, `INST_REMU:begin  // 除法/取余指令
                    div_ready_o   = 1'b1                     ;  // 除法器就绪
                    div_jump_flag = 1'b1                     ;  // 除法跳转标志
                    div_hold_flag = 1'b1                     ;  // 除法暂停标志
                    div_jump_addr = base_addr_add_addr_offset;  // 除法跳转地址
                end 
                default:begin
                    div_ready_o   = 1'b0;  // 除法器不就绪
                    div_jump_flag = 1'b0;  // 无除法跳转
                    div_hold_flag = 1'b0;  // 无除法暂停
                    div_jump_addr = 1'b0;  // 无除法跳转地址
                end
            endcase
        end   
        else if((opcode == `INST_TYPE_R_M_64W) && (funct7 == 7'b0000001)) begin
            div_we         = 1'b0            ;  // 除法写使能
            div_wdata      = 64'b0           ;  // 除法写数据
            div_waddr      = 5'b0            ;  // 除法写地址
            div_dividend_o = op1_i           ;  // 被除数
            div_divisor_o  = op2_i           ;  // 除数
            div_op_o       = {opcode, funct3};  // 除法操作码
            div_reg_waddr  = rd_addr_i       ;  // 除法结果寄存器地址
            case (funct3)
                `INST_DIVW, `INST_DIVUW, `INST_REMW, `INST_REMUW:begin  // 32位除法/取余
                    div_ready_o   = 1'b1                     ;  // 除法器就绪
                    div_jump_flag = 1'b1                     ;  // 除法跳转标志
                    div_hold_flag = 1'b1                     ;  // 除法暂停标志
                    div_jump_addr = base_addr_add_addr_offset;  // 除法跳转地址
                end 
                default:begin
                    div_ready_o   = 1'b0 ;  // 除法器不就绪
                    div_jump_flag = 1'b0 ;  // 无除法跳转
                    div_hold_flag = 1'b0 ;  // 无除法暂停
                    div_jump_addr = 64'b0;  // 无除法跳转地址
                end
            endcase
        end
        else begin
            div_jump_flag = 1'b0 ;  // 无除法跳转
            div_jump_addr = 64'b0;  // 无除法跳转地址
            if(div_busy_i == 1'b1) begin  // 除法器忙
                div_ready_o   = 1'b1 ;  // 除法器就绪
                div_we        = 1'b0 ;  // 无除法写使能
                div_wdata     = 64'b0;  // 无除法写数据
                div_waddr     = 5'b0 ;  // 无除法写地址
                div_hold_flag = 1'b1 ;  // 除法暂停标志
            end
            else begin
                div_ready_o   = 1'b0;  // 除法器不就绪
                div_hold_flag = 1'b0;  // 无除法暂停
                if(div_finish_i == 1'b1) begin  // 除法完成
                    div_wdata = div_rem_data_i;  // 除法结果
                    div_waddr = div_reg_waddr ;  // 除法结果寄存器地址
                    div_we    = 1'b1          ;  // 除法写使能
                end
                else begin
                    div_wdata = 64'b0;  // 无除法写数据
                    div_waddr = 5'b0 ;  // 无除法写地址
                    div_we    = 1'b0 ;  // 无除法写使能
                end
            end
        end
    end
    
    // 乘法器控制逻辑
    always @ (*) begin
        if((opcode == `INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            mult_we        = 1'b0            ;  // 乘法写使能
            mult_wdata     = 64'b0           ;  // 乘法写数据
            mult_waddr     = 5'b0            ;  // 乘法写地址
            mult_op1_o     = op1_i           ;  // 乘数1
            mult_op2_o     = op2_i           ;  // 乘数2
            mult_op_o      = {opcode, funct3};  // 乘法操作码
            mult_reg_waddr = rd_addr_i       ;  // 乘法结果寄存器地址
            case (funct3)
                `INST_MUL, `INST_MULHU, `INST_MULHSU, `INST_MULH: begin  // 乘法指令
                    mult_ready_o   = 1'b1                     ;  // 乘法器就绪
                    mult_jump_flag = 1'b1                     ;  // 乘法跳转标志
                    mult_hold_flag = 1'b1                     ;  // 乘法暂停标志
                    mult_jump_addr = base_addr_add_addr_offset;  // 乘法跳转地址
                end
                default: begin
                    mult_ready_o   = 1'b0 ;  // 乘法器不就绪
                    mult_jump_flag = 1'b0 ;  // 无乘法跳转
                    mult_hold_flag = 1'b0 ;  // 无乘法暂停
                    mult_jump_addr = 64'b0;  // 无乘法跳转地址
                end
            endcase
        end
        else if((opcode == `INST_TYPE_R_M_64W) && (funct3 == `INST_ADD_SUB_MULW) && (funct7 == 7'b0000001)) begin
            mult_we        = 1'b0                     ;  // 乘法写使能
            mult_wdata     = 64'b0                    ;  // 乘法写数据
            mult_waddr     = 5'b0                     ;  // 乘法写地址
            mult_ready_o   = 1'b1                     ;  // 乘法器就绪
            mult_jump_flag = 1'b1                     ;  // 乘法跳转标志
            mult_hold_flag = 1'b1                     ;  // 乘法暂停标志
            mult_jump_addr = base_addr_add_addr_offset;  // 乘法跳转地址
            mult_op1_o     = op1_i                    ;  // 乘数1
            mult_op2_o     = op2_i                    ;  // 乘数2
            mult_op_o      = {opcode, funct3}         ;  // 乘法操作码
            mult_reg_waddr = rd_addr_i                ;  // 乘法结果寄存器地址
        end
        else begin
            mult_jump_flag = 1'b0 ;  // 无乘法跳转
            mult_jump_addr = 64'b0;  // 无乘法跳转地址
            if(mult_finish_i == 1'b1) begin  // 乘法完成
                mult_ready_o   = 1'b0            ;  // 乘法器不就绪
                mult_hold_flag = 1'b0            ;  // 无乘法暂停
                mult_wdata     = mult_product_val;  // 乘法结果
                mult_waddr     = mult_reg_waddr  ;  // 乘法结果寄存器地址
                mult_we        = 1'b1            ;  // 乘法写使能
            end
            else if(mult_busy_i == 1'b1) begin  // 乘法器忙
                mult_ready_o   = 1'b1 ;  // 乘法器就绪
                mult_we        = 1'b0 ;  // 无乘法写使能
                mult_wdata     = 64'b0;  // 无乘法写数据
                mult_waddr     = 5'b0 ;  // 无乘法写地址
                mult_hold_flag = 1'b1 ;  // 乘法暂停标志
            end
            else begin
                mult_ready_o   = 1'b0 ;  // 乘法器不就绪
                mult_we        = 1'b0 ;  // 无乘法写使能
                mult_wdata     = 64'b0;  // 无乘法写数据
                mult_waddr     = 5'b0 ;  // 无乘法写地址
                mult_hold_flag = 1'b0 ;  // 无乘法暂停
            end
        end
    end
    
    // 主执行逻辑
    always @(*) begin
        case(opcode)
            `INST_TYPE_I:begin  // I型指令
                jump_addr       = 64'b0;  // 无跳转地址
                jump_flag       = 1'b0 ;  // 无跳转
                hold_flag       = 1'b0 ;  // 无暂停
                csr_wdata_o     = 64'b0;  // CSR写数据
                case(funct3)
                    `INST_ADDI:begin  // ADDI指令
                        reg_wdata = op1_i_add_op2_i;  // 加法结果
                        reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                        reg_we    = 1'b1           ;  // 寄存器写使能
                    end
                    `INST_SLTI:begin  // SLTI指令
                        reg_wdata = {63'b0,op1_i_less_op2_i_signed};  // 有符号比较结果
                        reg_waddr = rd_addr_i                      ;  // 目标寄存器地址
                        reg_we    = 1'b1                           ;  // 寄存器写使能
                    end
                    `INST_SLTIU:begin  // SLTIU指令
                        reg_wdata = {63'b0,op1_i_less_op2_i_unsigned};  // 无符号比较结果
                        reg_waddr = rd_addr_i                        ;  // 目标寄存器地址
                        reg_we    = 1'b1                             ;  // 寄存器写使能
                    end
                    `INST_XORI:begin  // XORI指令
                        reg_wdata = op1_i_xor_op2_i;  // 异或结果
                        reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                        reg_we    = 1'b1           ;  // 寄存器写使能
                    end
                    `INST_ORI:begin  // ORI指令
                        reg_wdata = op1_i_or_op2_i;  // 或结果
                        reg_waddr = rd_addr_i     ;  // 目标寄存器地址
                        reg_we    = 1'b1          ;  // 寄存器写使能
                    end
                    `INST_ANDI:begin  // ANDI指令
                        reg_wdata = op1_i_and_op2_i;  // 与结果
                        reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                        reg_we    = 1'b1           ;  // 寄存器写使能
                    end
                    `INST_SLLI:begin  // SLLI指令
                        reg_wdata = op1_i_shift_left_op2_i;  // 左移结果
                        reg_waddr = rd_addr_i             ;  // 目标寄存器地址
                        reg_we    = 1'b1                  ;  // 寄存器写使能
                    end
                    `INST_SRI:begin  // SRI指令（SRLI/SRAI）
                        if(funct7[5] == 1'b1) begin  // SRAI
                            reg_wdata = ((op1_i_shift_right_op2_i) & SRA_mask) | ({64{op1_i[31]}} & (~SRA_mask));  // 算术右移
                            reg_waddr = rd_addr_i                                                               ;  // 目标寄存器地址
                            reg_we    = 1'b1                                                                    ;  // 寄存器写使能
                        end
                        else begin  // SRLI
                            reg_wdata = op1_i_shift_right_op2_i;  // 逻辑右移
                            reg_waddr = rd_addr_i              ;  // 目标寄存器地址
                            reg_we    = 1'b1                   ;  // 寄存器写使能
                        end
                    end
                    default:begin
                        reg_wdata = 64'b0;  // 默认无写数据
                        reg_waddr = 5'b0 ;  // 默认无写地址
                        reg_we    = 1'b0 ;  // 默认无写使能
                    end
                endcase
            end
			            `INST_TYPE_R_M:begin  // R型指令（算术/逻辑运算）
                jump_addr       = 64'b0;  // 无跳转地址
                jump_flag       = 1'b0 ;  // 无跳转
                hold_flag       = 1'b0 ;  // 无暂停
                csr_wdata_o     = 64'b0;  // CSR无写数据
                
                // 检查funct7是否为标准值（0000000或0100000）
                if((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case(funct3)
                        `INST_ADD_SUB:begin  // ADD/SUB指令
                            if(funct7 == 7'b000_0000) begin  // ADD
                                reg_wdata = op1_i_add_op2_i;  // 加法结果
                                reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                                reg_we    = 1'b1           ;  // 寄存器写使能
                            end
                            else begin  // SUB
                                reg_wdata = op1_i_sub_op2_i;  // 减法结果
                                reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                                reg_we    = 1'b1           ;  // 寄存器写使能
                            end
                        end
                        `INST_SLL:begin  // SLL指令（逻辑左移）
                            reg_wdata = op1_i_shift_left_op2_i;  // 左移结果
                            reg_waddr = rd_addr_i             ;  // 目标寄存器地址
                            reg_we    = 1'b1                  ;  // 寄存器写使能
                        end
                        `INST_SLT:begin  // SLT指令（有符号比较）
                            reg_wdata = {63'b0,op1_i_less_op2_i_signed};  // 比较结果（1或0）
                            reg_waddr = rd_addr_i                      ;  // 目标寄存器地址
                            reg_we    = 1'b1                           ;  // 寄存器写使能
                        end
                        `INST_SLTU:begin  // SLTU指令（无符号比较）
                            reg_wdata = {63'b0,op1_i_less_op2_i_unsigned};  // 比较结果（1或0）
                            reg_waddr = rd_addr_i                        ;  // 目标寄存器地址
                            reg_we    = 1'b1                             ;  // 寄存器写使能
                        end
                        `INST_XOR:begin  // XOR指令（异或）
                            reg_wdata = op1_i_xor_op2_i;  // 异或结果
                            reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                            reg_we    = 1'b1           ;  // 寄存器写使能
                        end
                        `INST_OR:begin  // OR指令（或）
                            reg_wdata = op1_i_or_op2_i;  // 或结果
                            reg_waddr = rd_addr_i     ;  // 目标寄存器地址
                            reg_we    = 1'b1          ;  // 寄存器写使能
                        end
                        `INST_AND:begin  // AND指令（与）
                            reg_wdata = op1_i_and_op2_i;  // 与结果
                            reg_waddr = rd_addr_i      ;  // 目标寄存器地址
                            reg_we    = 1'b1           ;  // 寄存器写使能
                        end
                        `INST_SR:begin  // SR指令（SRL/SRA）
                            if(funct7[5] == 1'b1) begin // SRA（算术右移）
                                // 算术右移：高位补符号位
                                reg_wdata = ((op1_i_shift_right_op2_i) & SRA_mask) | ({64{op1_i[31]}} & (~SRA_mask));
                                reg_waddr = rd_addr_i                                                               ;
                                reg_we    = 1'b1                                                                    ;
                            end
                            else begin // SRL（逻辑右移）
                                reg_wdata = op1_i_shift_right_op2_i;  // 逻辑右移结果
                                reg_waddr = rd_addr_i              ;  // 目标寄存器地址
                                reg_we    = 1'b1                   ;  // 寄存器写使能
                            end
                        end
                        default:begin  // 默认情况
                            reg_wdata = 64'b0;  // 无写数据
                            reg_waddr = 5'b0 ;  // 无写地址
                            reg_we    = 1'b0 ;  // 无写使能
                        end
                    endcase
                end
                else begin  // 非标准funct7值
                    reg_wdata = 64'b0;  // 无写数据
                    reg_waddr = 5'b0 ;  // 无写地址
                    reg_we    = 1'b0 ;  // 无写使能
                end
            end
            
            `INST_JAL:begin  // JAL指令（跳转并链接）
                reg_wdata       = op1_i_add_op2_i          ;  // 返回地址（PC+4）
                reg_waddr       = rd_addr_i                ;  // 目标寄存器地址
                reg_we          = 1'b1                     ;  // 寄存器写使能
                jump_addr       = base_addr_add_addr_offset;  // 跳转目标地址
                jump_flag       = 1'b1                     ;  // 跳转使能
                hold_flag       = 1'b0                     ;  // 无暂停
                csr_wdata_o     = 64'b0                    ;  // CSR无写数据
            end
            
            `INST_JALR:begin  // JALR指令（寄存器间接跳转并链接）
                reg_wdata       = op1_i_add_op2_i          ;  // 返回地址（PC+4）
                reg_waddr       = rd_addr_i                ;  // 目标寄存器地址
                reg_we          = 1'b1                     ;  // 寄存器写使能
                jump_addr       = base_addr_add_addr_offset;  // 跳转目标地址（rs1 + imm）
                jump_flag       = 1'b1                     ;  // 跳转使能
                hold_flag       = 1'b0                     ;  // 无暂停
                csr_wdata_o     = 64'b0                    ;  // CSR无写数据
            end
            
            `INST_LUI:begin  // LUI指令（加载高位立即数）
                reg_wdata       = op1_i    ;  // 立即数（高位）
                reg_waddr       = rd_addr_i;  // 目标寄存器地址
                reg_we          = 1'b1     ;  // 寄存器写使能
                jump_addr       = 64'b0    ;  // 无跳转地址
                jump_flag       = 1'b0     ;  // 无跳转
                hold_flag       = 1'b0     ;  // 无暂停
                csr_wdata_o     = 64'b0    ;  // CSR无写数据
            end
            
            `INST_AUIPC:begin  // AUIPC指令（PC加立即数）
                reg_wdata       = op1_i_add_op2_i;  // PC + 立即数
                reg_waddr       = rd_addr_i      ;  // 目标寄存器地址
                reg_we          = 1'b1           ;  // 寄存器写使能
                jump_addr       = 64'b0          ;  // 无跳转地址
                jump_flag       = 1'b0           ;  // 无跳转
                hold_flag       = 1'b0           ;  // 无暂停
                csr_wdata_o     = 64'b0          ;  // CSR无写数据
            end
            
            `INST_CSR:begin  // CSR指令（控制和状态寄存器操作）
                jump_addr       = 64'b0;  // 无跳转地址
                jump_flag       = 1'b0 ;  // 无跳转
                hold_flag       = 1'b0 ;  // 无暂停
                case(funct3)
                    `INST_CSRRW:begin  // CSRRW（原子读-写）
                        csr_wdata_o = op1_i      ;  // 写入CSR的值
                        reg_wdata   = csr_rdata_i;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i  ;  // 目标寄存器地址
                        reg_we      = 1'b1       ;  // 寄存器写使能
                    end
                    `INST_CSRRS:begin  // CSRRS（原子读-置位）
                        csr_wdata_o = op1_i | csr_rdata_i;  // CSR值置位
                        reg_wdata   = csr_rdata_i        ;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i          ;  // 目标寄存器地址
                        reg_we      = 1'b1               ;  // 寄存器写使能
                    end
                    `INST_CSRRC:begin  // CSRRC（原子读-清零）
                        csr_wdata_o = op1_i & (~csr_rdata_i);  // CSR值清零
                        reg_wdata   = csr_rdata_i           ;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i             ;  // 目标寄存器地址
                        reg_we      = 1'b1                  ;  // 寄存器写使能
                    end
                    `INST_CSRRWI:begin  // CSRRWI（立即数原子读-写）
                        csr_wdata_o = {59'b0,uimm};  // 立即数写入CSR
                        reg_wdata   = csr_rdata_i ;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i   ;  // 目标寄存器地址
                        reg_we      = 1'b1        ;  // 寄存器写使能
                    end
                    `INST_CSRRSI:begin  // CSRRSI（立即数原子读-置位）
                        csr_wdata_o = {59'b0,uimm} | csr_rdata_i;  // CSR值置位
                        reg_wdata   = csr_rdata_i               ;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i                 ;  // 目标寄存器地址
                        reg_we      = 1'b1                      ;  // 寄存器写使能
                    end
                    `INST_CSRRCI:begin  // CSRRCI（立即数原子读-清零）
                        csr_wdata_o = (~{59'b0,uimm}) & csr_rdata_i;  // CSR值清零
                        reg_wdata   = csr_rdata_i                  ;  // 读取的CSR值写入寄存器
                        reg_waddr   = rd_addr_i                    ;  // 目标寄存器地址
                        reg_we      = 1'b1                         ;  // 寄存器写使能
                    end
                    default:begin  // 默认情况
                        csr_wdata_o = 64'b0;  // CSR无写数据
                        reg_wdata   = 64'b0;  // 无寄存器写数据
                        reg_waddr   = 5'b0 ;  // 无寄存器写地址
                        reg_we      = 1'b0 ;  // 无寄存器写使能
                    end
                endcase
            end
            
            default:begin  // 默认情况（未定义指令）
                reg_wdata       = 64'b0;  // 无寄存器写数据
                reg_waddr       = 5'b0 ;  // 无寄存器写地址
                reg_we          = 1'b0 ;  // 无寄存器写使能
                jump_addr       = 64'b0;  // 无跳转地址
                jump_flag       = 1'b0 ;  // 无跳转
                hold_flag       = 1'b0 ;  // 无暂停
                csr_wdata_o     = 64'b0;  // CSR无写数据
            end
        endcase
    end
    
endmodule
			
			
            