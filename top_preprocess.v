module top_preprocess #(
    parameter IMG_WIDTH = 28,
    parameter IMG_HEIGHT = 28,
    parameter P_PIXEL_INTENSITY_BITS = 8,
    parameter P_IMAGE_BRAM_DATA_WIDTH = 64
)(
    input  wire         clk,
    input  wire         rst_n,

    input  wire         start,
    output wire         done,

    // DDR3 AXI（只写）
    output wire [31:0]  axi_awaddr,
    output wire [31:0]  axi_wdata,
    output wire         axi_wvalid
);

    localparam IMG_PIXELS = IMG_WIDTH * IMG_HEIGHT;
    localparam PIXELS_PER_BRAM_WORD =
        P_IMAGE_BRAM_DATA_WIDTH / P_PIXEL_INTENSITY_BITS;
    localparam IMAGE_BRAM_DEPTH =
        (IMG_PIXELS + PIXELS_PER_BRAM_WORD - 1) / PIXELS_PER_BRAM_WORD;
    localparam BRAM_ADDR_WIDTH = $clog2(IMAGE_BRAM_DEPTH);
    localparam IMG_ADDR_WIDTH  = $clog2(IMG_PIXELS);
    localparam [IMG_ADDR_WIDTH-1:0] IMG_ADDR_MAX = IMG_PIXELS - 1;

    assign axi_awaddr = 32'b0;
    assign axi_wdata  = 32'b0;
    assign axi_wvalid = 1'b0;

    /**********************************************
     * 0. Image BRAM（photo.coe）
     **********************************************/
    wire [BRAM_ADDR_WIDTH-1:0] bram_addr;
    wire                       bram_ena;
    wire [P_IMAGE_BRAM_DATA_WIDTH-1:0] bram_dout_raw;

    image_mem u_image_bram (
        .clka  (clk),
        .ena   (bram_ena),
        .addra (bram_addr),
        .douta (bram_dout_raw)
    );

    // -------------------------------------
    // 1. Image Loader
    // -------------------------------------
    wire load_image_start;
    wire [IMG_PIXELS-1:0][P_PIXEL_INTENSITY_BITS-1:0] image_buffer_out;
    wire loading_busy;
    wire load_done;

    assign load_image_start = start;

    image_loader #(
        .P_NUM_INPUT_PIXELS      (IMG_PIXELS),
        .P_PIXEL_INTENSITY_BITS  (P_PIXEL_INTENSITY_BITS),
        .P_IMAGE_BRAM_DATA_WIDTH (P_IMAGE_BRAM_DATA_WIDTH),
        .P_IMAGE_BRAM_DEPTH      (IMAGE_BRAM_DEPTH)
    ) u_image_loader (
        .clk                (clk),
        .rst_n              (rst_n),
        .i_load_image_start (load_image_start),
        .i_bram_dout_raw    (bram_dout_raw),
        .o_bram_addr        (bram_addr),
        .o_bram_ena         (bram_ena),
        .o_image_buffer_out (image_buffer_out),
        .o_loading_busy     (loading_busy),
        .o_load_done        (load_done)
    );

    /**********************************************
     * 2. weight Loader
     **********************************************/
    wire [15:0] weight_data;
    wire [15:0] weight_addr;

    weight_bram u_weight_bram (
        .clka (clk),
        .ena  (1'b1),
        .addra(weight_addr),
        .douta(weight_data)
    );

    /**********************************************
     * 3. Frame Reader (from image buffer)
     **********************************************/
    wire rd_en;
    wire [IMG_ADDR_WIDTH-1:0] rd_addr;
    wire [P_PIXEL_INTENSITY_BITS-1:0] rd_data;

    wire [IMG_ADDR_WIDTH-1:0] img_rd_index;
    assign img_rd_index = IMG_ADDR_MAX - rd_addr;
    assign rd_data = image_buffer_out[img_rd_index];

    wire [P_PIXEL_INTENSITY_BITS-1:0] pixel_in;
    wire pixel_valid;
    wire line_end;
    wire frame_end;

    frame_reader #(
        .IMG_WIDTH  (IMG_WIDTH),
        .IMG_HEIGHT (IMG_HEIGHT),
        .ADDR_WIDTH (IMG_ADDR_WIDTH)
    ) u_frame_reader (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (load_done),
        .rd_en       (rd_en),
        .rd_addr     (rd_addr),
        .rd_data     (rd_data),
        .pixel_out   (pixel_in),
        .pixel_valid (pixel_valid),
        .line_end    (line_end),
        .frame_end   (frame_end)
    );

    /**********************************************
     * 4. Gaussian Preprocess
     **********************************************/
    wire [P_PIXEL_INTENSITY_BITS-1:0] gauss_out;
    wire gauss_valid;
    wire gauss_line_end;
    wire gauss_frame_end;

    gaussian_filter #(
        .IMG_WIDTH  (IMG_WIDTH),
        .IMG_HEIGHT (IMG_HEIGHT),
        .DATA_WIDTH (P_PIXEL_INTENSITY_BITS)
    ) u_gaussian (
        .clk            (clk),
        .rst_n          (rst_n),
        .pixel_in       (pixel_in),
        .pixel_valid    (pixel_valid),
        .line_end       (line_end),
        .frame_end      (frame_end),
        .pixel_out      (gauss_out),
        .pixel_valid_out(gauss_valid),
        .line_end_out   (gauss_line_end),
        .frame_end_out  (gauss_frame_end)
    );

    /**********************************************
     * 5. Gaussian Output Buffer
     **********************************************/
    reg [IMG_ADDR_WIDTH-1:0] gauss_wr_addr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gauss_wr_addr <= {IMG_ADDR_WIDTH{1'b0}};
        else if (gauss_frame_end)
            gauss_wr_addr <= {IMG_ADDR_WIDTH{1'b0}};
        else if (gauss_valid)
            gauss_wr_addr <= gauss_wr_addr + 1'b1;
    end

    wire [P_PIXEL_INTENSITY_BITS-1:0] gauss_rd_data;
    bram_double_part #(
        .DATA_WIDTH (P_PIXEL_INTENSITY_BITS),
        .ADDR_WIDTH (IMG_ADDR_WIDTH)
    ) u_gauss_bram (
        .clk     (clk),
        .rd_en   (1'b0),
        .rd_addr ({IMG_ADDR_WIDTH{1'b0}}),
        .rd_data (gauss_rd_data),
        .wr_en   (gauss_valid),
        .wr_addr (gauss_wr_addr),
        .wr_data (gauss_out)
    );

    assign done = gauss_frame_end;

endmodule
