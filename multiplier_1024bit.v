module multiplier_1024bit #(
    parameter WIDTH = 1024
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output reg [2*WIDTH-1:0] product,
    output reg done
);

    // S? d?ng thu?t toán shift-and-add t?i ?u v?i pipeline
    reg [2*WIDTH-1:0] pp;        // Partial product
    reg [2*WIDTH-1:0] multiplicand;
    reg [WIDTH-1:0] multiplier;
    reg [10:0] count;            // 11 bits ?? ??m ??n 1024
    
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            product <= 0;
            pp <= 0;
            multiplicand <= 0;
            multiplier <= 0;
            count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Kh?i t?o
                        pp <= 0;
                        multiplicand <= {{WIDTH{1'b0}}, a};
                        multiplier <= b;
                        count <= 0;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    // Shift-and-add algorithm
                    if (multiplier[0]) begin
                        pp <= pp + multiplicand;
                    end
                    multiplicand <= multiplicand << 1;
                    multiplier <= multiplier >> 1;
                    count <= count + 1;
                    
                    if (count == WIDTH - 1) begin
                        state <= FINISH;
                    end
                end
                
                FINISH: begin
                    product <= pp;
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule