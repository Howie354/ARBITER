module round_robin_arbiter_base #(
    parameter REQ_NUM = 8
) (
    input                  clk,
    input                  rst_n,
    input [REQ_NUM-1 : 0]  reqs,
    output [REQ_NUM-1 : 0] grants
);

    reg [REQ_NUM-1 : 0]  mask;         //掩码，默认为11111111
    wire has_masked_reqs;
    wire [REQ_NUM-1 : 0] masked_reqs;
    wire [REQ_NUM-1 : 0] masked_grants;
    wire [REQ_NUM-1 : 0] unmasked_grants;
    
    assign has_masked_reqs = |masked_reqs;
    assign masked_reqs = mask & reqs;
    assign masked_grants = masked_reqs & ~(masked_reqs - 1'b1);
    assign unmasked_grants = reqs & ~(reqs - 1'b1);
    assign grants = has_masked_reqs ? masked_grants : unmasked_grants;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            mask <= {REQ_NUM{1'b1}};  //用{}扩展
        end
        else if(~(|mask)) begin
            mask <= {REQ_NUM{1'b1}};
        end
        else if(has_masked_reqs) begin
            mask <= ~(grants|(grants-1'b1));
        end
    end
    
    // reqs =                 8'b01010001;
    // mask =                 8'b11111100;
    // masked_reqs =          8'b01010000;
    // grants =               8'b00010000; 
    // grants-1 =             8'b00001111;
    // grants|(grants-1) =    8'b00011111;
    // ~(grants|(grants-1)) = 8'b11100000;      形成下一个mask的算法
    // next_mask =            8'b11100000;

endmodule

module round_robin_arbiter_hand #(
    parameter REQ_NUM = 8
) (
    input                  clk,
    input                  rst_n,

    input  [REQ_NUM-1 : 0] valid_in,
    input  [REQ_NUM-1 : 0] data_in,
    input  [REQ_NUM-1 : 0] last_in,
    output [REQ_NUM-1 : 0] ready_in,

    output                  valid_out,
    output                  data_out,
    output                  last_out,
    input                   ready_out

);

round_robin_arbiter_base #(.REQ_NUM(REQ_NUM)) u_round_robin_arbiter_base(
    .clk(clk),
    .rst_n(rst_n),
    .reqs(valid_in),
    .grants(grants)
);

localparam ADDR_WD = $clog2(REQ_NUM);

wire [REQ_NUM-1 : 0] grants;

reg                 lock_r;
reg [REQ_NUM-1 : 0] grants_r;

reg [ADDR_WD-1 : 0] grants_idx;

wire change_grants;
wire has_grants;
assign change_grants = valid_out && ready_out && last_out;
assign has_grants = |grants;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        lock_r <=  1'b0;
        grants_r <= 'b0;
    end
    else begin
        if(change_grants) begin
            lock_r <=  1'b0;
            grants_r <= 'b0;
        end
        if(has_grants & !lock_r) begin //注意是!lock_r，不是!last_out。
            lock_r   <= 1'b1;
            grants_r <= grants;
        end
    end
end

integer idx;
always @(*) begin
    grants_idx = 'b0;
    for(idx = 0; idx < REQ_NUM; idx = idx + 1'b1) begin
        if(grants_r[idx] == 1'b1) begin
            grants_idx = idx;
        end
    end
end

//if grants_r = 8'b00000001 / 8'b00000000 ==> grants_idx = 0，所以下面赋值时需要 & grants_r[grants_idx]来确定是有分配还是无分配grants。 
assign ready_in = grants_r & {REQ_NUM{ready_out}};
assign valid_out = valid_in[grants_idx] & grants_r[grants_idx];
assign data_out = data_in[grants_idx];
assign last_out = last_in[grants_idx] & grants_r[grants_idx];

endmodule