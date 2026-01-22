module Dual_Port_Mem #(
    parameter ADDR_WIDTH = 13,         // 地址位宽，支持 2^10 = 1024 个地址
    parameter DATA_WIDTH = 16          // 数据位宽，例如 16 位指令或数据
)(
    input wire 					clk		,
	input wire 					rst_n	,
/*--------------portA--------------*/
	//from pc
    input  wire [ADDR_WIDTH-1:0] addr_a	,  		//pc
    //to if
	output  reg [DATA_WIDTH-1:0] dout_a ,  		//inst
	output wire [ADDR_WIDTH-1:0] pc_o	,
/*--------------portB--------------*/
	//from data_stack
    input wire [DATA_WIDTH-1:0] T		,
	input wire [DATA_WIDTH-1:0] N		,
	//from id_ex
    input wire 					mem_ren	,      	// 数据读使能
    input wire 					mem_wen	,      	// 数据写使能
	//to if
    output reg [DATA_WIDTH-1:0] dout_b			//[T]
	
	
);
    // RAM 存储体
    reg [DATA_WIDTH-1:0] register [(1 << ADDR_WIDTH)-1:0];  //位宽16，深度2^12
	
	wire [ADDR_WIDTH-1:0] addr_b_T;      // T
	wire [ADDR_WIDTH-1:0] addr_b_N;       // N
	assign addr_b_T = T[ADDR_WIDTH-1:0];
	assign addr_b_N = N[ADDR_WIDTH-1:0];
	
	assign pc_o = addr_a;
	// 加载指令
    initial begin
        $readmemh("t1.mem", register);
    end
	
/*
	integer i;
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			 for(i = 0; i < 16; i = i + 1)begin
            register[i] = 0;						//存储器初始化
        end
		else if(mem_wen)
			register[addr_b_T] <= N;				//B端口 写
	end
*/	
    // 端口A：同步读
    always @(*) begin
        dout_a <= register[addr_a];
    end

    // 端口B：同步读写
    always @(posedge clk) begin
		if(mem_wen)
			register[addr_b_T] <= N;
        else if (mem_ren)
            dout_b <= register[addr_b_T];
    end
	
	
	
endmodule

