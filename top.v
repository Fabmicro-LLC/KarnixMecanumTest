module top (
	input	wire 		clk25,
	input	wire [3:0]	key,
	output	wire [3:0]	led,
	inout	wire [15:0]	gpio,
);
	localparam	BASE_FREQ = 25000000;
	localparam	MOTOR_FREQ = 16000;
	localparam	MOTOR_STEPS = 96000;

	wire		rst;

	wire		motor_fl_ready;
	wire		motor_fl_step;
	reg		motor_fl_valid;
	reg		motor_fl_dir;
	reg [31:0]	motor_fl_freq_top;
	reg [31:0]	motor_fl_step_num;

	wire		motor_fr_ready;
	wire		motor_fr_step;
	reg		motor_fr_valid;
	reg		motor_fr_dir;
	reg [31:0]	motor_fr_freq_top;
	reg [31:0]	motor_fr_step_num;

	wire		motor_bl_ready;
	wire		motor_bl_step;
	reg		motor_bl_valid;
	reg		motor_bl_dir;
	reg [31:0]	motor_bl_freq_top;
	reg [31:0]	motor_bl_step_num;

	wire		motor_br_ready;
	wire		motor_br_step;
	reg		motor_br_valid;
	reg		motor_br_dir;
	reg [31:0]	motor_br_freq_top;
	reg [31:0]	motor_br_step_num;

	wire		motor_all_en;

	reg [31:0]	ir_command;
	wire		ir_ready;
	wire		ir_input;
	wire		ir_ack;

	assign motor_all_en = motor_fl_valid | motor_fr_valid | motor_bl_valid | motor_br_valid; // Enable ALL

	assign rst = key[3];
	assign led[0] = motor_fl_step | motor_fr_step | motor_bl_step | motor_br_step;
	assign led[1] = motor_fl_valid | motor_fr_valid | motor_bl_valid | motor_br_valid;
	assign led[2] = motor_fl_ready | motor_fr_ready | motor_bl_ready | motor_br_ready;
	assign led[3] = ir_ready;
	assign ir_input = gpio[2];

	// Connect motor drivers to their corresponding signal pins 

	assign gpio[6] = ~motor_all_en; 	// #Enable ALL
	assign gpio[7] = motor_fl_dir;		// ForwardLeftDIR
	assign gpio[9] = motor_fl_step;		// ForwardLeftSTEP
	assign gpio[10] = motor_fr_dir;		// ForwardRightDIR
	assign gpio[11] = motor_fr_step;	// ForwardRightSTEP
	assign gpio[12] = motor_bl_dir;		// BackwardLeftDIR
	assign gpio[13] = motor_bl_step;	// BackwardLeftSTEP
	assign gpio[14] = motor_br_dir;		// BackwardRightDIR
	assign gpio[15] = motor_br_step;	// BackwardRightSTEP

	ir_decoder decoder_samsung(
		.clk(clk25),
		.rst(rst),
		.ack(ir_ack),
		.enable('b1),
		.ir_input(ir_input),
		.ready(ir_ready),
		.command(ir_command)       
	);

	assign ir_ack = ir_ready;

	stepper motor_fl_stepper(
		.clk(clk25),
		.rst(rst),
		.valid(motor_fl_valid),
		.ready(motor_fl_ready),
		.one_step(motor_fl_step),
		.step_freq_top(motor_fl_freq_top),
		.step_num(motor_fl_step_num)
	);

	stepper motor_fr_stepper(
		.clk(clk25),
		.rst(rst),
		.valid(motor_fr_valid),
		.ready(motor_fr_ready),
		.one_step(motor_fr_step),
		.step_freq_top(motor_fr_freq_top),
		.step_num(motor_fr_step_num)
	);

	stepper motor_bl_stepper(
		.clk(clk25),
		.rst(rst),
		.valid(motor_bl_valid),
		.ready(motor_bl_ready),
		.one_step(motor_bl_step),
		.step_freq_top(motor_bl_freq_top),
		.step_num(motor_bl_step_num)
	);

	stepper motor_br_stepper(
		.clk(clk25),
		.rst(rst),
		.valid(motor_br_valid),
		.ready(motor_br_ready),
		.one_step(motor_br_step),
		.step_freq_top(motor_br_freq_top),
		.step_num(motor_br_step_num)
	);

	task motor_fl_task;
		input	[31:0] freq_top;
		input	[31:0] step_num;
		input	dir;
		begin
			motor_fl_freq_top <= freq_top;
			motor_fl_step_num <= step_num;
			motor_fl_dir <= dir;
			motor_fl_valid <= 1'b1;
		end
	endtask;

	task motor_fr_task;
		input	[31:0] freq_top;
		input	[31:0] step_num;
		input	dir;
		begin
			motor_fr_freq_top <= freq_top;
			motor_fr_step_num <= step_num;
			motor_fr_dir <= dir;
			motor_fr_valid <= 1'b1;
		end
	endtask;

	task motor_bl_task;
		input	[31:0] freq_top;
		input	[31:0] step_num;
		input	dir;
		begin
			motor_bl_freq_top <= freq_top;
			motor_bl_step_num <= step_num;
			motor_bl_dir <= dir;
			motor_bl_valid <= 1'b1;
		end
	endtask;

	task motor_br_task;
		input	[31:0] freq_top;
		input	[31:0] step_num;
		input	dir;
		begin
			motor_br_freq_top <= freq_top;
			motor_br_step_num <= step_num;
			motor_br_dir <= dir;
			motor_br_valid <= 1'b1;
		end
	endtask;

	always@(posedge clk25 or posedge rst) begin
		if(rst) begin
			motor_fl_task('d0, 'd0, 'd0);
			motor_fl_valid <= 'd0;

			motor_fr_task('d0, 'd0, 'd0);
			motor_fr_valid <= 'd0;

			motor_bl_task('d0, 'd0, 'd0);
			motor_bl_valid <= 'd0;

			motor_br_task('d0, 'd0, 'd0);
			motor_br_valid <= 'd0;
		end else begin
			if (key[0]) begin // Move forward 90 deg 
				motor_fl_task(
					BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
					MOTOR_STEPS,		// 90 * 16 * 30 = rotate 90 deg
					'd0);
				motor_fr_task(
					BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
					MOTOR_STEPS,		// 90 * 16 * 30 = rotate 90 deg
					'd0);
				motor_bl_task(
					BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
					MOTOR_STEPS,		// 90 * 16 * 30 = rotate 90 deg
					'd0);
				motor_br_task(
					BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
					MOTOR_STEPS,		// 90 * 16 * 30 = rotate 90 deg
					'd0);
			end

			if (key[1]) begin // STOP
				motor_fl_valid <= 'b0;
				motor_fr_valid <= 'b0;
				motor_bl_valid <= 'b0;
				motor_br_valid <= 'b0;
			end

 
			if (ir_ready) begin
				if (ir_command == 32'hFD020707 ||
				    ir_command == 32'h19E60707 ||
				    ir_command == 32'h97680707) begin // 'Power' - Emergency STOP
					motor_fl_valid <= 'b0;
					motor_fr_valid <= 'b0;
					motor_bl_valid <= 'b0;
					motor_br_valid <= 'b0;
				end

				if (ir_command == 32'h9F600707) begin // 'Up' - move forward 1/8
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 45 deg
						'd1);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 45 deg
						'd1);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 45 deg
						'd1);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 45 deg
						'd1);
				end

				if (ir_command == 32'h9E610707) begin // 'Down' - move backward 1/8
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 180 * 16 * 30 = rotate 180 deg
						'd0);
				end

				if (ir_command == 32'h9A650707) begin // 'Left' - strafe left
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
				end

				if (ir_command == 32'h9D620707) begin // 'Right' - strafe right
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
				end

				if (ir_command == 32'hD22D0707) begin // 'Exit' - Rotate Clockwise 
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
				end


				if (ir_command == 32'h86790707) begin // 'Home' - Rotate Counter-Clockwise 
					motor_fl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
					motor_fr_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_bl_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd0);
					motor_br_task(
						BASE_FREQ / 2 / MOTOR_FREQ,	// 16kHz
						MOTOR_STEPS,		// 100 * 16 * 30 = rotate 180 deg
						'd1);
				end
			end

			if (motor_fl_ready)
				motor_fl_valid <= 'b0;

			if (motor_fr_ready)
				motor_fr_valid <= 'b0;

			if (motor_bl_ready)
				motor_bl_valid <= 'b0;

			if (motor_br_ready)
				motor_br_valid <= 'b0;

		end
	end

endmodule


