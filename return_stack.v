module return_stack (
    input 					clk		,
    input 					rst_n	,	
	
	input wire [15:0]		rsk_data,
	input wire [7:0]		rsp_n	,
	input wire 				rsk_wen	,
	
	output wire [15:0]       R		,
	output reg [ 7:0]		rsp		,
	output wire 			full	,
	output wire 			empty	
);
    reg [15:0] stack [0:255];


	assign R = rsk_data;  // 当前栈顶地址由 rsp 提供
	
	    // 栈指针控制逻辑
    always @(*) begin
        if (!rst_n)
            rsp <= 6'd0;
        else
            rsp <= rsp_n;  // 下一阶段传入的指针值
    end
	
	integer i;
    always@(posedge clk) 
	begin
		if (!rst_n) begin
        for (i = 0; i < 256; i = i + 1)
            stack[i] <= 16'b0;
    end
		else if (rsk_wen) 
			stack[rsp_n] <= rsk_data;
	end

	assign empty = (rsp == 0);
    assign full = (rsp == 8'd255);
	
endmodule


