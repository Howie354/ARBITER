module homework_tb #(
    parameter REQ_NUM = 8
) ( );

reg                  clk;
reg                  rstn;  
reg  [REQ_NUM-1 : 0] valid_in;
reg  [REQ_NUM-1 : 0] data_in;
reg  [REQ_NUM-1 : 0] last_in;
wire [REQ_NUM-1 : 0] ready_in;
wire                 valid_out;
wire                 data_out;
wire                 last_out;
reg                  ready_out;

wire [REQ_NUM-1 : 0] fire_in;
assign fire_in = valid_in & ready_in;
wire [REQ_NUM-1 : 0] last_in_fire;
assign last_in_fire = fire_in & last_in;

initial begin
    clk = 0;
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    rstn = 0;
    #15
    rstn = 1;
    #10000
    $finish();
end

initial begin
    $dumpfile ("test.vcd");
    $dumpvars;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        ready_out <= 'b0;
        data_in <= 'b0;
    end
    else begin
        ready_out <= $random;
        data_in <= {REQ_NUM{1'b1}};
    end
end

reg [2 : 0] counter [REQ_NUM-1 : 0];


genvar idx;
for (idx = 0; idx < REQ_NUM; idx = idx + 1) begin
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_in     <= 'b0;
            counter[idx] <= 3'b111;
            last_in      <= 'b0; 
        end
        else begin
            if (!valid_in[idx] || last_in_fire) begin
                valid_in[idx] <= 1'b1;
                counter[idx] <= 3'b111;
                last_in[idx] <= 1'b0;
            end

            if (valid_in[idx] && ready_in[idx]) begin
                counter[idx] <= counter[idx] - 1;
                if (counter[idx] == 1) begin
                    last_in[idx] <= 1'b1;
                end
            end
        end
    end 
end

homework #(.REQ_NUM(REQ_NUM)
) homework_tb (.clk(clk),
               .rst_n(rstn),
               .valid_in(valid_in),
               .data_in(data_in),
               .last_in(last_in),
               .ready_in(ready_in),
               .valid_out(valid_out),
               .data_out(data_out),
               .ready_out(ready_out),
               .last_out(last_out)
);

endmodule