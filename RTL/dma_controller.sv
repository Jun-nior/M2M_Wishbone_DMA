/*
 * Module: dma_controller
 * Description: The top-level DMA controller module that integrates the CSR block,
 * the core FSM, and the Wishbone master agent.
 */
module dma_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter LEN_WIDTH  = 16
) (
    input  logic i_clk,
    input  logic i_rst_n,

    // Interconnect -> DMA
    rggen_wishbone_if.slave s_wb_if,

    // DMA -> Interconnect
    rggen_wishbone_if.master m_wb_if,

    output logic [2:0]  state
);

    // CSR - FSM
    logic                  csr_go;
    logic                  csr_ie;
    logic [ADDR_WIDTH-1:0] csr_src_addr;
    logic [ADDR_WIDTH-1:0] csr_dest_addr;
    logic [LEN_WIDTH-1:0]  csr_len;
    logic                  fsm_busy;
    logic                  fsm_done_if_set;
    logic                  fsm_done_if_state;
    logic                  fsm_clear_go_enable;
    logic                  fsm_clear_go_data;

    // FSM - WB_Agent
    logic                  fsm_agent_start;
    logic                  fsm_agent_we;
    logic [ADDR_WIDTH-1:0] fsm_agent_addr;
    logic [DATA_WIDTH-1:0] fsm_agent_wdata;
    logic                  agent_fsm_done;
    logic [DATA_WIDTH-1:0] agent_fsm_rdata;

    DMA_CSR dut_dma_csr (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .wishbone_if(s_wb_if), 
        
        .o_SOURCE_ADDR_REG_addr(csr_src_addr),
        .o_DEST_ADDR_REG_addr(csr_dest_addr),
        .o_LENGTH_REG_len(csr_len),
        .i_CONTROL_REG_go_hw_write_enable(fsm_clear_go_enable),
        .i_CONTROL_REG_go_hw_write_data(fsm_clear_go_data),
        .o_CONTROL_REG_go(csr_go),
        .o_CONTROL_REG_ie(csr_ie),
        
        .i_STATUS_REG_busy(fsm_busy),
        .i_STATUS_REG_done_if_set(fsm_done_if_set),
        .o_STATUS_REG_done_if(fsm_done_if_state) // later use for interrupt logic at the system-level
    );

    dma_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .LEN_WIDTH (LEN_WIDTH)
    ) dut_dma_fsm (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_go(csr_go),
        .i_src_addr(csr_src_addr),
        .i_dest_addr(csr_dest_addr),
        .i_len(csr_len),
        .o_busy(fsm_busy),
        .o_done_if_set(fsm_done_if_set),
        .o_go_hw_we(fsm_clear_go_enable),
        .o_clear_go(fsm_clear_go_data),
        
        .o_start(fsm_agent_start),
        .o_we(fsm_agent_we),
        .o_addr(fsm_agent_addr),
        .o_wdata(fsm_agent_wdata),
        .i_done(agent_fsm_done),
        .i_rdata(agent_fsm_rdata)
    );

    assign state = dut_dma_fsm.current_state;

    wishbone_master_agent #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut_wb_master_agent (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(fsm_agent_start),
        .i_we(fsm_agent_we),
        .i_addr(fsm_agent_addr),
        .i_wdata(fsm_agent_wdata),
        .o_busy(), // Not use yet
        .o_rdata(agent_fsm_rdata),
        .o_done(agent_fsm_done),
        .wb_if(m_wb_if) 
    );

endmodule
