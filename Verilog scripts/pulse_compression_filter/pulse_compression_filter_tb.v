
 -------------------
 This module is a test bench for the module pulse_compression_filter_tb.v. The script
 imports the MATLAB pulse compression filter output MIF file and compares
 if the obtained output from the pulse_compression_filter is the same as the MATLAB
 implmentation.

*/


// Setting the time unit used in this module.
`timescale 1 ns/100 ps



module pulse_compression_filter_tb;


// Parameters for creating the 80MHz clock signal.
localparam NUM_CYCLES = 500000;
localparam CLOCK_FREQ = 80000000;
localparam RST_CYCLES = 20;


// Creating the local parameters for the DUT module
localparam COEFF_LENGTH = 800;
localparam DATA_LENGTH = 7700;
localparam HT_COEFF_LENGTH = 27;
localparam DATA_WIDTH = 12;




// Creating the local parameters the DUT.
reg clock;
reg enableModule;
wire [31:0] MFOutput;

// Creating the local parameters for storing the MIF data.
reg [31:0] MIFBuffer [0:14399];

// Creating the local parameters for the testing purposes.
reg [13:0] MIFCounter;
reg [31:0] outputBuffer [0:14399];
reg testFailedFlag;




// FSM
reg [1:0] state;
localparam IDLE = 0;
localparam COMAPRE_DATA = 1;
localparam PRINT_RESULTS = 2;
localparam STOP = 3;




// Set the initial value of the clock.
initial begin
	clock = 1'd0;
	enableModule = 1'd0;
	testFailedFlag = 1'd0;
	state = IDLE;
	MIFCounter = 14'd0;
	
	// Set enableModule high after RST_CYCLES clock cycles.
	repeat(RST_CYCLES) @ (posedge clock);
	enableModule = 1'd1;
end



// Transfer the data in the file MFOutputData.mif to MIFBuffer.
// This MIF file contains the expected output of the matched filter
// from the MATLAB simulation.
initial begin
	$readmemb("MFOutputData.mif", MIFBuffer);
end






// Instantiated DUT module.
 pulse_compression_filter #(
	.COEFF_LENGTH 		(COEFF_LENGTH),
	.DATA_LENGTH 		(DATA_LENGTH),
	.DATA_WIDTH 		(DATA_WIDTH)
) dut (
	.clock				(clock),
	.enable				(enableModule),
	
	.MFOutput  		  (MFOutput)
);



// Calculating the parameters for the 50MHz clock.
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



always @ (posedge clock) begin
	case(state)
	
	
		// State IDLE. This state waits until enableModule is high before 
		// transistioning to COMAPRE_DATA. It waits 13 clock cycles as that
		// is how long it takes before data is supplied and the output data
		// is provided.
		IDLE: begin
			if(enableModule) begin
				repeat(13) @ (posedge clock);
				state = COMAPRE_DATA;
			end
		end
		
		
		// State COMAPRE_DATA. This state stores the output of the dut to 
		// outputBuffer and then compares that output with the expected output
		// from the MIFBuffer. If the values do not match it set testFailedFlag
		// high. Once all the data is checked (14400), the state transisions to 
		// PRINT_RESULTS.
		COMAPRE_DATA: begin
		
			// Store and compare the obtained output and the expected output.
			outputBuffer[MIFCounter] = MFOutput;
			if(outputBuffer[MIFCounter] != MIFBuffer[MIFCounter]) begin
				testFailedFlag = 1'd1;
			end
			
			// Increment MIFCounter by 1.
			MIFCounter = MIFCounter + 14'd1;
			
			// If MIFCounter is equal to 14400, transision to PRINT_RESULTS.
			if(MIFCounter == 14'd14400) begin
				state = PRINT_RESULTS;
			end
		end
		
		
		// State PRINT_RESULTS. This state prints the transcript of the test bench.
		PRINT_RESULTS: begin
			$display("This is a test bench for the module pulse_compression_filter. \n \n",
						"It tests whether the output of the implimented pulse compression filter \n",
						"on the FPGA is identical to the MATLAB implmentation. The matched filter \n",
						"impulse response is loaded through MFImpulseCoeff.MIF whilst the input data \n",
						"is loaded through the file MFInputData.MIF. The 14,400 obtained output values from\n", 
						"the module are then compared with the MATLAB output which is stored in ",
						"MFOutputData.MIF. \n \n"
			);
			
			// Check if testFailedFlag is high, is so print the test failed, else it passed.
			if(testFailedFlag) begin
				$display("Test results: FAILED \n \n");
			end
			else begin
				$display("Test results: PASSED \n \n");
			end

			// Transision to state STOP.
			state = STOP;
		end
		
		
		// State STOP. This state stops the simulation.
		STOP: begin
			$stop;
		end
		
		
		// State default. This state sets the default values just incase the 
		// FSM is in an unkown state.
		default: begin
			clock = 1'd0;
			enableModule = 1'd0;
			testFailedFlag = 1'd0;
			state = IDLE;
			MIFCounter = 14'd0;
		end	
	
	endcase
end

endmodule
