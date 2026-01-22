`timescale 1ns/1ps

module tb_TOP_J1();
	reg clk;
    reg rst_n;
	
	TOP_J1 uut (
		.clk(clk),
		.rst_n(rst_n)
		);
    

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz 时钟


    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end

    // 4. 仿真控制
    initial begin
        // 加载波形
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_TOP_J1);

        // 运行仿真一段时间
        #2000; // 例如 2us
        $finish;
    end

endmodule
