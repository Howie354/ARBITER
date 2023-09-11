module weight_round_robin_arbiter_tb #(
    parameter REQ_NUM = 8
) ( );

reg                  clk;
reg                  rstn;
reg  [REQ_NUM-1 : 0] reqs;
wire [REQ_NUM-1 : 0] grants;

initial begin
    clk = 1'b0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    rstn = 1'b0;
    #15
    rstn = 1'b1;
    #500
    $finish();
end

initial begin
    $dumpfile ("test.vcd");
    $dumpvars;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        reqs <= 'b0;
    end
    else begin
        reqs <= $random;
    end
end

weight_round_robin_arbiter # (.REQ_NUM(REQ_NUM)
) weight_round_robin_arbiter_1 (.clk(clk),
                                .rstn(rstn),
                                .reqs(reqs),
                                .grants(grants)
);
    
endmodule

