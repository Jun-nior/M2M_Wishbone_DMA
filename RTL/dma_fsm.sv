/*
 * Module: dma_fsm
 * Description: The core state machine (the "brain") of the DMA controller.
 * It orchestrates the data transfer by issuing commands to the wishbone_master_agent.
 */
module dma_fsm #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter LEN_WIDTH  = 16
) (
    // --- DMA_CSR ---
    input  logic                  i_clk,
    input  logic                  i_rst_n,
    input  logic                  i_go,           
    input  logic [ADDR_WIDTH-1:0] i_src_addr,
    input  logic [ADDR_WIDTH-1:0] i_dest_addr,
    input  logic [LEN_WIDTH-1:0]  i_len,
    output logic                  o_busy,
    output logic                  o_done_if_set, 
    output logic                  o_go_hw_we,   // enable hw write to "go" bit
    output logic                  o_clear_go,   // clear the "go" bit automatically when DMA is finished 

    // --- WB_master_agent ---
    output logic                  o_start,
    output logic                  o_we,
    output logic [ADDR_WIDTH-1:0] o_addr,
    output logic [DATA_WIDTH-1:0] o_wdata,
    input  logic                  i_done,
    input  logic [DATA_WIDTH-1:0] i_rdata
);

    typedef enum logic [2:0] {
        IDLE,
        LATCH_CONFIG,
        READ_START,
        READ_WAIT,
        WRITE_START,
        WRITE_WAIT,
        FINISH
    } state_e;

    state_e current_state, next_state;

    logic [ADDR_WIDTH-1:0] src_addr_reg;
    logic [ADDR_WIDTH-1:0] dest_addr_reg;
    logic [LEN_WIDTH-1:0]  len_reg;
    logic [DATA_WIDTH-1:0] data_buffer; 

    logic i_go_prev;
    logic go_trigger;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // --- Detech i_go once --- (nice to have in case i_go stay high for various cycle)
    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            i_go_prev <= 1'b0;
        end else begin
            i_go_prev <= i_go;
        end
    end
    
    assign go_trigger = !i_go_prev && i_go; 

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (go_trigger) begin
                    next_state = LATCH_CONFIG;
                end
            end
            LATCH_CONFIG: begin
                if (i_len == 0) begin
                    next_state = FINISH;
                end else begin
                    next_state = READ_START;
                end
            end
            READ_START: begin
                next_state = READ_WAIT;
            end
            READ_WAIT: begin
                if (i_done) begin
                    next_state = WRITE_START;
                end
            end
            WRITE_START: begin
                next_state = WRITE_WAIT;
            end
            WRITE_WAIT: begin
                if (i_done) begin
                    if (len_reg > 1) begin
                        next_state = READ_START; 
                    end else begin
                        next_state = FINISH;
                    end
                end
            end
            FINISH: begin
                next_state = IDLE;
            end
        endcase
    end

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            src_addr_reg  <= '0;
            dest_addr_reg <= '0;
            len_reg       <= '0;
            data_buffer   <= '0;
        end else begin
            case (current_state)
                LATCH_CONFIG: begin
                    src_addr_reg  <= i_src_addr;
                    dest_addr_reg <= i_dest_addr;
                    len_reg       <= i_len;
                end
                READ_WAIT: begin
                    if (i_done) begin
                        data_buffer <= i_rdata;
                    end
                end
                WRITE_WAIT: begin
                    if (i_done) begin
                        src_addr_reg  <= src_addr_reg + 4; // Increment by one word (4 bytes)
                        dest_addr_reg <= dest_addr_reg + 4;
                        len_reg       <= len_reg - 1;
                    end
                end
            endcase
        end
    end


    always_comb begin
        o_busy        = (current_state != IDLE);
        o_done_if_set = (current_state == FINISH);
        o_go_hw_we    = (current_state == LATCH_CONFIG);
        o_clear_go    = 0; // always want to clear bit "go"
        o_start = 0;
        o_we    = 0;
        o_addr  = 0;
        o_wdata = 0;

        case (current_state)
            READ_START: begin
                o_start = 1;
                o_we    = 0; // Read
                o_addr  = src_addr_reg;
            end
            READ_WAIT: begin
                o_we    = 1'b0;
                o_addr  = src_addr_reg;
            end
            WRITE_START: begin
                o_start = 1;
                o_we    = 1; // Write
                o_addr  = dest_addr_reg;
                o_wdata = data_buffer;
            end
            WRITE_WAIT: begin
                o_we    = 1'b1;
                o_addr  = dest_addr_reg;
                o_wdata = data_buffer;
            end
        endcase
    end

endmodule
