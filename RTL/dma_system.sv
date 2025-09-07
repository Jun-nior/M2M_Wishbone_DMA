/*
 * Module: dma_system
 * Description: The top-level system module that integrates all components:
 * - The DMA Controller
 * - The BRAM with its Wishbone wrapper
 * - The multi-master Wishbone Interconnect
 * It exposes a single Wishbone slave port for the CPU and an interrupt line.
 */
module dma_system #(
    parameter DATA_WIDTH      = 32,
    parameter ADDR_WIDTH      = 32,
    parameter BRAM_ADDR_WIDTH = 14  
) (
    input  logic i_clk,
    input  logic i_rst_n,

    // Interface for the CPU/Testbench to control the system
    rggen_wishbone_if.slave  cpu_wb_if,

    // Interrupt output from the DMA
    output logic             o_dma_interrupt
);

    rggen_wishbone_if #(ADDR_WIDTH, DATA_WIDTH) dma_to_interconnect_if();
    rggen_wishbone_if #(ADDR_WIDTH, DATA_WIDTH) interconnect_to_bram_if();
    rggen_wishbone_if #(ADDR_WIDTH, DATA_WIDTH) interconnect_to_csr_if();


    logic master, master_c;
    logic [2:0] state;

    wishbone_interconnect #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut_interconnect (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        
        .cpu_s_wb_if(cpu_wb_if),
        .dma_s_wb_if(dma_to_interconnect_if),

        .bram_m_wb_if(interconnect_to_bram_if),
        .csr_m_wb_if(interconnect_to_csr_if),

        .state(state),
        .master(master),
        .master_c(master_c)
    );


    dma_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut_dma_controller (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        
        // The slave port connects to the interconnect's master port for CSR
        .s_wb_if(interconnect_to_csr_if),
        
        // The master port connects to the interconnect's slave port for DMA
        .m_wb_if(dma_to_interconnect_if),

        .state(state)
    );


    bram_wishbone_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH)
    ) u_bram_wrapper (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        
        // The slave port connects to the interconnect's master port for BRAM
        .wb_if(interconnect_to_bram_if),
        .master(master),
        .master_c(master_c)
    );
    
    
    // The final interrupt signal is generated only when the DMA's interrupt flag is set AND the interrupt is enabled in the control register.
    
    logic dma_interrupt_flag;
    logic dma_interrupt_enable;
    
    // update later the output ports
    assign dma_interrupt_flag   = dut_dma_controller.dut_dma_csr.o_STATUS_REG_done_if;
    assign dma_interrupt_enable = dut_dma_controller.dut_dma_csr.o_CONTROL_REG_ie;
    
    assign o_dma_interrupt = dma_interrupt_flag && dma_interrupt_enable;

endmodule
