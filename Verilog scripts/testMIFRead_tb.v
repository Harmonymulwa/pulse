module testMIFRead_tb;


// Parameters for creating the 50MHz clock signal
localparam NUM_CYCLES = 500;
localparam CLOCK_FREQ = 50000000;
localparam RST_CYCLES = 10;

localparam LENGTH = 20000;
localparam DATA_WIDTH = 13;


// Local parameters for the dut module.
reg clock;
reg enableModule;

wire signed [DATA_WIDTH-1:0] outputValue;




initial begin
	clock = 1'd0;
	enableModule = 1'd0;
	// Set enableModule to 1 after RST_CYCLES clock cycles.
	repeat(RST_CYCLES) @ (posedge clock);
	enableModule = 1'd1;
end





testMIFRead #(
	.LENGTH 			(LENGTH),
	.DATA_WIDTH 	(DATA_WIDTH)

)(
	.clock			(clock),
	.enable			(enableModule),
	
	.outputValue	(outputValue)
);




// Clock parameters.
real HALF_CLOCK_PERIOD = (1000000000.0/$itor(CLOCK_FREQ))/2.0;
integer half_cycles = 0;




// Create the clock toggeling and stop it simulation when half_cycles == (2*NUM_CYCLES).
always begin
	#(HALF_CLOCK_PERIOD);
	clock = ~clock;
	half_cycles = half_cycles + 1;

	if(half_cycles == (2*NUM_CYCLES)) begin
		$stop;
	end
end




endmodule
