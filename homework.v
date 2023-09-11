module homework #(
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

wire [REQ_NUM-1 : 0] grants;

localparam ADDR_WD = $clog2(REQ_NUM);

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

weight_round_robin_arbiter #(.REQ_NUM(REQ_NUM)) u_weight_round_robin_arbiter(
    .clk(clk),
    .rst_n(rst_n),
    .reqs(valid_in),
    .grants(grants)
);

endmodule

module weight_round_robin_arbiter #(
    parameter REQ_NUM = 8
) (
    input                  clk,
    input                  rst_n,
    input [REQ_NUM-1 : 0]  reqs,
    output [REQ_NUM-1 : 0] grants
);


    reg [REQ_NUM-1 : 0]  mask_r;         //掩码，默认为11111111
    wire has_masked_reqs;
    wire [REQ_NUM-1 : 0] masked_reqs;
    wire [REQ_NUM-1 : 0] masked_grants;
    wire [REQ_NUM-1 : 0] unmasked_grants;
    
    localparam ADDR_WD = $clog2(REQ_NUM);
    localparam WEIGHT_WD = ADDR_WD + 1'b1;
    reg [WEIGHT_WD-1 : 0] weight_r [REQ_NUM-1 : 0];
    reg [ADDR_WD-1 : 0] grants_idx;
    
    wire all_weight_zero;
    assign all_weight_zero = ~(|mask_r);

    assign has_masked_reqs = |masked_reqs;
    assign masked_reqs = mask_r & reqs;
    assign masked_grants = masked_reqs & ~(masked_reqs - 1'b1);
    assign unmasked_grants = reqs & ~(reqs - 1'b1);
    assign grants = has_masked_reqs ? masked_grants : unmasked_grants;

    always @(*) begin
      grants_idx = 'b0;
      for(idx = 0; idx < REQ_NUM; idx = idx + 1) begin
          if(grants[idx] == 1'b1) begin
              grants_idx = idx;
          end
      end
    end

    integer idx;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(idx = 0; idx < REQ_NUM; idx = idx + 1) begin
                weight_r[idx] <= idx + 1'b1;
            end
            
            mask_r <= {REQ_NUM{1'b1}};
        end
        else if(all_weight_zero) begin
            for(idx = 0; idx < REQ_NUM; idx = idx + 1) begin
                weight_r[idx] <= idx + 1'b1;
            end
            
            mask_r <= {REQ_NUM{1'b1}};
        end
        else if(has_masked_reqs) begin
            weight_r[grants_idx] <=  weight_r[grants_idx] - 1'b1;
            mask_r[grants_idx] <= (weight_r[grants_idx] != 1'b1);
        end
    end

endmodule
