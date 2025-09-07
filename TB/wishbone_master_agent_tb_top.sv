`timescale 1ns/1ps
`include "rggen_rtl_pkg.sv"

//##############################################################################
// Testbench Top
//##############################################################################
module wishbone_master_agent_tb_top;

    logic                   clk;
    logic                   rst_n;
    logic                   start;
    logic                   we;
    logic [31:0]            addr;
    logic [31:0]            wdata;
    logic                   busy;
    logic [31:0]            rdata;
    logic                   done;

    rggen_wishbone_if #(
        .ADDRESS_WIDTH(32),
        .DATA_WIDTH   (32)
    ) wb_if();

    wishbone_master_agent #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_dut (
        .i_clk    (clk),
        .i_rst_n  (rst_n),
        .i_start  (start),
        .i_we     (we),
        .i_addr   (addr),
        .i_wdata  (wdata),
        .o_busy   (busy),
        .o_rdata  (rdata),
        .o_done   (done),
        .wb_if    (wb_if.master)
    );

    dummy_wishbone_slave u_slave (
        .i_clk    (clk),
        .i_rst_n  (rst_n),
        .wb_if    (wb_if.slave)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("INFO: Starting testbench...");
        
        start <= 0;
        rst_n <= 1'b0;
        repeat (5) @(posedge clk);
        rst_n <= 1'b1;
        @(posedge clk);
        $display("INFO: Reset complete.");

        // === TEST 1: WRITE TRANSACTION ===
        $display("INFO: --- Running Test 1: Write Transaction ---");
        addr  <= 32'h1000;
        wdata <= 32'hCAFE_BABE;
        we    <= 1'b1;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        @(posedge clk);
        assert (busy == 1'b1) else $error("FAILED: o_busy did not go high on start.");
        
        wait (done == 1'b1);
        $display("INFO: Write transaction done.");
        @(posedge clk);
        @(posedge clk);
        assert (busy == 1'b0) else $error("FAILED: o_busy did not go low after done.");
        $display("PASSED: Test 1.");

        // === TEST 2: READ TRANSACTION ===
        $display("INFO: --- Running Test 2: Read Transaction ---");
        addr  <= 32'h2000;
        we    <= 1'b0;
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        
        
        wait (done == 1'b1);
        $display("INFO: Read transaction done.");
        @(posedge clk);
        assert (rdata == 32'hDEAD_BEEF) else $error("FAILED: Read data mismatch. Expected %h, got %h", 32'hDEAD_BEEF, rdata);
        
        @(posedge clk);
        assert (busy == 1'b0) else $error("FAILED: o_busy did not go low after done.");
        $display("PASSED: Test 2.");

        $display("INFO: All tests completed successfully!");
        $finish;
    end
endmodule


//##############################################################################
// Dummy Wishbone Slave
//##############################################################################
module dummy_wishbone_slave (
    input  logic i_clk,
    input  logic i_rst_n,
    rggen_wishbone_if.slave wb_if
);
    logic ack_delay;
    logic request_seen;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            request_seen <= 1'b0;
        end else if (wb_if.cyc && wb_if.stb && !request_seen) begin
            request_seen <= 1'b1;
        end else if (wb_if.ack) begin 
        end
    end
    
    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            ack_delay <= 1'b0;
        end else begin
            ack_delay <= request_seen;
        end
    end

    assign wb_if.ack   = ack_delay;
    assign wb_if.dat_r = 32'hDEAD_BEEF; // Return a fixed value for reads
    assign wb_if.err   = 1'b0;

endmodule
