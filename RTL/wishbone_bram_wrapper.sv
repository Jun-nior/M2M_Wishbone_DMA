/*
 * Module: bram_wishbone_wrapper
 * Description: A wrapper that provides a Wishbone slave interface to a simple
 * single-port BRAM core. It translates Wishbone transactions
 * into the simple read/write signals required by the BRAM.
 */
module bram_wishbone_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32, // System-level address width from the bus
    parameter BRAM_ADDR_WIDTH = 14  // Internal address width of the BRAM core (for 64KB)
) (
    input  logic i_clk,
    input  logic i_rst_n,

    // Wishbone Slave Interface (connects to the interconnect)
    rggen_wishbone_if.slave wb_if,

    // Extra Input 
    input  logic master,
    output logic master_c
);

    logic [BRAM_ADDR_WIDTH - 1 : 0] bram_addr;
    logic                           master_reg;
    logic [DATA_WIDTH/8-1:0]        bram_we;

    assign bram_we = { (DATA_WIDTH/8){wb_if.cyc && wb_if.stb && wb_if.we} } & wb_if.sel;
    assign bram_addr = wb_if.adr[BRAM_ADDR_WIDTH + 1 : 2];

    bram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(BRAM_ADDR_WIDTH)
    ) u_bram (
        .clk    (i_clk),
        .addr   (bram_addr),
        .w_en   (bram_we),
        .wdata  (wb_if.dat_w),
        .rdata  (wb_if.dat_r) 
    );

    logic ack_reg;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            ack_reg <= 0;
        end else begin
            ack_reg <= wb_if.cyc && wb_if.stb;
            master_reg <= master;
        end
    end

    assign wb_if.ack = ack_reg;
    assign master_c = master_reg; // give correct respond to a master
    assign wb_if.err = 0; // This simple slave never generates an error

endmodule

