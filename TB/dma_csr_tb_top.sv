`timescale 1ns/1ps
`include "rggen_rtl_pkg.sv"

module DMA_CSR_tb_top;

  logic i_clk;
  logic i_rst_n;

  rggen_wishbone_if #(
    .ADDRESS_WIDTH(32),
    .DATA_WIDTH   (32)
  ) wishbone_if();

  logic       i_busy;
  logic       o_go;
  logic       i_done_if_set;
  logic       o_ie;
  logic [31:0] o_source_addr;
  logic [31:0] o_dest_addr;
  logic [15:0] o_len;
  logic       o_done_if_state; 

  DMA_CSR u_dut (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .wishbone_if(wishbone_if.slave),
    
    // Connect to FSM signals
    .o_SOURCE_ADDR_REG_addr(o_source_addr),
    .o_DEST_ADDR_REG_addr(o_dest_addr),
    .o_LENGTH_REG_len(o_len),
    .o_CONTROL_REG_go(o_go),
    .o_CONTROL_REG_ie(o_ie),
    .i_STATUS_REG_busy(i_busy),
    .i_STATUS_REG_done_if_set(i_done_if_set),
    .o_STATUS_REG_done_if(o_done_if_state) 
  );

  // Clock Generation
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk; 
  end

  initial begin
    logic [31:0] read_data;

    i_rst_n <= 1'b0;
    i_busy <= 1'b0;
    i_done_if_set <= 1'b0;
    repeat (5) @(posedge i_clk);
    i_rst_n <= 1'b1;
    @(posedge i_clk);
    $display("INFO: Reset complete.");

    // === TEST 1: CHECK INITIAL VALUES ===
    $display("INFO: --- Running Test 1: Initial Values ---");
    wishbone_read(32'h00, read_data); // Read SOURCE_ADDR_REG
    assert (read_data == 32'h0) else $error("FAILED: SOURCE_ADDR_REG initial value mismatch.");
    wishbone_read(32'h10, read_data); // Read STATUS_REG
    assert (read_data == 32'h0) else $error("FAILED: STATUS_REG initial value mismatch.");
    $display("PASSED: Test 1.");

    // === TEST 2: RW (Read-Write) Registers ===
    $display("INFO: --- Running Test 2: RW Registers ---");
    wishbone_write(32'h00, 32'h1234_5678);
    wishbone_write(32'h04, 32'h9ABC_DEF0);
    wishbone_write(32'h08, 32'h0000_FFFF);
    wishbone_write(32'h0C, 32'h0000_0002);

    wishbone_read(32'h00, read_data);
    assert (read_data == 32'h1234_5678) else $error("FAILED: SOURCE_ADDR_REG R/W failed.");
    assert (o_source_addr == 32'h1234_5678) else $error("FAILED: o_source_addr output mismatch.");
    
    wishbone_read(32'h04, read_data);
    assert (read_data == 32'h9ABC_DEF0) else $error("FAILED: DEST_ADDR_REG R/W failed.");
    assert (o_dest_addr == 32'h9ABC_DEF0) else $error("FAILED: o_dest_addr output mismatch.");

    wishbone_read(32'h08, read_data);
    assert (read_data == 32'h0000_FFFF) else $error("FAILED: LENGTH_REG R/W failed.");
    assert (o_len == 16'hFFFF) else $error("FAILED: o_len output mismatch.");

    wishbone_read(32'h0C, read_data);
    assert (read_data[1] == 1'b1) else $error("FAILED: IE bit R/W failed.");
    assert (o_ie == 1'b1) else $error("FAILED: o_ie output mismatch.");
    $display("PASSED: Test 2.");

    // === TEST 3: RO (Read-Only) Bit 'busy' ===
    $display("INFO: --- Running Test 3: RO 'busy' bit ---");
    i_busy <= 1'b1; // Simulate FSM is busy
    @(posedge i_clk);
    wishbone_read(32'h10, read_data);
    assert (read_data[0] == 1'b1) else $error("FAILED: 'busy' bit read failed.");
    i_busy <= 1'b0;
    @(posedge i_clk);
    $display("PASSED: Test 3.");
    
    // === TEST 4: RW (Read-Write) Bit 'go' (Updated for 'rw' type) ===
    $display("INFO: --- Running Test 4: RW 'go' bit ---");
    
    // Step 1: Write '1' to set the 'go' bit.
    // Write 0x3 to set both 'go' (bit 0) and 'ie' (bit 1).
    wishbone_write(32'h0C, 32'h3); 
    @(posedge i_clk); 
    assert (o_go == 1'b1) else $error("FAILED: o_go did not become 1 after writing 1.");
    $display("INFO: 'go' bit successfully set to 1.");

    wishbone_read(32'h0C, read_data);
    assert (read_data[0] == 1'b1) else $error("FAILED: 'go' bit did not read back as 1.");

    // Step 2: Write '0' to clear the 'go' bit.
    // Write 0x2 to keep 'ie' high but clear 'go'.
    wishbone_write(32'h0C, 32'h2);
    @(posedge i_clk); 
    assert (o_go == 1'b0) else $error("FAILED: o_go did not become 0 after writing 0.");
    $display("INFO: 'go' bit successfully cleared to 0.");
    
    wishbone_read(32'h0C, read_data);
    assert (read_data[0] == 1'b0) else $error("FAILED: 'go' bit did not read back as 0.");

    $display("PASSED: Test 4.");

    // === TEST 5: W1C (Write-1-to-Clear) Bit 'done_if' ===
    $display("INFO: --- Running Test 5: W1C 'done_if' bit ---");
    // Step 1: Simulate HW setting the flag
    i_done_if_set <= 1'b1;
    @(posedge i_clk);
    i_done_if_set <= 1'b0;
    
    // Step 2: Verify the flag is set (sticky)
    wishbone_read(32'h10, read_data);
    assert (read_data[16] == 1'b1) else $error("FAILED: 'done_if' flag was not set by hardware.");
    assert (o_done_if_state == 1'b1) else $error("FAILED: o_done_if_state output should be high after set."); // NEW ASSERTION

    // Step 3: Write 1 to clear the flag
    wishbone_write(32'h10, 32'h0001_0000);

    // Step 4: Verify the flag is cleared
    wishbone_read(32'h10, read_data);
    assert (read_data[16] == 1'b0) else $error("FAILED: 'done_if' flag was not cleared by software write.");
    assert (o_done_if_state == 1'b0) else $error("FAILED: o_done_if_state output should be low after clear."); // NEW ASSERTION
    $display("PASSED: Test 5.");

    $display("INFO: All tests completed successfully!");
    $finish;
  end

  task wishbone_write(input [31:0] addr, input [31:0] data);
    @(posedge i_clk);
    wishbone_if.cyc   <= 1;
    wishbone_if.stb   <= 1;
    wishbone_if.we    <= 1;
    wishbone_if.adr   <= addr;
    wishbone_if.dat_w <= data;
    wishbone_if.sel   <= 4'hF;
    do @(posedge i_clk); while (!wishbone_if.ack && !wishbone_if.err);
    wishbone_if.stb <= 0;
    wishbone_if.cyc <= 0;
  endtask

  task wishbone_read(input [31:0] addr, output [31:0] data);
    @(posedge i_clk);
    wishbone_if.cyc <= 1;
    wishbone_if.stb <= 1;
    wishbone_if.we  <= 0;
    wishbone_if.adr <= addr;
    do @(posedge i_clk); while (!wishbone_if.ack && !wishbone_if.err);
    data = wishbone_if.dat_r;
    wishbone_if.stb <= 0;
    wishbone_if.cyc <= 0;
  endtask
  
endmodule
