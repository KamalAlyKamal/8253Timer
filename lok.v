
module x(input clk, input [5:0] N);

reg [5:0] Threshold;

always@(posedge clk)
	Threshold=((N)>>>2);

endmodule
