module priority_arbiter #(
    parameter REQ_NUM = 8
)(
    input [REQ_NUM-1 : 0]  reqs,
    output [REQ_NUM-1 : 0] grants
);

wire [REQ_NUM-1 : 0] pre_reqs;
localparam VECTOR = 1'b1;
localparam CONCISE = 1'b1;

generate
    if(CONCISE) begin
        assign grants = reqs & ~(reqs - 1'b1); //简易算法
    end 
    else if(VECTOR) begin
        assign pre_reqs[REQ_NUM-1 : 0] = reqs[REQ_NUM-2 : 0] & pre_reqs[REQ_NUM-2 : 0];
        assign grants = reqs & ~pre_reqs;  //向量算法
    end
    else begin
        assign pre_reqs[0] = 1'b0;
        assign grants[0] = reqs[0];        
        genvar i;   
        for(i=1;i<REQ_NUM;i=i+1) begin
            assign pre_reqs[i] = |reqs[i-1:0];
            assign grants[i] = reqs[i] & ~pre_reqs[i];
        end   
    end           //for循环相当于把一堆展开的assign堆叠起来
    
endgenerate 


endmodule