module rsa #(
    parameter WIDTH = 1024
)(
    input clk,
    input reset,
    input start, 

    input  [WIDTH-1:0] RSA_in,
    input  [WIDTH-1:0] RSA_key,
    input  [WIDTH-1:0] RSA_n,

    output reg [WIDTH-1:0] RSA_out,
    output reg done
);

    reg [2*WIDTH-1:0] result;
    reg [2*WIDTH-1:0] base;
    reg [WIDTH-1:0] ex1, ex2, A, B;
    reg [WIDTH-1:0] N, N_INV;
	 
    reg [9:0] bit;

    // Montgomery multiplier signals
    reg mm_start, ni_start;
    wire mm_done, ni_done;
    wire [WIDTH-1:0] mm_res, ni_res, mod_res1, mod_res2;

    montgomery_multiplier #(WIDTH) MM (
        .clk(clk),
        .reset(reset),
        .start(mm_start),
        .a(A),
        .b(B),
        .n(N),
        .n_inv(N_INV),
        .result(mm_res),
        .done(mm_done)
    );

    n_inv #(WIDTH) NI(
	.clk(clk),
	.start(ni_start),
	.reset(reset),
	.n(N),
	.result(ni_res),
	.done(ni_done)
    );

    mod #(WIDTH) MOD1(
	.a(result),
	.n(N),
	.R(mod_res1)
    );

    mod #(WIDTH) MOD2(
	.a(base),
	.n(N),
	.R(mod_res2)
    );

    // FSM
    reg [2:0] state;
    localparam IDLE=0, CALC_E=1, CALC_N=2, INIT=3, SQUARE=4, MULTIPLY=5, CALC_C=6, FINISH=7;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
	    	bit <= 0;
            	done <= 0;
            	state <= IDLE;
        end else begin
		mm_start <= 0;
		ni_start <= 0;

		case (state)

		IDLE: begin
			if (start) begin
				done <= 0;

				ex1 <= RSA_key;
				ex2 <= RSA_key;
				result <= 1 << WIDTH;   // convert 1 to Montgomery form
				base <= RSA_in << WIDTH;     // convert M to Montgomery form
				done <= 0;
				N <= RSA_n;
	    			bit <= 0;
				
				state <= CALC_E;
			end
		end
		
		CALC_E: begin
			if (ex1 == 1) begin
				ni_start <= 1;
				state <= CALC_N;
			end else begin
				ex1 <= ex1 >> 1;
				bit <= bit + 1;
				state <= CALC_E;
			end
		end

		CALC_N: begin
			ni_start <= 0;
                    	if (ni_done) begin
				result <= mod_res1;
				base <= mod_res2;
                        	N_INV <= ni_res;
                        	state <= INIT;
                    	end
                end

          	INIT: begin
			
			done <= 0;
			A <= result;
			B <= result;
			mm_start <= 1;
			bit <= bit - 1;
						  
			if (ex2[bit] == 1 && bit != 10'd1023) begin
				state <= MULTIPLY;
			end
         		else if (ex2[bit] == 0 && bit != 10'd1023) state <= SQUARE;
			else if (bit == 10'd1023) state <= CALC_C;
                end

                SQUARE: begin
			mm_start <= 0;
			if (mm_done) begin
				result <= mm_res;
				state <= INIT;
			end
                end

                MULTIPLY: begin
			mm_start <= 0;
			if (mm_done) begin
				A <= mm_res;
				B <= base[WIDTH-1:0];
				mm_start <= 1;

				if (bit == 10'd1023) begin 
					state <= CALC_C;
				end
				else begin
					state <= SQUARE;
				end
			end
                end

		CALC_C: begin
			if (mm_done) begin
                    		A <= mm_res;
				B <= 1024'd1;
				mm_start <= 1;
				state <= FINISH;
			end
		end

                FINISH: begin
			if (mm_done) begin
                    		RSA_out <= mm_res;
                    		state <= IDLE;
		    		done <= 1;
			end
                end

            endcase
        end
    end
endmodule

