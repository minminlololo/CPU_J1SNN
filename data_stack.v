module data_stack (
    input 					clk		,
    input 					rst_n	,	
	
	input wire [15:0]		dsk_data,
	input wire [7:0]		dsp_n	,
	input wire 				dsk_wen	,
	
	output wire [15:0]       T		,
	output wire [15:0]       N		,
	output reg [ 7:0]		dsp		,
	
	output wire 			full	,
	output wire 			empty	
);
    reg [15:0] stack [0:255];

	
	assign T = dsk_data;  // 当前栈顶地址由 dsp 提供
	assign N = stack[dsp_n-1];
	
	    // 栈指针控制逻辑
    always @(*) begin
        if (!rst_n)
            dsp <= 8'd0;
        else
            dsp <= dsp_n;  // 下一阶段传入的指针值
    end
	
    integer i;
    always@(posedge clk) 
	begin
		if (!rst_n) begin
        for (i = 0; i < 256; i = i + 1)
            stack[i] <= 16'b0;
    end
		else if (dsk_wen) 
			stack[dsp_n] <= dsk_data;
	end

    assign empty = (dsp == 0);
    assign full = (dsp == 8'd255);
endmodule


