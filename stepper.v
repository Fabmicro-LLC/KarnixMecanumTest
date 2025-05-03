module stepper #(
	parameter CLK_FREQ = 25000000		// Default clk base frequency
)
(
	input	wire 		clk,		// Base clock
	input	wire 		rst,		// Base clock
	input	wire 		valid,		// Validity enables stepper 
	input	wire [31:0]	step_freq_top,	// Input defines step frequency
	input	wire [31:0]	step_num,	// Input defines number of steps to go
	output	reg 		one_step,	// output one step
	output	reg 		ready		// output indicates readiness (all steps made) 
);
	reg [31:0]	clk_div;
	reg [31:0]	clk_div_top;
	reg [31:0]	steps;

	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			clk_div <= 'b0;
			clk_div_top <= 'b0;
			steps <= 'b0;
			one_step <= 'b0;
			ready <= 'b0;
		end else begin
			if (valid && ~ready) begin
				clk_div <= clk_div + 'b1;

				if (clk_div == 0)
					clk_div_top <= step_freq_top;
					
				if (clk_div == clk_div_top) begin
					one_step <= ~one_step;

					clk_div <= 'b0;

					if (one_step == 'b1)
						steps <= steps + 'b1;

					if (steps == step_num)
						ready <= 'b1;
				end

			end

			if (!valid) begin
				clk_div <= 'b0;
				ready <= 'b0;
				steps <= 'b0;
			end
		end
	end

endmodule

