/*
 * Module: wishbone_master_agent
 * Description: A reusable agent that performs a single Wishbone master transaction (read or write)
 * upon receiving a start command. It handles the low-level Wishbone handshake protocol.
 */
module wishbone_master_agent #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (
    // --- Control Interface (from FSM) ---
    input  logic                  i_clk,
    input  logic                  i_rst_n,
    input  logic                  i_start, 
    input  logic                  i_we,    
    input  logic [ADDR_WIDTH-1:0] i_addr,
    input  logic [DATA_WIDTH-1:0] i_wdata,
    output logic                  o_busy,  
    output logic [DATA_WIDTH-1:0] o_rdata, 
    output logic                  o_done,  

    rggen_wishbone_if.master wb_if
);

    typedef enum logic [1:0] {
        IDLE,
        REQUEST,
        WAIT_ACK
    } state_e;

    state_e current_state, next_state;

    logic [DATA_WIDTH-1:0] rdata_reg;

    // --- State Register ---
    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // --- Next State Logic ---
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (i_start) begin
                    next_state = REQUEST;
                end
            end
            REQUEST: begin
                // Move to WAIT_ACK on the next cycle to wait for the slave's response
                next_state = WAIT_ACK;
            end
            WAIT_ACK: begin
                if (wb_if.ack || wb_if.err) begin
                    // Transaction is complete once we receive ack or err
                    next_state = IDLE;
                end
            end
        endcase
    end

    // --- Output Logic ---
    always_comb begin
        // Default values
        o_busy  = (current_state != IDLE);
        o_done  = (current_state == WAIT_ACK && (wb_if.ack || wb_if.err));;
        if (current_state == WAIT_ACK && wb_if.ack && !i_we) begin
            o_rdata = wb_if.dat_r;
        end else begin
            o_rdata = 'x; 
        end

        wb_if.cyc   = (current_state == REQUEST || current_state == WAIT_ACK);
        wb_if.stb   = (current_state == REQUEST || current_state == WAIT_ACK);
        wb_if.we    = i_we;
        wb_if.adr   = i_addr;
        wb_if.dat_w = i_wdata;
        wb_if.sel   = 4'hF; // Assume full data width transfer for simplicity
    end
    
    // --- Data Capture Logic ---
    // always_ff @(posedge i_clk) begin
    //     if (current_state == WAIT_ACK && wb_if.ack && !i_we) begin
    //         rdata_reg <= wb_if.dat_r;
    //     end else begin
    //         rdata_reg <= 'hx;
    //         done_comb <= 0;
    //     end
    // end

endmodule
