`timescale 1ns/1ps

module tb_rsa;
    reg clk, reset, start;
    reg [1023:0] RSA_in, RSA_key, RSA_n;
    wire [1023:0] RSA_out;
    wire done;

    integer fd, code;
    
    rsa #(1024) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .RSA_in(RSA_in),
        .RSA_key(RSA_key),
        .RSA_n(RSA_n),
        .RSA_out(RSA_out),
        .done(done)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $dumpfile("fsm.vcd");
        $dumpvars(0, tb_rsa);
        
	fd = $fopen("rsa_input.txt", "r");
        if (fd == 0) begin
            $display("ERROR: Cannot open rsa_input.txt");
            $finish;
        end

	while (!$feof(fd)) begin
            code = $fscanf(fd, "%d %d %d\n", RSA_in, RSA_key, RSA_n);
            if (code != 3) begin
                $display("Invalid line in input file!");
                $finish;
            end

            $display("\n=== New Test Case ===");
            $display("RSA_in = %d", RSA_in);
            $display("RSA_key = %d", RSA_key);
            $display("RSA_n = %d", RSA_n);

            // Reset & start
            reset = 1;
            start = 0;
            #20 reset = 0;
            #10 start = 1;
            #10 start = 0;

            wait(done);
            $display("RSA_out = %d", RSA_out);
		$display("RSA_out = %h", RSA_out);
        end

        $fclose(fd);
        $display("\nAll test cases finished.");
        $finish;
    end
endmodule