module bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 14,
    parameter BYTE_WIDTH = 8
) (
    input   logic                               clk,
    input   logic   [ADDR_WIDTH - 1 : 0]        addr,
    input   logic   [DATA_WIDTH/BYTE_WIDTH-1:0] w_en,
    input   logic   [DATA_WIDTH - 1 : 0]        wdata,
    output  logic   [DATA_WIDTH - 1 : 0]        rdata 
);
    logic [DATA_WIDTH - 1 : 0] mem [0 : 2**ADDR_WIDTH - 1];

    always_ff @(posedge clk) begin
        if (w_en[0]) begin
            mem[addr][7:0]      <= wdata[7:0];
        end
        if (w_en[1]) begin
            mem[addr][15:8]     <= wdata[15:8];
        end
        if (w_en[2]) begin
            mem[addr][23:16]    <= wdata[23:16];
        end
        if (w_en[3]) begin
            mem[addr][31:24]    <= wdata[31:24];
        end
        rdata <= mem[addr];
    end
endmodule