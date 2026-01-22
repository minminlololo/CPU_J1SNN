module convolution_5x5 #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] window_in [0:24],  // 5x5 = 25个像素
    output [23:0] conv_out
    //output valid_out
);

    // 高斯核系数（已归一化，总和为256）
    localparam [7:0] KERNEL [0:24] = '{
        8'd1,  8'd4,  8'd6,  8'd4,  8'd1,
        8'd4,  8'd16, 8'd24, 8'd16, 8'd4,
        8'd6,  8'd24, 8'd36, 8'd24, 8'd6,
        8'd4,  8'd16, 8'd24, 8'd16, 8'd4,
        8'd1,  8'd4,  8'd6,  8'd4,  8'd1
    };
    
    // 第一级：25个乘法器
    wire [15:0] mult_result [0:24];
    generate
        for (genvar i = 0; i < 25; i++) begin
            assign mult_result[i] = window_in[i] * KERNEL[i];
        end
    endgenerate
    
    // 第二级：树形加法器
    wire [17:0] sum_level1 [0:11];
    generate
        for (genvar i = 0; i < 12; i++) begin
            if (i < 12)
                assign sum_level1[i] = mult_result[i*2] + mult_result[i*2+1];
        end
    endgenerate
    
    wire [18:0] sum_level2 [0:5];
    generate
        for (genvar i = 0; i < 6; i++) begin
            assign sum_level2[i] = sum_level1[i*2] + sum_level1[i*2+1];
        end
    endgenerate
    
    wire [19:0] sum_level3 [0:2];
    assign sum_level3[0] = sum_level2[0] + sum_level2[1];
    assign sum_level3[1] = sum_level2[2] + sum_level2[3];
    assign sum_level3[2] = sum_level2[4] + sum_level2[5] + mult_result[24];
    
    wire [20:0] sum_level4 = sum_level3[0] + sum_level3[1] + sum_level3[2];
    
    // 第三级：右移8位（除以256）
    assign conv_out = sum_level4[23:0] >> 8;
    //assign valid_out = 1'b1;
    
endmodule
