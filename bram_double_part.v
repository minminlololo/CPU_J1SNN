module bram_double_part #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 16   // 能覆盖 2*IMG_W*IMG_H
)(
    input  wire                     clk,

    // -------- Port A : Read --------
    input  wire                     rd_en,
    input  wire [ADDR_WIDTH-1:0]    rd_addr,
    output reg  [DATA_WIDTH-1:0]    rd_data,

    // -------- Port B : Write -------
    input  wire                     wr_en,
    input  wire [ADDR_WIDTH-1:0]    wr_addr,
    input  wire [DATA_WIDTH-1:0]    wr_data
);

    // BRAM 存储体
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Port A : 同步读
    always @(posedge clk) begin
        if (rd_en)
            rd_data <= mem[rd_addr];
    end

    // Port B : 同步写
    always @(posedge clk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

endmodule
