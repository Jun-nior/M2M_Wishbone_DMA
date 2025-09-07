/*
 * Module: wishbone_interconnect
 * Version: 2 (Final - Multi-Master with Arbiter)
 * Description: A Wishbone interconnect that connects two masters (CPU, DMA) to two slaves
 * (BRAM, DMA_CSR). It includes a fixed-priority arbiter to handle
 * concurrent access requests to the slaves.
 */
module wishbone_interconnect #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    // Slave 0: BRAM
    parameter S0_ADDR_BASE = 32'h0000_0000,
    parameter S0_ADDR_END  = 32'h0000_FFFF, // 64KB space for RAM

    // Slave 1: DMA Controller Registers (CSR)
    parameter S1_ADDR_BASE = 32'h8000_0000,
    parameter S1_ADDR_END  = 32'h8000_001F  // 32 bytes for CSR
) (
    input  logic i_clk,
    input  logic i_rst_n,

    // --- Slave Ports (from Masters) ---
    rggen_wishbone_if.slave  cpu_s_wb_if, // From CPU (Master 0, higher priority)
    rggen_wishbone_if.slave  dma_s_wb_if,  // From DMA (Master 1, lower priority)

    // --- Master Ports (to Slaves) ---
    rggen_wishbone_if.master bram_m_wb_if, // To BRAM (Slave 0)
    rggen_wishbone_if.master csr_m_wb_if,   // To DMA_CSR (Slave 1)

    // --- Extra port ---
    input  logic [2:0] state,
    input  logic master_c,
    output logic master
);

    logic cpu_request, dma_request;
    logic cpu_grant,   dma_grant;
    logic grant_lock;
    logic transaction_done;

    logic [ADDR_WIDTH-1:0] selected_addr;
    logic [DATA_WIDTH-1:0] selected_dat_w;
    logic                  selected_we;
    logic [3:0]            selected_sel;
    logic                  selected_cyc;
    logic                  selected_stb;

    logic bram_selected;
    logic csr_selected;

    assign cpu_request = cpu_s_wb_if.cyc && cpu_s_wb_if.stb;
    assign dma_request = dma_s_wb_if.cyc && dma_s_wb_if.stb;
    
    assign cpu_grant =  grant_lock ? 
                        ((cpu_s_wb_if.we == 0 && (state == 2 || state == 3))
                        || cpu_s_wb_if.we == 1 && (state == 4 || state == 5)) ? 0 : (cpu_request && !dma_grant) : cpu_request;
    assign dma_grant =  grant_lock ? (dma_request && !cpu_grant) : (dma_request && !cpu_request);

    always_latch begin
        if (!i_rst_n) begin
            grant_lock <= 1'b0;
        end else if (cpu_grant || dma_grant) begin
            grant_lock <= 1'b1;
        end else if (transaction_done) begin
            grant_lock <= 1'b0;
        end
    end

    // Select the signals from the granted master to be forwarded to the slaves.
    always_comb begin
        if (cpu_grant) begin
            selected_addr  = cpu_s_wb_if.adr;
            selected_dat_w = cpu_s_wb_if.dat_w;
            selected_we    = cpu_s_wb_if.we;
            selected_sel   = cpu_s_wb_if.sel;
            selected_cyc   = cpu_s_wb_if.cyc;
            selected_stb   = cpu_s_wb_if.stb;
        end else if (dma_grant) begin
            selected_addr  = dma_s_wb_if.adr;
            selected_dat_w = dma_s_wb_if.dat_w;
            selected_we    = dma_s_wb_if.we;
            selected_sel   = dma_s_wb_if.sel;
            selected_cyc   = dma_s_wb_if.cyc;
            selected_stb   = dma_s_wb_if.stb;
        end else begin
            selected_addr  = '0;
            selected_dat_w = '0;
            selected_we    = 1'b0;
            selected_sel   = '0;
            selected_cyc   = 1'b0;
            selected_stb   = 1'b0;
        end
    end

    assign bram_selected = (selected_addr >= S0_ADDR_BASE) && (selected_addr <= S0_ADDR_END);
    assign csr_selected  = (selected_addr >= S1_ADDR_BASE) && (selected_addr <= S1_ADDR_END);

    // Forward the selected master's request to the correct slave.
    assign bram_m_wb_if.cyc   = selected_cyc && bram_selected;
    assign bram_m_wb_if.stb   = selected_stb && bram_selected;
    assign bram_m_wb_if.we    = selected_we;
    assign bram_m_wb_if.adr   = selected_addr;
    assign bram_m_wb_if.dat_w = selected_dat_w;
    assign bram_m_wb_if.sel   = selected_sel;

    assign csr_m_wb_if.cyc   = selected_cyc && csr_selected;
    assign csr_m_wb_if.stb   = selected_stb && csr_selected;
    assign csr_m_wb_if.we    = selected_we;
    assign csr_m_wb_if.adr   = selected_addr;
    assign csr_m_wb_if.dat_w = selected_dat_w;
    assign csr_m_wb_if.sel   = selected_sel;

    // Route the response from the active slave back to the correct master. (not use)
    // logic slave_ack, slave_err;
    // logic [DATA_WIDTH-1:0] slave_dat_r;

    // assign slave_ack   = (bram_m_wb_if.ack && bram_selected) || (csr_m_wb_if.ack && csr_selected);
    // assign slave_dat_r = (bram_selected) ? bram_m_wb_if.dat_r : csr_m_wb_if.dat_r;
    // assign slave_err   = ((bram_m_wb_if.err && bram_selected) || (csr_m_wb_if.err && csr_selected)) ||
    //                      (selected_stb && !bram_selected && !csr_selected);

    // assign cpu_s_wb_if.ack   = slave_ack && cpu_grant;
    // assign cpu_s_wb_if.dat_r = slave_dat_r;
    // assign cpu_s_wb_if.err   = slave_err && cpu_grant;

    // assign dma_s_wb_if.ack   = slave_ack && dma_grant;
    // assign dma_s_wb_if.dat_r = slave_dat_r;
    // assign dma_s_wb_if.err   = slave_err && dma_grant;

    always_comb begin
        cpu_s_wb_if.ack   = 0;
        cpu_s_wb_if.dat_r = 0;
        cpu_s_wb_if.err   = 0;

        dma_s_wb_if.ack   = 0;
        dma_s_wb_if.dat_r = 0;
        dma_s_wb_if.err   = 0;
        
        if (cpu_grant) begin
            if (bram_selected) begin
                cpu_s_wb_if.ack   = (master == 0) ? bram_m_wb_if.ack : 0;
                cpu_s_wb_if.dat_r = (master == 0) ? bram_m_wb_if.dat_r : 0;
                cpu_s_wb_if.err   = (master == 0) ? bram_m_wb_if.err : 0;
            end else if (csr_selected) begin
                cpu_s_wb_if.ack   = csr_m_wb_if.ack;
                cpu_s_wb_if.dat_r = csr_m_wb_if.dat_r;
                cpu_s_wb_if.err   = csr_m_wb_if.err;
            end else begin
                // Address decode error for CPU
                cpu_s_wb_if.err = cpu_request;
            end
        end else if (dma_grant) begin
            if (bram_selected) begin
                dma_s_wb_if.ack   = (master == 1) ? bram_m_wb_if.ack : 0;
                dma_s_wb_if.dat_r = (master == 1) ? bram_m_wb_if.dat_r : 0;
                dma_s_wb_if.err   = (master == 1) ? bram_m_wb_if.err : 0;
            end else begin
                // Address decode error for DMA
                dma_s_wb_if.err = dma_request;
            end
        end
    end
    
    // assign transaction_done = slave_ack || slave_err;
    assign transaction_done = (cpu_grant && (cpu_s_wb_if.ack || cpu_s_wb_if.err)) ||
                              (dma_grant && (dma_s_wb_if.ack || dma_s_wb_if.err));

    assign master = (cpu_grant) ? 0 : (dma_grant) ? 1 : 0;
endmodule

