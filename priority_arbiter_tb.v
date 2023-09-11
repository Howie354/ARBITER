module priority_arbiter_tb #(
    parameter REQ_NUM = 8
) (
);

    reg [REQ_NUM-1 : 0]  reqs;
    wire [REQ_NUM-1 : 0] grants;


    always begin
        #8 reqs = {$random}%256;    
    end

    initial begin
        #1000 $finish();
    end
    
    initial begin
        $dumpfile ("test.vcd");
        $dumpvars;
    end

    priority_arbiter #(.REQ_NUM (REQ_NUM)
    ) u_priority_arbiter (
        .reqs(reqs),
        .grants(grants)
    );

endmodule