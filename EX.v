`include "D:\FPGA\Code\J1Sc\ZP2\defines.v"

module EX#(
    parameter ADDR_WIDTH = 13,       // 指令地址宽度，最大支持 8KB ROM
    parameter DATA_WIDTH = 16
)
(	
	//from id_ex		
	input wire [DATA_WIDTH-1:0] inst                ,		 
	input wire [ADDR_WIDTH-1:0] inst_addr           ,	
	input wire [3:0]  			sel                 ,		   
	input wire [DATA_WIDTH-1:0] Immediate           ,      
	input wire 		  			return_alu          ,	           	         
//	input wire [3:0]  			stack_alu           ,  // alu 0~3控制data/return栈更新逻辑(stack_ex)
	input wire [3:0]  			funct_op            , 
	input wire [1:0]			enc_sel				,
    input wire  	  			mix_alu             ,	      // alu 4~7
	input wire [ADDR_WIDTH-1:0] target              ,	
	input wire [DATA_WIDTH-1:0] T_m                 ,		
	//from data_stack		
	input wire [7:0]  			dsp					,
	input wire [DATA_WIDTH-1:0] T					,
	input wire [DATA_WIDTH-1:0] N					,
	
	//from return_stack		
	input wire [7:0]  			rsp					,
	input wire [DATA_WIDTH-1:0] R					,
	
	//from pc
 //   input  wire [DATA_WIDTH-1:0]	pc_ex			,       // 当前PC值

	//to multiplie	
	output reg  [3 :0] 				alu_type		,
		
	//to ex/wb				
	output reg  [7 :0] 				dsp_n			,
	output reg  [7 :0] 				rsp_n			,
	output reg         				dsk_wen			,
	output reg 		   				rsk_wen			,
	output reg  [DATA_WIDTH-1:0] 	rsk_data		,
	output reg  [DATA_WIDTH-1:0] 	dsk_data		,
	//to pc	
	output reg  [ADDR_WIDTH-1:0] 	jump_addr		,
	output reg         				jump_flag		,
	output reg         				call_en			,
	//to mem				
	output reg  	   				mem_ren			,
	output reg 		   				mem_wen			,
					
	output reg		   				hold_flag		,
	
	output reg 						enc_sel_o		,
	// output reg 						pre_start 		,
	// output reg 						enc_start 		,
	// output reg 						snn_start 		,
	output reg 						clear	  		,
	output reg 						wait_snn  		,
	output reg 						output_snn		,
	output reg						ctrl_valid		,
	output wire [3:0] 				funct_op_o
	);
	
	reg  [DATA_WIDTH-1:0] 			result_alu;
	wire [DATA_WIDTH-1:0] 			op1;
	wire [DATA_WIDTH-1:0] 			op2;
	
	assign op1 = T;
	assign op2 = N;
	
	assign funct_op_o  = funct_op;
	

/*--------------计算控制单元----------------*/
	always@(*)begin
		if(!rst_n)begin
			// pre_start  = 1'b0;
			// enc_start  = 1'b0;
			// snn_start  = 1'b0;
			clear	   = 1'b0;
			wait_snn   = 1'b0;
			output_snn = 1'b0;
			ctrl_valid = 1'b0;
			enc_sel_o  = 2'b0;
		end
		else if(sel == 4'b0001 && mix_alu == 1'b1 )begin
			case(funct_op)begin
			`START_PRE  : begin 
				ctrl_valid  = 1'b1;
			
			`START_ENC  : begin
				ctrl_valid  = 1'b1;
				enc_sel_o   = enc_sel;
			end
			`START_SNN  : begin
				ctrl_valid  = 1'b1;
			end
			`CLEAR	    : begin 
				clear      = 1'b1;
			end
			`WAIT_SNN   : begin 
				wait_snn   = 1'b1;
			end
			`OUTPUT_SNN : begin 
				output_snn = 1'b1;
			end
			default:begin
				// pre_start  = 1'b0;
				// enc_start  = 1'b0;
				// snn_start  = 1'b0;
				 clear	   = 1'b0;
				wait_snn   = 1'b0;
				output_snn = 1'b0;
				ctrl_valid = 1'b0;
				enc_sel_o  = 2'b0;
			end
		   end
		  endcase
		end
		else begin
				// pre_start  = 1'b0;
				// enc_start  = 1'b0;
				// snn_start  = 1'b0;
				clear	   = 1'b0;
				wait_snn   = 1'b0;
				output_snn = 1'b0;
				enc_sel_o  = 2'b0;
		end
	end

	
	
/*--------------堆栈操作单元----------------*/
    always@(*) begin   // 控制data栈指针的更新
	case(sel)
		4'b0001:dsp_n = dsp_add;	//立即数
		4'b0010:begin  	//alu
			case (stack_alu[1:0]) 
				2'b00: dsp_n = dsp;
				2'b01: dsp_n = dsp_add;
				2'b10: dsp_n = dsp_sub;
				default: dsp_n = dsp;
			endcase
			end
		4'b0011:begin		//栈操作
				case(funct_op)
				`INST_PUSH : dsp_n = dsp_add;
				`INST_POP  : dsp_n = dsp_sub;
				`INST_DUP  : dsp_n = dsp_add;
				`INST_DROP : dsp_n = dsp_sub;
				`INST_SWAP : dsp_n = dsp;
				`INST_OVER : dsp_n = dsp_add;
				`INST_NIP  : dsp_n = dsp - 5'd2;
				default: dsp_n = dsp;
				endcase
				end
		4'b0100:dsp_n = dsp;		//加载
		4'b0101:dsp_n = dsp;        //J
		4'b0110:dsp_n = dsp_sub;    //CJ
		4'b0111:dsp_n = dsp;		//Call
		default:dsp_n = dsp;
	endcase
    end

	always@(*) begin   // 控制returm栈指针的更新
	case(sel)
		4'b0000:rsp_n = rsp;		//立即数
		4'b0001:begin  	//alu_r,m
        case (stack_alu[3:2])
            2'b01: rsp_n = rsp_add;
            2'b10: rsp_n = rsp_sub;
            default: rsp_n = rsp;
        endcase
		end
		4'b0011:rsp_n = rsp;		//栈操作
		4'b0100:rsp_n = rsp;		//加载
		4'b0101:rsp_n = rsp;        //J
		4'b0110:rsp_n = rsp;    	//CJ
		4'b0111:rsp_n = rsp_add;	//Call
		default: rsp_n = rsp;
	endcase	
    end

    // 写入return栈的数据
    always@(*)
	begin
		case(sel)
			4'b0010:begin  	//alu_r,m
			if(mix_alu[2])
				rsk_data = T;
			end
			4'b0111:rsk_data = inst_addr + 16'd1; // Call类，PC是字节地址
		default:rsk_data = {DATA_WIDTH{1'b0}};
        endcase
    end
	
	
	//写入data栈的数据
	always@(*)
	begin
		case(sel)
			4'b0001:dsk_data = Immediate;
			4'b0010:dsk_data = result_alu;
			4'b0011:begin
					case(funct_op)
					`INST_DUP  : dsk_data = T;
					`INST_OVER : dsk_data = N;
					`INST_NIP  : dsk_data = T;
					default:dsk_data = T;
					endcase
				end
			default:dsk_data = T;
		endcase		
	end

	// R栈写使能逻辑
    always@(*)
	begin
		case(sel)
		4'b0001:rsk_wen = 1'b0;		//立即数
		4'b0010:begin  	//alu_r,m
			if(mix_alu[2])
				rsk_wen = 1'b1;
			end
		4'b0111:rsk_wen = 1'b1; //Call
		default:rsk_wen = 1'b0;
		endcase
    end

	// D栈写使能逻辑
    always@(*)
	begin
		case(sel)
		4'b0001:dsk_wen = 1'b1;		//立即数
		4'b0010:begin  	   //alu_r,m
			case (mix_alu[3])
				1'b1: dsk_wen = 1'b1;
				default: dsk_wen = 1'b0;
			endcase
			end
		default:dsk_wen = 1'b0;
		endcase
    end
/*----------------控制单元----------------*/
	
	always@(*)
	begin
		if(sel == 4'b0010)//alu_r
			if(return_alu== 1'b1)
				jump_flag = 1'b1;
			else 
				jump_flag = 1'b0;
		else if(sel == 4'b0101) //Jump
			jump_flag = 1'b1;
		else if(sel == 4'b0110)//CJump
			if(T == 0)
				jump_flag = 1'b1;
			else 
				jump_flag = 1'b0;
		else if(sel == 4'b0111)//Call
			jump_flag = 1'b1;
		else 
			jump_flag = 1'b0;
	end
	
	always@(*)
	begin
		if(sel == 4'b0010)//alu_r
			if(return_alu== 1'b1)
				jump_addr = R[12:0];
			else 
				jump_addr = {ADDR_WIDTH{1'b0}};
		else if(sel == 4'b0101) //Jump
			jump_addr = target;
		else if(sel == 4'b0110)//CJump
			if(T == 0)
				jump_addr = target;
			else 
				jump_addr = {ADDR_WIDTH{1'b0}};
		else if(sel == 4'b0111)//Call
			jump_addr = target;
		 
		else 
			jump_addr = {ADDR_WIDTH{1'b0}};
	end
	
	always@(*)
	begin
		if(sel == 4'b0111)
			call_en = 1'b1;
		else 
			call_en = 1'b0;
	end
	
	always@(*)
	begin  +
		if(sel == 4'b0101)  //Jump
			hold_flag = 1'b1;
		else if (sel == 4'b0110)  //CJump
			if(T == 0)
				hold_flag = 1'b1;
			else 
				hold_flag = 1'b0;
		else if (sel == 4'b0111) //Call
			hold_flag = 1'b0;
		else 
			hold_flag = 1'b0;
	end
	
	//数据存储端口读写使能
	always@(*)
	begin
		if(sel == 4'b0010)
			mem_ren = mix_alu[0];
		else 
			mem_ren = 1'b0;
	end
	
	always@(*)
	begin
		if(sel == 4'b0010)
			mem_wen = mix_alu[1];
		else 
			mem_wen = 1'b0;
	end
/*-------------乘法器设计-----------------*/
	wire [15:0] product;
	mul_tc_16_16 mul_tc_16_16_0 (
    .a      (op1)   ,	//输入数据，二进制补码
    .b      (op2)   ,	//输入数据，二进制补码
    .product(product)   //输出乘积a * b，二进制补码
);
CPU_SNN_Interface CPU_SNN_Interface_inst#(
	.ADDR_WIDTH(13),       // 指令地址宽度，最大支持 8KB ROM
	.DATA_WIDTH(16)
	) 
	(
    .clk			()		,
    .rst_n			()		,
	.T				()		,
	.N				()		,
    //请求通道 ---  ()
    .cpu_req_valid	()		,		//CPU-->SNN发送计算请求信号
    .cpu_req_ready	()		,		//SNN-->CPU返回可以接收信号
    .req_rs1		()		,
	.req_rs2		()		,
					()
    //反馈通道 ---  ()
	.snn_done		()		,    	//返回计算完成标志
	.snn_result		()		, 		//snn计算结果
	.rsp_err		()		,		//返回该指令的错误标志
	.snn_rsp_valid	()		,		//SNN-->CPU准备发送结果信号
	.snn_rsp_ready	()		,  		//CPU-->SNN接收接收结果信号
	.cpu_resp_data  ()
	// 如果需要，接口可以告诉 CPU 在请求被采样时应该从栈弹出多少个元素
    // 例如：snn 参数来自 T/N => pop_count = 2；这里用 2bit 能表示 0~3
	//output reg [1:0]              cpu_req_pop_cnt  // 建议 CPU 弹出参数个数（仅建议）
);
endmodule