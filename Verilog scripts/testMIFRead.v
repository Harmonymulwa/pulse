module testMIFRead #(
	parameter LENGTH = 10000,
	parameter DATA_WIDTH = 16

)(
	input clock,
	input enable,
	
	output reg coeffSetFlag,	
	output signed [DATA_WIDTH - 1:0] coeffOutRe,
	output signed [DATA_WIDTH - 1:0] coeffOutIm
);


reg signed [DATA_WIDTH-1:0] MIFBuffer [0:(LENGTH * 2) - 1];


initial begin
	$readmemb("MFImpulseCoeff.mif", MIFBuffer);
end



endmodule
