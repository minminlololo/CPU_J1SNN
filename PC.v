module PC
(
	input  wire        clk           ,
	input  wire        rst_n         ,
	//from ex_wb
	input  wire [12:0] jump_addr_i   ,
	input  wire        jump_flag     ,
	input  wire 	   hold_flag_i   ,//流水线暂停标志
	input  wire        call_en 		 ,// CALL指令使能
	//to if
	output reg [12:0] 	pc_o  
);
	reg [12:0] pc_count;
	// PC值计算（组合逻辑）
    always @(posedge clk) begin
		if(!rst_n)
			pc_o = pc_count;
		else if (call_en)               		// 优先级
            pc_o = jump_addr_i;      // CALL跳转到目标地址
        else if (jump_flag)             // 最低优先级
            pc_o = jump_addr_i;      // 普通跳转
        else if (hold_flag_i)    // 流水线暂停
            pc_o = pc_o;
        else
            pc_o = pc_count;   // 默认顺序执行
    end
	
	
	always @(posedge clk) begin
		if(!rst_n)
			pc_count = 13'h0000;
		else if (call_en )    
            pc_count = pc_count - 2'd10;      
		else if (jump_flag || hold_flag_i)               
            pc_count = pc_count;      
        else
            pc_count = pc_count +1'd1;     // 默认顺序执行
    end
/*	
	reg call_en_r;
	reg call_en_rr;
	always@(posedge clk)
	begin
	if(!rst_n)
		begin
		call_en_r <= 1'b0;
		call_en_rr <= 1'b0;
		end 
	else
		begin
		call_en_r <= call_en;
		call_en_rr <= call_en_r;
		end
	end
	*/
endmodule

