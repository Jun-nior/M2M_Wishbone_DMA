module bram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 14
) (
    input   logic                           clk,
    input   logic   [ADDR_WIDTH - 1 : 0]    addr,
    input   logic                           w_en,
    input   logic   [DATA_WIDTH - 1 : 0]    wdata,
    output  logic   [DATA_WIDTH - 1 : 0]    rdata 
);
    logic [DATA_WIDTH - 1 : 0] mem [0 : 2**ADDR_WIDTH - 1];

    always_ff @(posedge clk) begin
        if (w_en) begin
            mem[addr] <= wdata;
        end
        rdata <= mem[addr];
    end
endmodule