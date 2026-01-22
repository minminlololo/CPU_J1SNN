/*16位，7类*/
 // I type inst立即数操作，
`define INST_TYPE_I 2'b11


// R type inst 基础逻辑运算，M type inst整数乘除法扩展
///////////////////////////////////////////////
///[15:13]|[12:9]|[8:7]|
///   000 | FUNCT|FUNCT 
//////////////////////////////////////////////




`define INST_TYPE_CTRL  	3'b000
`define INST_NOP     		16'h0000	 //空操作
// M 0:PROPRESS 1:SNN
`define START_PRE	        4'b0001		//启动图像预处理
`define START_ENC		    4'b0010  	//启动脉冲编码模块
`define START_SNN    	    4'b0011		//启动SNN推理计算
`define CLEAR		        4'b0100		//清除硬件状态
`define WAIT_SNN			4'b0101      
`define OUTPUT_SNN			4'b0110

`define ENCODE_POISSON		2'b01		//泊松编码
`define ENCODE_RATE 		2'b10       //频率编码
`define ENCODE_HYBRID		2'b11		//混合编码


// STACK inst
`define INST_TYPE_STA   3'b001

`define INST_PUSH  		4'b0001
`define INST_POP   		4'b0010
`define INST_DUP   		4'b0011  //复 制栈顶
`define INST_DROP  		4'b0100  //丢弃栈顶元素
`define INST_SWAP  		4'b0101	 //交换栈顶元素
`define INST_OVER  		4'b0110  //复制次栈顶元素到顶部
`define INST_NIP   		4'b0111	 //删除次栈顶

// L type inst加载指令，用于从内存中加载数据到寄存器
`define INST_TYPE_L 3'b0010
`define INST_LW     1'b0//加载字

`define INST_SW     1'b1//存储字

// J type inst  分支指令
`define INST_TYPE_J    3'b011      //无条件跳转
//CJ	条件跳转	
`define INST_TYPE_CJ   3'b100		//栈顶值为0跳转
//Call
`define INST_TYPE_CALL 3'b101		//调用程序
// `define INST_IRET    4'b0100		//中断返回
	

