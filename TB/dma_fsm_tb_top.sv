`timescale 1ns/1ps

module dma_fsm_tb_top;

    logic                  clk;
    logic                  rst_n;
    logic                  go;
    logic [31:0]           src_addr;
    logic [31:0]           dest_addr;
    logic [15:0]           len;
    logic                  busy;
    logic                  done_if_set;
    logic                  start;
    logic                  we;
    logic [31:0]           addr;
    logic [31:0]           wdata;
    logic                  done;
    logic [31:0]           rdata;

    dma_fsm #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .LEN_WIDTH (16)
    ) u_dut (
        .i_clk        (clk),
        .i_rst_n      (rst_n),
        .i_go         (go),
        .i_src_addr   (src_addr),
        .i_dest_addr  (dest_addr),
        .i_len        (len),
        .o_busy       (busy),
        .o_done_if_set(done_if_set),
        .o_start      (start),
        .o_we         (we),
        .o_addr       (addr),
        .o_wdata      (wdata),
        .i_done       (done),
        .i_rdata      (rdata)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // --- Dummy Wishbone Master Agent Simulation ---
    // This process simulates the behavior of the wishbone_master_agent.
    // It waits for a 'start' command from the FSM and provides a 'done' signal after a fixed delay.
    initial begin
        done <= 1'b0;
        rdata <= 32'hAAAAAAAA; // Default read data
        forever begin
            @(posedge clk iff start); 

            repeat (3) @(posedge clk);
            
            rdata <= rdata + 1;
            
            done <= 1'b1;
            @(posedge clk);
            done <= 1'b0;
        end
    end

    initial begin
        $display("INFO: Starting DMA FSM testbench...");
        
        rst_n <= 1'b0;
        go <= 1'b0;
        repeat (5) @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        $display("INFO: Reset complete.");

        // === TEST 1: Zero-Length Transfer ===
        $display("INFO: --- Running Test 1: Zero-Length Transfer ---");
        src_addr  <= 32'h1000;
        dest_addr <= 32'h2000;
        len       <= 16'd0;
        
        go <= 1'b1;
        @(posedge clk);
        go <= 1'b0;
        
        wait (done_if_set);
        $display("INFO: Zero-length transfer finished.");
        assert (busy == 1'b1) else $error("FAILED: 'busy' should be high during the FINISH state.");
        @(posedge clk);
        @(posedge clk);
        assert (busy == 1'b0) else $error("FAILED: 'busy' should be low after the transfer.");
        $display("PASSED: Test 1.");
        
        @(posedge clk);

        // === TEST 2: Transfer 3 Words ===
        $display("INFO: --- Running Test 2: Transfer 3 Words ---");
        src_addr  <= 32'h1000;
        dest_addr <= 32'h2000;
        len       <= 16'd3;
        
        go <= 1'b1;
        @(posedge clk);
        go <= 1'b0;
        
        for (int i = 0; i < 3; i++) begin
            logic [31:0] expected_src_addr, expected_dest_addr;
            expected_src_addr  = 32'h1000 + (i * 4);
            expected_dest_addr = 32'h2000 + (i * 4);

            @(posedge clk iff (start && !we));
            $display("INFO: Cycle %0d - Read from 0x%h", i, addr);
            assert (addr == expected_src_addr) else $error("FAILED: Incorrect source address.");
            
            @(posedge clk iff (start && we));
            $display("INFO: Cycle %0d - Write to 0x%h with data 0x%h", i, addr, wdata);
            assert (addr == expected_dest_addr) else $error("FAILED: Incorrect destination address.");
        end

        wait (done_if_set);
        $display("INFO: 3-word transfer finished.");
        @(posedge clk);
        @(posedge clk);
        assert (busy == 1'b0) else $error("FAILED: 'busy' should be low after the transfer.");
        $display("PASSED: Test 2.");
        
        $display("INFO: All tests completed successfully!");
        $finish;
    end
endmodule

    
