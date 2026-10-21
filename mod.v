module mod #(
    parameter WIDTH = 64
)(
    input      [2*WIDTH-1:0] a,  
    input      [WIDTH-1:0]   n,   
    output reg [WIDTH-1:0]   R
);

    reg [WIDTH:0] remainder; 
    integer i;

    always @* begin
        remainder = 0;

   
        for (i = 2*WIDTH-1; i >= 0; i = i - 1) begin
            remainder = (remainder << 1) | a[i];

            if (remainder >= n) begin
                remainder = remainder - n;
            end
        end

        R = remainder[WIDTH-1:0];
    end

endmodule