`timescale 1ns/1ps
`include "rggen_rtl_pkg.sv"

//##############################################################################
// Testbench Top for the complete dma_system
//##############################################################################
module dma_system_tb_top;

    logic i_clk;
    logic i_rst_n;

    logic dma_interrupt;

    rggen_wishbone_if #(
        .ADDRESS_WIDTH(32),
        .DATA_WIDTH   (32)
    ) cpu_wb_if();

    dma_system u_dut (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .cpu_wb_if      (cpu_wb_if),
        .o_dma_interrupt(dma_interrupt)
    );

    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; 
    end

    initial begin
        logic [31:0] read_data;
        logic [31:0] addr;
        localparam SRC_ADDR  = 32'h0000_0000;
        localparam DEST_ADDR = 32'h0000_1000;
        localparam LENGTH    = 64;
        localparam CPU_TEST_ADDR = 32'h0000_4000;

        $display("INFO: Starting DMA System integration test...");

        i_rst_n <= 1'b0;
        repeat (5) @(posedge i_clk);
        i_rst_n <= 1'b1;
        @(posedge i_clk);
        $display("%t INFO: Reset complete.", $time);
        // --- SETUP PHASE: Pre-load source memory and clear destination ---
        $display("%t INFO: Pre-loading source data into BRAM...", $time);
        for (int i = 0; i < LENGTH; i++) begin
            wishbone_write(SRC_ADDR + (i*4), 32'(i + 1));
            wishbone_write(DEST_ADDR + (i*4), 32'hDEADBEEF); // Fill dest with garbage
        end
        $display("%t INFO: Memory setup complete.", $time);
        wishbone_write(CPU_TEST_ADDR, 32'hAAAAAAAA);

        // --- ACTION PHASE: Configure and start the DMA ---
        $display("%t INFO: Configuring DMA for a %0d-word transfer.", $time, LENGTH);
        wishbone_write(32'h8000_0000, SRC_ADDR);  // Write Source Address
        wishbone_write(32'h8000_0004, DEST_ADDR); // Write Destination Address
        wishbone_write(32'h8000_0008, LENGTH);    // Write Length
        wishbone_write(32'h8000_000C, 32'h1);     // Set 'go' bit
        $display("%t INFO: DMA started.", $time);

        // --- CONCURRENCY TEST: Access memory while DMA is busy ---
        // This is a simple test for the arbiter.
        // The CPU tries to do its own work while the DMA is also working.
        $display("%t INFO: Waiting for DMA to complete...", $time);
        forever begin
            wishbone_read(32'h8000_0010, read_data); // Read STATUS_REG into local variable
            if (read_data[0] == 1'b0) begin
                break; // Exit the loop if the 'busy' bit is 0
            end
            @(posedge i_clk);
            wishbone_read(CPU_TEST_ADDR, read_data);
            assert(read_data == 32'hAAAAAAAA) else $error("FAILED: Concurrent CPU access failed, rdata: %h", read_data);
        end
        $display("%t INFO: DMA has completed the transfer.", $time);
        wishbone_write(32'h8000_0010, 32'h10000);  // clear done_if
        // wait (u_dut.dut_dma_controller.dut_dma_fsm.current_state == 6);
        // --- CHECK PHASE: Verify the results ---
        $display("%t INFO: Verifying copied data...", $time);
        for (int i = 0; i < LENGTH; i++) begin
            logic [31:0] expected_data;
            logic [31:0] actual_data;
            expected_data = 32'(i + 1);
            addr = DEST_ADDR + (i*4);
            wishbone_read(addr, actual_data);
            assert (actual_data == expected_data) $display("PASS: Offset %0d, Address: %0h, Expected %h, got %h", i, addr, expected_data, actual_data);
                else $error("FAILED: Data mismatch at offset %0d. Expected %h, got %h", i, expected_data, actual_data);
        end
        $display("PASSED: Data verification successful.");
        
        $display("INFO: All tests completed successfully!");
        // wishbone_write(32'h8000_000C, 32'h0);
        $display("----------------------------");
        $display("          Test 2");
        $display("----------------------------");
        // SRC_ADDR  = 32'h0000_2000;
        // DEST_ADDR = 32'h0000_3000;
        // LENGTH    = 128;
        // CPU_TEST_ADDR = 32'h0000_4000;
        $display("%t INFO: Pre-loading source data into BRAM...", $time);
        for (int i = 0; i < LENGTH + 64; i++) begin
            wishbone_write(SRC_ADDR + (i*4) + 4096, 32'(i + 1));
            wishbone_write(DEST_ADDR + (i*4) + 4096, 32'hDEADBEEF); // Fill dest with garbage
        end
        $display("%t INFO: Memory setup complete.", $time);
        wishbone_write(CPU_TEST_ADDR + 4096, 32'hBBBBBBBB);
        // --- ACTION PHASE: Configure and start the DMA ---
        $display("%t INFO: Configuring DMA for a %0d-word transfer.", $time, LENGTH);
        wishbone_write(32'h8000_0000, SRC_ADDR + 4096);  // Write Source Address
        wishbone_write(32'h8000_0004, DEST_ADDR + 4096); // Write Destination Address
        wishbone_write(32'h8000_0008, LENGTH + 64);    // Write Length
        wishbone_write(32'h8000_000C, 32'h3);     // Set 'go' bit and enable "ie"
        $display("%t INFO: DMA started.", $time);


        $display("%t INFO: Waiting for DMA to complete...", $time);
        while (!dma_interrupt) begin
            @(posedge i_clk);
            @(posedge i_clk);
            wishbone_read(CPU_TEST_ADDR + 4096, read_data);
            assert(read_data == 32'hBBBBBBBB) else $error("FAILED: Concurrent CPU access failed, rdata: %h", read_data);
        end
        $display("%t INFO: DMA has completed the transfer.", $time);
        wishbone_write(32'h8000_0010, 32'h10000);  // clear done_if
        // wait (u_dut.dut_dma_controller.dut_dma_fsm.current_state == 6);
        // --- CHECK PHASE: Verify the results ---
        $display("%t INFO: Verifying copied data...", $time);
        for (int i = 0; i < LENGTH + 64; i++) begin
            logic [31:0] expected_data;
            logic [31:0] actual_data;
            expected_data = 32'(i + 1);
            addr = DEST_ADDR + (i*4) + 4096;
            wishbone_read(addr, actual_data);
            assert (actual_data == expected_data) $display("PASS: Offset %0d, Address: %0h, Expected %h, got %h", i, addr, expected_data, actual_data);
                else $error("FAILED: Data mismatch at offset %0d. Expected %h, got %h", i, expected_data, actual_data);
        end
        $display("PASSED: Data verification successful.");
        
        $display("INFO: All tests completed successfully!");
        $finish;
    end
    
    // --- BFM tasks for CPU/Testbench ---
    task wishbone_write(input [31:0] addr, input [31:0] data);
        @(posedge i_clk);
        cpu_wb_if.cyc   <= 1;
        cpu_wb_if.stb   <= 1;
        cpu_wb_if.we    <= 1;
        cpu_wb_if.adr   <= addr;
        cpu_wb_if.dat_w <= data;
        cpu_wb_if.sel   <= 4'hF;
        wait (u_dut.dut_interconnect.cpu_grant);
        @(posedge i_clk);
        wait (cpu_wb_if.ack == 1'b1);
        @(posedge i_clk);
        cpu_wb_if.cyc <= 0;
        cpu_wb_if.stb <= 0;
        cpu_wb_if.we  <= 0;
    endtask

    task wishbone_read(input [31:0] addr, output [31:0] data);
        @(posedge i_clk);
        cpu_wb_if.cyc <= 1;
        cpu_wb_if.stb <= 1;
        cpu_wb_if.we  <= 0;
        cpu_wb_if.adr <= addr;
        wait (u_dut.dut_interconnect.cpu_grant);
        @(posedge i_clk);
        wait (cpu_wb_if.ack === 1'b1);
        @(posedge i_clk);
        data = cpu_wb_if.dat_r;
        cpu_wb_if.cyc <= 0;
        cpu_wb_if.stb <= 0;
    endtask

endmodule

    
