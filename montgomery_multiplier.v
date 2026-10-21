module montgomery_multiplier #(
    parameter WIDTH = 1024
)(
    input               clk,
    input               reset,
    input               start,
    input  [WIDTH-1:0]  a,      // Montgomery form
    input  [WIDTH-1:0]  b,      // Montgomery form
    input  [WIDTH-1:0]  n,      // modulus
    input  [WIDTH-1:0]  n_inv,  // n' = -n^{-1} mod R
    output reg [WIDTH-1:0] result,
    output reg          done
);

    reg [WIDTH-1:0] A, B, N, N_INV;
    reg [2*WIDTH-1:0] t, u, m;            // product t = a*b
    reg [3*WIDTH-1:0] h;

    reg [2:0] state;
    localparam IDLE = 0,
               MUL  = 1,
               CALC_M = 2,
               CALC_H = 3,
               CALC_U1 = 4,
	       CALC_U2 = 5,
               REDUCE = 6;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            done   <= 0;
            state  <= IDLE;
        end else begin
            case (state)

                IDLE: begin
                    done <= 0;
                    if (start) begin
                        A <= a;
                        B <= b;
                        N <= n;
                        N_INV <= n_inv;
                        state <= MUL;
                    end
                end

                MUL: begin
                    t <= A * B;         // t = a*b
                    state <= CALC_M;
                end

                CALC_M: begin
                    m <= (t * N_INV) & ((1 << WIDTH) - 1); // m = (t * n') mod R
                    state <= CALC_H;
                end

		CALC_H: begin
                    h <= m * n; // h = m*n
                    state <= CALC_U1;
                end

                CALC_U1: begin
                    if (h[WIDTH-1:0] >= (1024'b1 << 1023)) u <= (h >> WIDTH) + 1; // u = h/R
		    else u <= (h >> WIDTH);
                    state <= CALC_U2;
                end

		CALC_U2: begin
                    if (t[WIDTH-1:0] >= (1024'b1 << 1023)) u <= u + (t >> WIDTH) + 1; // u = (t + m*n) / R
		    else u <= u + (t >> WIDTH);
                    state <= REDUCE;
                end

                REDUCE: begin
                    if (u >= N)
                        result <= u - N;
                    else
                        result <= u[WIDTH-1:0];
                    done <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule

