module AFIFO #(
    parameter DEPTH = 16,
    parameter N = 4, // N must > 1
    parameter WIDTH = 8
) (
    input clk_w, clk_r, rst_w, rst_r,
    input [WIDTH-1:0] wdata,
    input push, pop,
    output wfull, rempty,
    output [WIDTH-1:0] rdata
);
wire [N-1:0] waddr_FIFO, raddr_FIFO;
wire [N:0] rptr_wclk, wptr_rclk, rptr, wptr;
wire wen;

FIFO_wptr #(.N(N)) fifo_wptr0 (
    .clk_w(clk_w),
    .rst_w(rst_w),
    .push(push),
    .rptr_wclk(rptr_wclk),
    .wfull(wfull),
    .wen(wen),
    .waddr_FIFO(waddr_FIFO),
    .wptr(wptr)
);
FIFO_rptr #(.N(N)) fifo_rptr0 (
    .clk_r(clk_r),
    .rst_r(rst_r),
    .pop(pop),
    .rempty(rempty),
    .raddr_FIFO(raddr_FIFO),
    .wptr_rclk(wptr_rclk),
    .rptr(rptr)
);
FIFO #(.DEPTH(DEPTH), .N(N), .WIDTH(WIDTH)) fifo0 (
    .clk_w(clk_w),
    .wdata(wdata),
    .waddr(waddr_FIFO),
    .wen(wen),
    .rdata(rdata),
    .raddr(raddr_FIFO)
);
TWO_FF #(.N(N)) two_ff_w2r (
    .clk(clk_r),
    .rst(rst_r),
    .idata(wptr),
    .odata(wptr_rclk)
);
TWO_FF #(.N(N)) two_ff_r2w (
    .clk(clk_w),
    .rst(rst_w),
    .idata(rptr),
    .odata(rptr_wclk)
);
endmodule
module FIFO_wptr #(
    parameter N = 4
) (
    input clk_w, rst_w,
    input push,
    input [N:0] rptr_wclk,
    output wfull,
    output wen,
    output [N-1:0] waddr_FIFO,
    output reg [N:0] wptr
);
reg [N:0] waddr;
wire [N:0] next_wptr, next_waddr;
// wire wfull;
// wire wen;
// wire [N-1:0] waddr_FIFO;
assign wfull = (wptr[N] != rptr_wclk[N]) & (wptr[N-1] != rptr_wclk[N-1]) & (wptr[N-2:0] == rptr_wclk[N-2:0]);
assign wen = ~wfull & push;
assign next_waddr = waddr + 'd1;
assign next_wptr  = {next_waddr[N], next_waddr[N-1:0] ^ next_waddr[N:1]};
assign waddr_FIFO = waddr[N-1:0];

always @(posedge clk_w or negedge rst_w) begin
    if (!rst_w) begin
        wptr  <= 'd0;
        waddr <= 'd0;
    end else begin
        if (wen) begin
            wptr  <= next_wptr;
            waddr <= next_waddr;
        end else begin
            wptr  <= wptr;
            waddr <= waddr;
        end
    end
end
endmodule

module FIFO_rptr #(
    parameter N = 4
) (
    input clk_r, rst_r,
    input pop,
    output rempty,
    output [N-1:0] raddr_FIFO,
    input [N:0] wptr_rclk,
    output reg [N:0] rptr
);
reg [N:0] raddr;
wire [N:0] next_rptr, next_raddr;
// wire rempty;
wire ren;
wire [N-1:0] rdata_FIFO;
assign rempty = wptr_rclk == rptr;
assign ren = ~rempty & pop;
assign next_raddr = raddr + 'd1;
assign next_rptr  = {next_raddr[N], next_raddr[N-1:0] ^ next_raddr[N:1]};
assign raddr_FIFO = raddr[N-1:0];

always @(posedge clk_r or negedge rst_r) begin
    if (!rst_r) begin
        rptr  <= 'd0;
        raddr <= 'd0;
    end else begin
        if (ren) begin
            rptr  <= next_rptr;
            raddr <= next_raddr;
        end else begin
            rptr  <= rptr;
            raddr <= raddr;
        end
    end
end
endmodule

module FIFO #(
    parameter DEPTH = 16,
    parameter N = 4,
    parameter WIDTH = 8
) (
    input clk_w, // may not need rst_w
    input [WIDTH-1:0] wdata,
    input [N-1:0] waddr,
    input wen,
    output [WIDTH-1:0] rdata,
    input [N-1:0] raddr
);
reg [WIDTH-1:0] data_mem [0:DEPTH-1];
integer i;
assign rdata = data_mem[raddr];
always @(posedge clk_w) begin
    if (wen) data_mem[waddr] <= wdata;
end
endmodule
module TWO_FF #(
    parameter N = 4
) (
    input clk, rst,
    input [N:0] idata,
    output [N:0] odata
);
reg [N:0] reg0, reg1;
assign odata = reg1;
always @(posedge clk or negedge rst) begin
    if (!rst) {reg0, reg1} <= 'd0;
    else      {reg0, reg1} <= {idata, reg0};
end
endmodule