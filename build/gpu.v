`timescale 1ns/1ns
`default_nettype none
module controller (
	clk,
	reset,
	consumer_read_valid,
	consumer_read_address,
	consumer_read_ready,
	consumer_read_data,
	consumer_write_valid,
	consumer_write_address,
	consumer_write_data,
	consumer_write_ready,
	mem_read_valid,
	mem_read_address,
	mem_read_ready,
	mem_read_data,
	mem_write_valid,
	mem_write_address,
	mem_write_data,
	mem_write_ready
);
	parameter ADDR_BITS = 8;
	parameter DATA_BITS = 16;
	parameter NUM_CONSUMERS = 4;
	parameter NUM_CHANNELS = 1;
	parameter WRITE_ENABLE = 1;
	input wire clk;
	input wire reset;
	input wire [NUM_CONSUMERS - 1:0] consumer_read_valid;
	input wire [(NUM_CONSUMERS * ADDR_BITS) - 1:0] consumer_read_address;
	output reg [NUM_CONSUMERS - 1:0] consumer_read_ready;
	output reg [(NUM_CONSUMERS * DATA_BITS) - 1:0] consumer_read_data;
	input wire [NUM_CONSUMERS - 1:0] consumer_write_valid;
	input wire [(NUM_CONSUMERS * ADDR_BITS) - 1:0] consumer_write_address;
	input wire [(NUM_CONSUMERS * DATA_BITS) - 1:0] consumer_write_data;
	output reg [NUM_CONSUMERS - 1:0] consumer_write_ready;
	output reg [NUM_CHANNELS - 1:0] mem_read_valid;
	output reg [(NUM_CHANNELS * ADDR_BITS) - 1:0] mem_read_address;
	input wire [NUM_CHANNELS - 1:0] mem_read_ready;
	input wire [(NUM_CHANNELS * DATA_BITS) - 1:0] mem_read_data;
	output reg [NUM_CHANNELS - 1:0] mem_write_valid;
	output reg [(NUM_CHANNELS * ADDR_BITS) - 1:0] mem_write_address;
	output reg [(NUM_CHANNELS * DATA_BITS) - 1:0] mem_write_data;
	input wire [NUM_CHANNELS - 1:0] mem_write_ready;
	localparam IDLE = 3'b000;
	localparam READ_WAITING = 3'b010;
	localparam WRITE_WAITING = 3'b011;
	localparam READ_RELAYING = 3'b100;
	localparam WRITE_RELAYING = 3'b101;
	reg [(NUM_CHANNELS * 3) - 1:0] controller_state;
	reg [(NUM_CHANNELS * $clog2(NUM_CONSUMERS)) - 1:0] current_consumer;
	reg [NUM_CONSUMERS - 1:0] channel_serving_consumer;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg [0:1] _sv2v_jump;
		_sv2v_jump = 2'b00;
		if (reset) begin
			mem_read_valid <= 0;
			mem_read_address <= 0;
			mem_write_valid <= 0;
			mem_write_address <= 0;
			mem_write_data <= 0;
			consumer_read_ready <= 0;
			consumer_read_data <= 0;
			consumer_write_ready <= 0;
			current_consumer <= 0;
			controller_state <= 0;
			channel_serving_consumer = 0;
		end
		else begin : sv2v_autoblock_2
			reg signed [31:0] i;
			begin : sv2v_autoblock_3
				reg signed [31:0] _sv2v_value_on_break;
				for (i = 0; i < NUM_CHANNELS; i = i + 1)
					if (_sv2v_jump < 2'b10) begin
						_sv2v_jump = 2'b00;
						case (controller_state[i * 3+:3])
							IDLE: begin : sv2v_autoblock_4
								reg signed [31:0] j;
								begin : sv2v_autoblock_5
									reg signed [31:0] _sv2v_value_on_break;
									reg [0:1] _sv2v_jump_1;
									_sv2v_jump_1 = _sv2v_jump;
									for (j = 0; j < NUM_CONSUMERS; j = j + 1)
										if (_sv2v_jump < 2'b10) begin
											_sv2v_jump = 2'b00;
											if (consumer_read_valid[j] && !channel_serving_consumer[j]) begin
												channel_serving_consumer[j] = 1;
												current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] <= j;
												mem_read_valid[i] <= 1;
												mem_read_address[i * ADDR_BITS+:ADDR_BITS] <= consumer_read_address[j * ADDR_BITS+:ADDR_BITS];
												controller_state[i * 3+:3] <= READ_WAITING;
												_sv2v_jump = 2'b10;
											end
											else if (consumer_write_valid[j] && !channel_serving_consumer[j]) begin
												channel_serving_consumer[j] = 1;
												current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] <= j;
												mem_write_valid[i] <= 1;
												mem_write_address[i * ADDR_BITS+:ADDR_BITS] <= consumer_write_address[j * ADDR_BITS+:ADDR_BITS];
												mem_write_data[i * DATA_BITS+:DATA_BITS] <= consumer_write_data[j * DATA_BITS+:DATA_BITS];
												controller_state[i * 3+:3] <= WRITE_WAITING;
												_sv2v_jump = 2'b10;
											end
											_sv2v_value_on_break = j;
										end
									if (!(_sv2v_jump < 2'b10))
										j = _sv2v_value_on_break;
									if (_sv2v_jump != 2'b11)
										_sv2v_jump = _sv2v_jump_1;
								end
							end
							READ_WAITING:
								if (mem_read_ready[i]) begin
									mem_read_valid[i] <= 0;
									consumer_read_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 1;
									consumer_read_data[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)] * DATA_BITS+:DATA_BITS] <= mem_read_data[i * DATA_BITS+:DATA_BITS];
									controller_state[i * 3+:3] <= READ_RELAYING;
								end
							WRITE_WAITING:
								if (mem_write_ready[i]) begin
									mem_write_valid[i] <= 0;
									consumer_write_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 1;
									controller_state[i * 3+:3] <= WRITE_RELAYING;
								end
							READ_RELAYING:
								if (!consumer_read_valid[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]]) begin
									channel_serving_consumer[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] = 0;
									consumer_read_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 0;
									controller_state[i * 3+:3] <= IDLE;
								end
							WRITE_RELAYING:
								if (!consumer_write_valid[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]]) begin
									channel_serving_consumer[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] = 0;
									consumer_write_ready[current_consumer[i * $clog2(NUM_CONSUMERS)+:$clog2(NUM_CONSUMERS)]] <= 0;
									controller_state[i * 3+:3] <= IDLE;
								end
						endcase
						_sv2v_value_on_break = i;
					end
				if (!(_sv2v_jump < 2'b10))
					i = _sv2v_value_on_break;
				if (_sv2v_jump != 2'b11)
					_sv2v_jump = 2'b00;
			end
		end
	end
endmodule
`default_nettype none
module core (
	clk,
	reset,
	start,
	done,
	block_id,
	thread_count,
	program_mem_read_valid,
	program_mem_read_address,
	program_mem_read_ready,
	program_mem_read_data,
	data_mem_read_valid,
	data_mem_read_address,
	data_mem_read_ready,
	data_mem_read_data,
	data_mem_write_valid,
	data_mem_write_address,
	data_mem_write_data,
	data_mem_write_ready
);
	parameter DATA_MEM_ADDR_BITS = 8;
	parameter DATA_MEM_DATA_BITS = 8;
	parameter PROGRAM_MEM_ADDR_BITS = 8;
	parameter PROGRAM_MEM_DATA_BITS = 16;
	parameter THREADS_PER_BLOCK = 4;
	input wire clk;
	input wire reset;
	input wire start;
	output wire done;
	input wire [7:0] block_id;
	input wire [$clog2(THREADS_PER_BLOCK):0] thread_count;
	output reg program_mem_read_valid;
	output reg [PROGRAM_MEM_ADDR_BITS - 1:0] program_mem_read_address;
	input wire program_mem_read_ready;
	input wire [PROGRAM_MEM_DATA_BITS - 1:0] program_mem_read_data;
	output reg [THREADS_PER_BLOCK - 1:0] data_mem_read_valid;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] data_mem_read_address;
	input wire [THREADS_PER_BLOCK - 1:0] data_mem_read_ready;
	input wire [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] data_mem_read_data;
	output reg [THREADS_PER_BLOCK - 1:0] data_mem_write_valid;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] data_mem_write_address;
	output reg [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] data_mem_write_data;
	input wire [THREADS_PER_BLOCK - 1:0] data_mem_write_ready;
	reg [2:0] core_state;
	reg [2:0] fetcher_state;
	reg [15:0] instruction;
	reg [7:0] current_pc;
	wire [(THREADS_PER_BLOCK * 8) - 1:0] next_pc;
	reg [7:0] rs [THREADS_PER_BLOCK - 1:0];
	reg [7:0] rt [THREADS_PER_BLOCK - 1:0];
	reg [(THREADS_PER_BLOCK * 2) - 1:0] lsu_state;
	reg [7:0] lsu_out [THREADS_PER_BLOCK - 1:0];
	wire [7:0] alu_out [THREADS_PER_BLOCK - 1:0];
	reg [3:0] decoded_rd_address;
	reg [3:0] decoded_rs_address;
	reg [3:0] decoded_rt_address;
	reg [2:0] decoded_nzp;
	reg [7:0] decoded_immediate;
	reg decoded_reg_write_enable;
	reg decoded_mem_read_enable;
	reg decoded_mem_write_enable;
	reg decoded_nzp_write_enable;
	reg [1:0] decoded_reg_input_mux;
	reg [1:0] decoded_alu_arithmetic_mux;
	reg decoded_alu_output_mux;
	reg decoded_pc_mux;
	reg decoded_ret;
	wire [1:1] sv2v_tmp_fetcher_i_mem_read_valid;
	always @(*) program_mem_read_valid = sv2v_tmp_fetcher_i_mem_read_valid;
	wire [PROGRAM_MEM_ADDR_BITS:1] sv2v_tmp_fetcher_i_mem_read_address;
	always @(*) program_mem_read_address = sv2v_tmp_fetcher_i_mem_read_address;
	wire [3:1] sv2v_tmp_fetcher_i_fetcher_state;
	always @(*) fetcher_state = sv2v_tmp_fetcher_i_fetcher_state;
	wire [16:1] sv2v_tmp_fetcher_i_instruction;
	always @(*) instruction = sv2v_tmp_fetcher_i_instruction;
	fetcher #(
		.PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
		.PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS)
	) fetcher_i(
		.clk(clk),
		.reset(reset),
		.core_state(core_state),
		.current_pc(current_pc),
		.mem_read_valid(sv2v_tmp_fetcher_i_mem_read_valid),
		.mem_read_address(sv2v_tmp_fetcher_i_mem_read_address),
		.mem_read_ready(program_mem_read_ready),
		.mem_read_data(program_mem_read_data),
		.fetcher_state(sv2v_tmp_fetcher_i_fetcher_state),
		.instruction(sv2v_tmp_fetcher_i_instruction)
	);
	wire [4:1] sv2v_tmp_decoder_inst_decoded_rd_address;
	always @(*) decoded_rd_address = sv2v_tmp_decoder_inst_decoded_rd_address;
	wire [4:1] sv2v_tmp_decoder_inst_decoded_rs_address;
	always @(*) decoded_rs_address = sv2v_tmp_decoder_inst_decoded_rs_address;
	wire [4:1] sv2v_tmp_decoder_inst_decoded_rt_address;
	always @(*) decoded_rt_address = sv2v_tmp_decoder_inst_decoded_rt_address;
	wire [3:1] sv2v_tmp_decoder_inst_decoded_nzp;
	always @(*) decoded_nzp = sv2v_tmp_decoder_inst_decoded_nzp;
	wire [8:1] sv2v_tmp_decoder_inst_decoded_immediate;
	always @(*) decoded_immediate = sv2v_tmp_decoder_inst_decoded_immediate;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_reg_write_enable;
	always @(*) decoded_reg_write_enable = sv2v_tmp_decoder_inst_decoded_reg_write_enable;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_mem_read_enable;
	always @(*) decoded_mem_read_enable = sv2v_tmp_decoder_inst_decoded_mem_read_enable;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_mem_write_enable;
	always @(*) decoded_mem_write_enable = sv2v_tmp_decoder_inst_decoded_mem_write_enable;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_nzp_write_enable;
	always @(*) decoded_nzp_write_enable = sv2v_tmp_decoder_inst_decoded_nzp_write_enable;
	wire [2:1] sv2v_tmp_decoder_inst_decoded_reg_input_mux;
	always @(*) decoded_reg_input_mux = sv2v_tmp_decoder_inst_decoded_reg_input_mux;
	wire [2:1] sv2v_tmp_decoder_inst_decoded_alu_arithmetic_mux;
	always @(*) decoded_alu_arithmetic_mux = sv2v_tmp_decoder_inst_decoded_alu_arithmetic_mux;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_alu_output_mux;
	always @(*) decoded_alu_output_mux = sv2v_tmp_decoder_inst_decoded_alu_output_mux;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_pc_mux;
	always @(*) decoded_pc_mux = sv2v_tmp_decoder_inst_decoded_pc_mux;
	wire [1:1] sv2v_tmp_decoder_inst_decoded_ret;
	always @(*) decoded_ret = sv2v_tmp_decoder_inst_decoded_ret;
	decoder decoder_inst(
		.clk(clk),
		.reset(reset),
		.core_state(core_state),
		.instruction(instruction),
		.decoded_rd_address(sv2v_tmp_decoder_inst_decoded_rd_address),
		.decoded_rs_address(sv2v_tmp_decoder_inst_decoded_rs_address),
		.decoded_rt_address(sv2v_tmp_decoder_inst_decoded_rt_address),
		.decoded_nzp(sv2v_tmp_decoder_inst_decoded_nzp),
		.decoded_immediate(sv2v_tmp_decoder_inst_decoded_immediate),
		.decoded_reg_write_enable(sv2v_tmp_decoder_inst_decoded_reg_write_enable),
		.decoded_mem_read_enable(sv2v_tmp_decoder_inst_decoded_mem_read_enable),
		.decoded_mem_write_enable(sv2v_tmp_decoder_inst_decoded_mem_write_enable),
		.decoded_nzp_write_enable(sv2v_tmp_decoder_inst_decoded_nzp_write_enable),
		.decoded_reg_input_mux(sv2v_tmp_decoder_inst_decoded_reg_input_mux),
		.decoded_alu_arithmetic_mux(sv2v_tmp_decoder_inst_decoded_alu_arithmetic_mux),
		.decoded_alu_output_mux(sv2v_tmp_decoder_inst_decoded_alu_output_mux),
		.decoded_pc_mux(sv2v_tmp_decoder_inst_decoded_pc_mux),
		.decoded_ret(sv2v_tmp_decoder_inst_decoded_ret)
	);
	wire [3:1] sv2v_tmp_scheduler_inst_core_state;
	always @(*) core_state = sv2v_tmp_scheduler_inst_core_state;
	wire [8:1] sv2v_tmp_scheduler_inst_current_pc;
	always @(*) current_pc = sv2v_tmp_scheduler_inst_current_pc;
	scheduler #(.THREADS_PER_BLOCK(THREADS_PER_BLOCK)) scheduler_inst(
		.clk(clk),
		.reset(reset),
		.start(start),
		.fetcher_state(fetcher_state),
		.core_state(sv2v_tmp_scheduler_inst_core_state),
		.decoded_mem_read_enable(decoded_mem_read_enable),
		.decoded_mem_write_enable(decoded_mem_write_enable),
		.decoded_ret(decoded_ret),
		.lsu_state(lsu_state),
		.current_pc(sv2v_tmp_scheduler_inst_current_pc),
		.next_pc(next_pc),
		.done(done)
	);
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < THREADS_PER_BLOCK; _gv_i_1 = _gv_i_1 + 1) begin : threads
			localparam i = _gv_i_1;
			alu alu_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_alu_arithmetic_mux(decoded_alu_arithmetic_mux),
				.decoded_alu_output_mux(decoded_alu_output_mux),
				.rs(rs[i]),
				.rt(rt[i]),
				.alu_out(alu_out[i])
			);
			wire [1:1] sv2v_tmp_lsu_instance_mem_read_valid;
			always @(*) data_mem_read_valid[i] = sv2v_tmp_lsu_instance_mem_read_valid;
			wire [DATA_MEM_ADDR_BITS * 1:1] sv2v_tmp_lsu_instance_mem_read_address;
			always @(*) data_mem_read_address[i * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS] = sv2v_tmp_lsu_instance_mem_read_address;
			wire [1:1] sv2v_tmp_lsu_instance_mem_write_valid;
			always @(*) data_mem_write_valid[i] = sv2v_tmp_lsu_instance_mem_write_valid;
			wire [DATA_MEM_ADDR_BITS * 1:1] sv2v_tmp_lsu_instance_mem_write_address;
			always @(*) data_mem_write_address[i * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS] = sv2v_tmp_lsu_instance_mem_write_address;
			wire [DATA_MEM_DATA_BITS * 1:1] sv2v_tmp_lsu_instance_mem_write_data;
			always @(*) data_mem_write_data[i * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS] = sv2v_tmp_lsu_instance_mem_write_data;
			wire [2:1] sv2v_tmp_lsu_instance_lsu_state;
			always @(*) lsu_state[i * 2+:2] = sv2v_tmp_lsu_instance_lsu_state;
			wire [8:1] sv2v_tmp_lsu_instance_lsu_out;
			always @(*) lsu_out[i] = sv2v_tmp_lsu_instance_lsu_out;
			lsu lsu_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_mem_read_enable(decoded_mem_read_enable),
				.decoded_mem_write_enable(decoded_mem_write_enable),
				.mem_read_valid(sv2v_tmp_lsu_instance_mem_read_valid),
				.mem_read_address(sv2v_tmp_lsu_instance_mem_read_address),
				.mem_read_ready(data_mem_read_ready[i]),
				.mem_read_data(data_mem_read_data[i * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS]),
				.mem_write_valid(sv2v_tmp_lsu_instance_mem_write_valid),
				.mem_write_address(sv2v_tmp_lsu_instance_mem_write_address),
				.mem_write_data(sv2v_tmp_lsu_instance_mem_write_data),
				.mem_write_ready(data_mem_write_ready[i]),
				.rs(rs[i]),
				.rt(rt[i]),
				.lsu_state(sv2v_tmp_lsu_instance_lsu_state),
				.lsu_out(sv2v_tmp_lsu_instance_lsu_out)
			);
			wire [8:1] sv2v_tmp_register_instance_rs;
			always @(*) rs[i] = sv2v_tmp_register_instance_rs;
			wire [8:1] sv2v_tmp_register_instance_rt;
			always @(*) rt[i] = sv2v_tmp_register_instance_rt;
			registers #(
				.THREADS_PER_BLOCK(THREADS_PER_BLOCK),
				.THREAD_ID(i),
				.DATA_BITS(DATA_MEM_DATA_BITS)
			) register_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.block_id(block_id),
				.core_state(core_state),
				.decoded_reg_write_enable(decoded_reg_write_enable),
				.decoded_reg_input_mux(decoded_reg_input_mux),
				.decoded_rd_address(decoded_rd_address),
				.decoded_rs_address(decoded_rs_address),
				.decoded_rt_address(decoded_rt_address),
				.decoded_immediate(decoded_immediate),
				.alu_out(alu_out[i]),
				.lsu_out(lsu_out[i]),
				.rs(sv2v_tmp_register_instance_rs),
				.rt(sv2v_tmp_register_instance_rt)
			);
			pc #(
				.DATA_MEM_DATA_BITS(DATA_MEM_DATA_BITS),
				.PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS)
			) pc_instance(
				.clk(clk),
				.reset(reset),
				.enable(i < thread_count),
				.core_state(core_state),
				.decoded_nzp(decoded_nzp),
				.decoded_immediate(decoded_immediate),
				.decoded_nzp_write_enable(decoded_nzp_write_enable),
				.decoded_pc_mux(decoded_pc_mux),
				.alu_out(alu_out[i]),
				.current_pc(current_pc),
				.next_pc(next_pc[i * 8+:8])
			);
		end
	endgenerate
endmodule
`default_nettype none
module dcr (
	clk,
	reset,
	device_control_write_enable,
	device_control_data,
	thread_count
);
	input wire clk;
	input wire reset;
	input wire device_control_write_enable;
	input wire [7:0] device_control_data;
	output wire [7:0] thread_count;
	reg [7:0] device_control_register;
	assign thread_count = device_control_register[7:0];
	always @(posedge clk)
		if (reset)
			device_control_register <= 8'b00000000;
		else if (device_control_write_enable)
			device_control_register <= device_control_data;
endmodule
`default_nettype none
module decoder (
	clk,
	reset,
	core_state,
	instruction,
	decoded_rd_address,
	decoded_rs_address,
	decoded_rt_address,
	decoded_nzp,
	decoded_immediate,
	decoded_reg_write_enable,
	decoded_mem_read_enable,
	decoded_mem_write_enable,
	decoded_nzp_write_enable,
	decoded_reg_input_mux,
	decoded_alu_arithmetic_mux,
	decoded_alu_output_mux,
	decoded_pc_mux,
	decoded_ret
);
	input wire clk;
	input wire reset;
	input wire [2:0] core_state;
	input wire [15:0] instruction;
	output reg [3:0] decoded_rd_address;
	output reg [3:0] decoded_rs_address;
	output reg [3:0] decoded_rt_address;
	output reg [2:0] decoded_nzp;
	output reg [7:0] decoded_immediate;
	output reg decoded_reg_write_enable;
	output reg decoded_mem_read_enable;
	output reg decoded_mem_write_enable;
	output reg decoded_nzp_write_enable;
	output reg [1:0] decoded_reg_input_mux;
	output reg [1:0] decoded_alu_arithmetic_mux;
	output reg decoded_alu_output_mux;
	output reg decoded_pc_mux;
	output reg decoded_ret;
	localparam NOP = 4'b0000;
	localparam BRnzp = 4'b0001;
	localparam CMP = 4'b0010;
	localparam ADD = 4'b0011;
	localparam SUB = 4'b0100;
	localparam MUL = 4'b0101;
	localparam DIV = 4'b0110;
	localparam LDR = 4'b0111;
	localparam STR = 4'b1000;
	localparam CONST = 4'b1001;
	localparam RET = 4'b1111;
	always @(posedge clk)
		if (reset) begin
			decoded_rd_address <= 0;
			decoded_rs_address <= 0;
			decoded_rt_address <= 0;
			decoded_immediate <= 0;
			decoded_nzp <= 0;
			decoded_reg_write_enable <= 0;
			decoded_mem_read_enable <= 0;
			decoded_mem_write_enable <= 0;
			decoded_nzp_write_enable <= 0;
			decoded_reg_input_mux <= 0;
			decoded_alu_arithmetic_mux <= 0;
			decoded_alu_output_mux <= 0;
			decoded_pc_mux <= 0;
			decoded_ret <= 0;
		end
		else if (core_state == 3'b010) begin
			decoded_rd_address <= instruction[11:8];
			decoded_rs_address <= instruction[7:4];
			decoded_rt_address <= instruction[3:0];
			decoded_immediate <= instruction[7:0];
			decoded_nzp <= instruction[11:9];
			decoded_reg_write_enable <= 0;
			decoded_mem_read_enable <= 0;
			decoded_mem_write_enable <= 0;
			decoded_nzp_write_enable <= 0;
			decoded_reg_input_mux <= 0;
			decoded_alu_arithmetic_mux <= 0;
			decoded_alu_output_mux <= 0;
			decoded_pc_mux <= 0;
			decoded_ret <= 0;
			case (instruction[15:12])
				NOP:
					;
				BRnzp: decoded_pc_mux <= 1;
				CMP: begin
					decoded_alu_output_mux <= 1;
					decoded_nzp_write_enable <= 1;
				end
				ADD: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b00;
					decoded_alu_arithmetic_mux <= 2'b00;
				end
				SUB: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b00;
					decoded_alu_arithmetic_mux <= 2'b01;
				end
				MUL: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b00;
					decoded_alu_arithmetic_mux <= 2'b10;
				end
				DIV: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b00;
					decoded_alu_arithmetic_mux <= 2'b11;
				end
				LDR: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b01;
					decoded_mem_read_enable <= 1;
				end
				STR: decoded_mem_write_enable <= 1;
				CONST: begin
					decoded_reg_write_enable <= 1;
					decoded_reg_input_mux <= 2'b10;
				end
				RET: decoded_ret <= 1;
			endcase
		end
endmodule
`default_nettype none
module dispatch (
	clk,
	reset,
	start,
	thread_count,
	core_done,
	core_start,
	core_reset,
	core_block_id,
	core_thread_count,
	done
);
	parameter NUM_CORES = 2;
	parameter THREADS_PER_BLOCK = 4;
	input wire clk;
	input wire reset;
	input wire start;
	input wire [7:0] thread_count;
	input wire [NUM_CORES - 1:0] core_done;
	output reg [NUM_CORES - 1:0] core_start;
	output reg [NUM_CORES - 1:0] core_reset;
	output reg [(NUM_CORES * 8) - 1:0] core_block_id;
	output reg [($clog2(THREADS_PER_BLOCK) >= 0 ? (NUM_CORES * ($clog2(THREADS_PER_BLOCK) + 1)) - 1 : (NUM_CORES * (1 - $clog2(THREADS_PER_BLOCK))) + ($clog2(THREADS_PER_BLOCK) - 1)):($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK) + 0)] core_thread_count;
	output reg done;
	wire [7:0] total_blocks;
	assign total_blocks = ((thread_count + THREADS_PER_BLOCK) - 1) / THREADS_PER_BLOCK;
	reg [7:0] blocks_dispatched;
	reg [7:0] blocks_done;
	reg start_execution;
	always @(posedge clk)
		if (reset) begin
			done <= 0;
			blocks_dispatched <= 0;
			blocks_done <= 0;
			start_execution <= 0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < NUM_CORES; i = i + 1)
					begin
						core_start[i] <= 0;
						core_reset[i] <= 1;
						core_block_id[i * 8+:8] <= 0;
						core_thread_count[($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK)) + (i * ($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK)))+:($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK))] <= THREADS_PER_BLOCK;
					end
			end
		end
		else if (start) begin
			if (!start_execution) begin
				start_execution <= 1;
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 0; i < NUM_CORES; i = i + 1)
						core_reset[i] <= 1;
				end
			end
			if (blocks_done == total_blocks)
				done <= 1;
			begin : sv2v_autoblock_3
				reg signed [31:0] i;
				for (i = 0; i < NUM_CORES; i = i + 1)
					if (core_reset[i]) begin
						core_reset[i] = 0;
						if (blocks_dispatched < total_blocks) begin
							core_start[i] <= 1;
							core_block_id[i * 8+:8] <= blocks_dispatched;
							core_thread_count[($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK)) + (i * ($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK)))+:($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK))] <= (blocks_dispatched == (total_blocks - 1) ? thread_count - (blocks_dispatched * THREADS_PER_BLOCK) : THREADS_PER_BLOCK);
							blocks_dispatched = blocks_dispatched + 1;
						end
					end
			end
			begin : sv2v_autoblock_4
				reg signed [31:0] i;
				for (i = 0; i < NUM_CORES; i = i + 1)
					if (core_start[i] && core_done[i]) begin
						core_reset[i] <= 1;
						core_start[i] <= 0;
						blocks_done = blocks_done + 1;
					end
			end
		end
endmodule
`default_nettype none
module fetcher (
	clk,
	reset,
	core_state,
	current_pc,
	mem_read_valid,
	mem_read_address,
	mem_read_ready,
	mem_read_data,
	fetcher_state,
	instruction
);
	parameter PROGRAM_MEM_ADDR_BITS = 8;
	parameter PROGRAM_MEM_DATA_BITS = 16;
	input wire clk;
	input wire reset;
	input wire [2:0] core_state;
	input wire [7:0] current_pc;
	output reg mem_read_valid;
	output reg [PROGRAM_MEM_ADDR_BITS - 1:0] mem_read_address;
	input wire mem_read_ready;
	input wire [PROGRAM_MEM_DATA_BITS - 1:0] mem_read_data;
	output reg [2:0] fetcher_state;
	output reg [PROGRAM_MEM_DATA_BITS - 1:0] instruction;
	localparam IDLE = 3'b000;
	localparam FETCHING = 3'b001;
	localparam FETCHED = 3'b010;
	always @(posedge clk)
		if (reset) begin
			fetcher_state <= IDLE;
			mem_read_valid <= 0;
			mem_read_address <= 0;
			instruction <= {PROGRAM_MEM_DATA_BITS {1'b0}};
		end
		else
			case (fetcher_state)
				IDLE:
					if (core_state == 3'b001) begin
						fetcher_state <= FETCHING;
						mem_read_valid <= 1;
						mem_read_address <= current_pc;
					end
				FETCHING:
					if (mem_read_ready) begin
						fetcher_state <= FETCHED;
						instruction <= mem_read_data;
						mem_read_valid <= 0;
					end
				FETCHED:
					if (core_state == 3'b010)
						fetcher_state <= IDLE;
			endcase
endmodule
`default_nettype none
module gpu (
	clk,
	reset,
	start,
	done,
	device_control_write_enable,
	device_control_data,
	program_mem_read_valid,
	program_mem_read_address,
	program_mem_read_ready,
	program_mem_read_data,
	data_mem_read_valid,
	data_mem_read_address,
	data_mem_read_ready,
	data_mem_read_data,
	data_mem_write_valid,
	data_mem_write_address,
	data_mem_write_data,
	data_mem_write_ready
);
	parameter DATA_MEM_ADDR_BITS = 8;
	parameter DATA_MEM_DATA_BITS = 8;
	parameter DATA_MEM_NUM_CHANNELS = 4;
	parameter PROGRAM_MEM_ADDR_BITS = 8;
	parameter PROGRAM_MEM_DATA_BITS = 16;
	parameter PROGRAM_MEM_NUM_CHANNELS = 1;
	parameter NUM_CORES = 2;
	parameter THREADS_PER_BLOCK = 4;
	input wire clk;
	input wire reset;
	input wire start;
	output wire done;
	input wire device_control_write_enable;
	input wire [7:0] device_control_data;
	output wire [PROGRAM_MEM_NUM_CHANNELS - 1:0] program_mem_read_valid;
	output wire [(PROGRAM_MEM_NUM_CHANNELS * PROGRAM_MEM_ADDR_BITS) - 1:0] program_mem_read_address;
	input wire [PROGRAM_MEM_NUM_CHANNELS - 1:0] program_mem_read_ready;
	input wire [(PROGRAM_MEM_NUM_CHANNELS * PROGRAM_MEM_DATA_BITS) - 1:0] program_mem_read_data;
	output wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_read_valid;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_ADDR_BITS) - 1:0] data_mem_read_address;
	input wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_read_ready;
	input wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_DATA_BITS) - 1:0] data_mem_read_data;
	output wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_write_valid;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_ADDR_BITS) - 1:0] data_mem_write_address;
	output wire [(DATA_MEM_NUM_CHANNELS * DATA_MEM_DATA_BITS) - 1:0] data_mem_write_data;
	input wire [DATA_MEM_NUM_CHANNELS - 1:0] data_mem_write_ready;
	wire [7:0] thread_count;
	reg [NUM_CORES - 1:0] core_start;
	reg [NUM_CORES - 1:0] core_reset;
	reg [NUM_CORES - 1:0] core_done;
	reg [(NUM_CORES * 8) - 1:0] core_block_id;
	reg [($clog2(THREADS_PER_BLOCK) >= 0 ? (NUM_CORES * ($clog2(THREADS_PER_BLOCK) + 1)) - 1 : (NUM_CORES * (1 - $clog2(THREADS_PER_BLOCK))) + ($clog2(THREADS_PER_BLOCK) - 1)):($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK) + 0)] core_thread_count;
	localparam NUM_LSUS = NUM_CORES * THREADS_PER_BLOCK;
	reg [NUM_LSUS - 1:0] lsu_read_valid;
	reg [(NUM_LSUS * DATA_MEM_ADDR_BITS) - 1:0] lsu_read_address;
	reg [NUM_LSUS - 1:0] lsu_read_ready;
	reg [(NUM_LSUS * DATA_MEM_DATA_BITS) - 1:0] lsu_read_data;
	reg [NUM_LSUS - 1:0] lsu_write_valid;
	reg [(NUM_LSUS * DATA_MEM_ADDR_BITS) - 1:0] lsu_write_address;
	reg [(NUM_LSUS * DATA_MEM_DATA_BITS) - 1:0] lsu_write_data;
	reg [NUM_LSUS - 1:0] lsu_write_ready;
	localparam NUM_FETCHERS = NUM_CORES;
	reg [NUM_FETCHERS - 1:0] fetcher_read_valid;
	reg [(NUM_FETCHERS * PROGRAM_MEM_ADDR_BITS) - 1:0] fetcher_read_address;
	reg [NUM_FETCHERS - 1:0] fetcher_read_ready;
	reg [(NUM_FETCHERS * PROGRAM_MEM_DATA_BITS) - 1:0] fetcher_read_data;
	dcr dcr_ins(
		.clk(clk),
		.reset(reset),
		.device_control_write_enable(device_control_write_enable),
		.device_control_data(device_control_data),
		.thread_count(thread_count)
	);
	wire [NUM_LSUS:1] sv2v_tmp_data_memory_controller_consumer_read_ready;
	always @(*) lsu_read_ready = sv2v_tmp_data_memory_controller_consumer_read_ready;
	wire [NUM_LSUS * DATA_MEM_DATA_BITS:1] sv2v_tmp_data_memory_controller_consumer_read_data;
	always @(*) lsu_read_data = sv2v_tmp_data_memory_controller_consumer_read_data;
	wire [NUM_LSUS:1] sv2v_tmp_data_memory_controller_consumer_write_ready;
	always @(*) lsu_write_ready = sv2v_tmp_data_memory_controller_consumer_write_ready;
	controller #(
		.ADDR_BITS(DATA_MEM_ADDR_BITS),
		.DATA_BITS(DATA_MEM_DATA_BITS),
		.NUM_CONSUMERS(NUM_LSUS),
		.NUM_CHANNELS(DATA_MEM_NUM_CHANNELS)
	) data_memory_controller(
		.clk(clk),
		.reset(reset),
		.consumer_read_valid(lsu_read_valid),
		.consumer_read_address(lsu_read_address),
		.consumer_read_ready(sv2v_tmp_data_memory_controller_consumer_read_ready),
		.consumer_read_data(sv2v_tmp_data_memory_controller_consumer_read_data),
		.consumer_write_valid(lsu_write_valid),
		.consumer_write_address(lsu_write_address),
		.consumer_write_data(lsu_write_data),
		.consumer_write_ready(sv2v_tmp_data_memory_controller_consumer_write_ready),
		.mem_read_valid(data_mem_read_valid),
		.mem_read_address(data_mem_read_address),
		.mem_read_ready(data_mem_read_ready),
		.mem_read_data(data_mem_read_data),
		.mem_write_valid(data_mem_write_valid),
		.mem_write_address(data_mem_write_address),
		.mem_write_data(data_mem_write_data),
		.mem_write_ready(data_mem_write_ready)
	);
	wire [NUM_FETCHERS:1] sv2v_tmp_program_memory_controller_consumer_read_ready;
	always @(*) fetcher_read_ready = sv2v_tmp_program_memory_controller_consumer_read_ready;
	wire [NUM_FETCHERS * PROGRAM_MEM_DATA_BITS:1] sv2v_tmp_program_memory_controller_consumer_read_data;
	always @(*) fetcher_read_data = sv2v_tmp_program_memory_controller_consumer_read_data;
	controller #(
		.ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
		.DATA_BITS(PROGRAM_MEM_DATA_BITS),
		.NUM_CONSUMERS(NUM_FETCHERS),
		.NUM_CHANNELS(PROGRAM_MEM_NUM_CHANNELS),
		.WRITE_ENABLE(0)
	) program_memory_controller(
		.clk(clk),
		.reset(reset),
		.consumer_read_valid(fetcher_read_valid),
		.consumer_read_address(fetcher_read_address),
		.consumer_read_ready(sv2v_tmp_program_memory_controller_consumer_read_ready),
		.consumer_read_data(sv2v_tmp_program_memory_controller_consumer_read_data),
		.mem_read_valid(program_mem_read_valid),
		.mem_read_address(program_mem_read_address),
		.mem_read_ready(program_mem_read_ready),
		.mem_read_data(program_mem_read_data)
	);
	wire [NUM_CORES:1] sv2v_tmp_dispatch_instance_core_start;
	always @(*) core_start = sv2v_tmp_dispatch_instance_core_start;
	wire [NUM_CORES:1] sv2v_tmp_dispatch_instance_core_reset;
	always @(*) core_reset = sv2v_tmp_dispatch_instance_core_reset;
	wire [NUM_CORES * 8:1] sv2v_tmp_dispatch_instance_core_block_id;
	always @(*) core_block_id = sv2v_tmp_dispatch_instance_core_block_id;
	wire [(($clog2(THREADS_PER_BLOCK) >= 0 ? (NUM_CORES * ($clog2(THREADS_PER_BLOCK) + 1)) - 1 : (NUM_CORES * (1 - $clog2(THREADS_PER_BLOCK))) + ($clog2(THREADS_PER_BLOCK) - 1)) >= ($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK) + 0) ? (($clog2(THREADS_PER_BLOCK) >= 0 ? (NUM_CORES * ($clog2(THREADS_PER_BLOCK) + 1)) - 1 : (NUM_CORES * (1 - $clog2(THREADS_PER_BLOCK))) + ($clog2(THREADS_PER_BLOCK) - 1)) - ($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK) + 0)) + 1 : (($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK) + 0) - ($clog2(THREADS_PER_BLOCK) >= 0 ? (NUM_CORES * ($clog2(THREADS_PER_BLOCK) + 1)) - 1 : (NUM_CORES * (1 - $clog2(THREADS_PER_BLOCK))) + ($clog2(THREADS_PER_BLOCK) - 1))) + 1):1] sv2v_tmp_dispatch_instance_core_thread_count;
	always @(*) core_thread_count = sv2v_tmp_dispatch_instance_core_thread_count;
	dispatch #(
		.NUM_CORES(NUM_CORES),
		.THREADS_PER_BLOCK(THREADS_PER_BLOCK)
	) dispatch_instance(
		.clk(clk),
		.reset(reset),
		.start(start),
		.thread_count(thread_count),
		.core_done(core_done),
		.core_start(sv2v_tmp_dispatch_instance_core_start),
		.core_reset(sv2v_tmp_dispatch_instance_core_reset),
		.core_block_id(sv2v_tmp_dispatch_instance_core_block_id),
		.core_thread_count(sv2v_tmp_dispatch_instance_core_thread_count),
		.done(done)
	);
	genvar _gv_i_2;
	generate
		for (_gv_i_2 = 0; _gv_i_2 < NUM_CORES; _gv_i_2 = _gv_i_2 + 1) begin : cores
			localparam i = _gv_i_2;
			reg [THREADS_PER_BLOCK - 1:0] core_lsu_read_valid;
			reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] core_lsu_read_address;
			reg [THREADS_PER_BLOCK - 1:0] core_lsu_read_ready;
			reg [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] core_lsu_read_data;
			reg [THREADS_PER_BLOCK - 1:0] core_lsu_write_valid;
			reg [(THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS) - 1:0] core_lsu_write_address;
			reg [(THREADS_PER_BLOCK * DATA_MEM_DATA_BITS) - 1:0] core_lsu_write_data;
			reg [THREADS_PER_BLOCK - 1:0] core_lsu_write_ready;
			genvar _gv_j_1;
			for (_gv_j_1 = 0; _gv_j_1 < THREADS_PER_BLOCK; _gv_j_1 = _gv_j_1 + 1) begin : genblk1
				localparam j = _gv_j_1;
				localparam lsu_index = (i * THREADS_PER_BLOCK) + j;
				always @(posedge clk) begin
					lsu_read_valid[lsu_index] <= core_lsu_read_valid[j];
					lsu_read_address[lsu_index * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS] <= core_lsu_read_address[j * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS];
					lsu_write_valid[lsu_index] <= core_lsu_write_valid[j];
					lsu_write_address[lsu_index * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS] <= core_lsu_write_address[j * DATA_MEM_ADDR_BITS+:DATA_MEM_ADDR_BITS];
					lsu_write_data[lsu_index * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS] <= core_lsu_write_data[j * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS];
					core_lsu_read_ready[j] <= lsu_read_ready[lsu_index];
					core_lsu_read_data[j * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS] <= lsu_read_data[lsu_index * DATA_MEM_DATA_BITS+:DATA_MEM_DATA_BITS];
					core_lsu_write_ready[j] <= lsu_write_ready[lsu_index];
				end
			end
			wire [1:1] sv2v_tmp_core_instance_done;
			always @(*) core_done[i] = sv2v_tmp_core_instance_done;
			wire [1:1] sv2v_tmp_core_instance_program_mem_read_valid;
			always @(*) fetcher_read_valid[i] = sv2v_tmp_core_instance_program_mem_read_valid;
			wire [PROGRAM_MEM_ADDR_BITS * 1:1] sv2v_tmp_core_instance_program_mem_read_address;
			always @(*) fetcher_read_address[i * PROGRAM_MEM_ADDR_BITS+:PROGRAM_MEM_ADDR_BITS] = sv2v_tmp_core_instance_program_mem_read_address;
			wire [THREADS_PER_BLOCK:1] sv2v_tmp_core_instance_data_mem_read_valid;
			always @(*) core_lsu_read_valid = sv2v_tmp_core_instance_data_mem_read_valid;
			wire [THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS:1] sv2v_tmp_core_instance_data_mem_read_address;
			always @(*) core_lsu_read_address = sv2v_tmp_core_instance_data_mem_read_address;
			wire [THREADS_PER_BLOCK:1] sv2v_tmp_core_instance_data_mem_write_valid;
			always @(*) core_lsu_write_valid = sv2v_tmp_core_instance_data_mem_write_valid;
			wire [THREADS_PER_BLOCK * DATA_MEM_ADDR_BITS:1] sv2v_tmp_core_instance_data_mem_write_address;
			always @(*) core_lsu_write_address = sv2v_tmp_core_instance_data_mem_write_address;
			wire [THREADS_PER_BLOCK * DATA_MEM_DATA_BITS:1] sv2v_tmp_core_instance_data_mem_write_data;
			always @(*) core_lsu_write_data = sv2v_tmp_core_instance_data_mem_write_data;
			core #(
				.DATA_MEM_ADDR_BITS(DATA_MEM_ADDR_BITS),
				.DATA_MEM_DATA_BITS(DATA_MEM_DATA_BITS),
				.PROGRAM_MEM_ADDR_BITS(PROGRAM_MEM_ADDR_BITS),
				.PROGRAM_MEM_DATA_BITS(PROGRAM_MEM_DATA_BITS),
				.THREADS_PER_BLOCK(THREADS_PER_BLOCK)
			) core_instance(
				.clk(clk),
				.reset(core_reset[i]),
				.start(core_start[i]),
				.done(sv2v_tmp_core_instance_done),
				.block_id(core_block_id[i * 8+:8]),
				.thread_count(core_thread_count[($clog2(THREADS_PER_BLOCK) >= 0 ? 0 : $clog2(THREADS_PER_BLOCK)) + (i * ($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK)))+:($clog2(THREADS_PER_BLOCK) >= 0 ? $clog2(THREADS_PER_BLOCK) + 1 : 1 - $clog2(THREADS_PER_BLOCK))]),
				.program_mem_read_valid(sv2v_tmp_core_instance_program_mem_read_valid),
				.program_mem_read_address(sv2v_tmp_core_instance_program_mem_read_address),
				.program_mem_read_ready(fetcher_read_ready[i]),
				.program_mem_read_data(fetcher_read_data[i * PROGRAM_MEM_DATA_BITS+:PROGRAM_MEM_DATA_BITS]),
				.data_mem_read_valid(sv2v_tmp_core_instance_data_mem_read_valid),
				.data_mem_read_address(sv2v_tmp_core_instance_data_mem_read_address),
				.data_mem_read_ready(core_lsu_read_ready),
				.data_mem_read_data(core_lsu_read_data),
				.data_mem_write_valid(sv2v_tmp_core_instance_data_mem_write_valid),
				.data_mem_write_address(sv2v_tmp_core_instance_data_mem_write_address),
				.data_mem_write_data(sv2v_tmp_core_instance_data_mem_write_data),
				.data_mem_write_ready(core_lsu_write_ready)
			);
		end
	endgenerate
endmodule
`default_nettype none
module lsu (
	clk,
	reset,
	enable,
	core_state,
	decoded_mem_read_enable,
	decoded_mem_write_enable,
	rs,
	rt,
	mem_read_valid,
	mem_read_address,
	mem_read_ready,
	mem_read_data,
	mem_write_valid,
	mem_write_address,
	mem_write_data,
	mem_write_ready,
	lsu_state,
	lsu_out
);
	input wire clk;
	input wire reset;
	input wire enable;
	input wire [2:0] core_state;
	input wire decoded_mem_read_enable;
	input wire decoded_mem_write_enable;
	input wire [7:0] rs;
	input wire [7:0] rt;
	output reg mem_read_valid;
	output reg [7:0] mem_read_address;
	input wire mem_read_ready;
	input wire [7:0] mem_read_data;
	output reg mem_write_valid;
	output reg [7:0] mem_write_address;
	output reg [7:0] mem_write_data;
	input wire mem_write_ready;
	output reg [1:0] lsu_state;
	output reg [7:0] lsu_out;
	localparam IDLE = 2'b00;
	localparam REQUESTING = 2'b01;
	localparam WAITING = 2'b10;
	localparam DONE = 2'b11;
	always @(posedge clk)
		if (reset) begin
			lsu_state <= IDLE;
			mem_read_valid <= 0;
			mem_write_valid <= 0;
			mem_read_address <= 0;
			mem_write_address <= 0;
			mem_write_data <= 0;
			lsu_out <= 0;
		end
		else if (enable) begin
			if (decoded_mem_read_enable)
				case (lsu_state)
					IDLE:
						if (core_state == 3'b011)
							lsu_state <= REQUESTING;
					REQUESTING: begin
						mem_read_valid <= 1;
						mem_read_address <= rs;
						lsu_state <= WAITING;
					end
					WAITING:
						if (mem_read_ready == 1) begin
							mem_read_valid <= 0;
							lsu_out <= mem_read_data;
							lsu_state <= DONE;
						end
					DONE:
						if (core_state == 3'b110)
							lsu_state <= IDLE;
				endcase
			if (decoded_mem_write_enable)
				case (lsu_state)
					IDLE:
						if (core_state == 3'b011)
							lsu_state <= REQUESTING;
					REQUESTING: begin
						mem_read_valid <= 1;
						mem_write_address <= rs;
						mem_write_data <= rt;
						lsu_state <= WAITING;
					end
					WAITING:
						if (mem_write_ready) begin
							mem_write_valid <= 0;
							lsu_state <= DONE;
						end
					DONE:
						if (core_state == 3'b110)
							lsu_state <= IDLE;
				endcase
		end
endmodule
`default_nettype none
module pc (
	clk,
	reset,
	enable,
	core_state,
	decoded_nzp,
	decoded_immediate,
	decoded_nzp_write_enable,
	decoded_pc_mux,
	alu_out,
	current_pc,
	next_pc
);
	parameter DATA_MEM_DATA_BITS = 8;
	parameter PROGRAM_MEM_ADDR_BITS = 8;
	input wire clk;
	input wire reset;
	input wire enable;
	input wire [2:0] core_state;
	input wire [2:0] decoded_nzp;
	input wire [DATA_MEM_DATA_BITS - 1:0] decoded_immediate;
	input wire decoded_nzp_write_enable;
	input wire decoded_pc_mux;
	input wire [DATA_MEM_DATA_BITS - 1:0] alu_out;
	input wire [PROGRAM_MEM_ADDR_BITS - 1:0] current_pc;
	output reg [PROGRAM_MEM_ADDR_BITS - 1:0] next_pc;
	reg [2:0] nzp;
	always @(posedge clk)
		if (reset) begin
			nzp <= 3'b000;
			next_pc <= 0;
		end
		else if (enable) begin
			if (core_state == 3'b101) begin
				if (decoded_pc_mux == 1) begin
					if ((nzp & decoded_nzp) != 3'b000)
						next_pc <= decoded_immediate;
					else
						next_pc <= current_pc + 1;
				end
				else
					next_pc <= current_pc + 1;
			end
			if (core_state == 3'b110) begin
				if (decoded_nzp_write_enable) begin
					nzp[2] <= alu_out[2];
					nzp[1] <= alu_out[1];
					nzp[0] <= alu_out[0];
				end
			end
		end
endmodule
`default_nettype none
module registers (
	clk,
	reset,
	enable,
	block_id,
	core_state,
	decoded_rd_address,
	decoded_rs_address,
	decoded_rt_address,
	decoded_reg_write_enable,
	decoded_reg_input_mux,
	decoded_immediate,
	alu_out,
	lsu_out,
	rs,
	rt
);
	parameter THREADS_PER_BLOCK = 4;
	parameter THREAD_ID = 0;
	parameter DATA_BITS = 8;
	input wire clk;
	input wire reset;
	input wire enable;
	input wire [7:0] block_id;
	input wire [2:0] core_state;
	input wire [3:0] decoded_rd_address;
	input wire [3:0] decoded_rs_address;
	input wire [3:0] decoded_rt_address;
	input wire decoded_reg_write_enable;
	input wire [1:0] decoded_reg_input_mux;
	input wire [DATA_BITS - 1:0] decoded_immediate;
	input wire [DATA_BITS - 1:0] alu_out;
	input wire [DATA_BITS - 1:0] lsu_out;
	output reg [7:0] rs;
	output reg [7:0] rt;
	localparam ARITHMETIC = 2'b00;
	localparam MEMORY = 2'b01;
	localparam CONSTANT = 2'b10;
	reg [7:0] registers [15:0];
	always @(posedge clk)
		if (reset) begin
			rs <= 0;
			rt <= 0;
			registers[0] <= 8'b00000000;
			registers[1] <= 8'b00000000;
			registers[2] <= 8'b00000000;
			registers[3] <= 8'b00000000;
			registers[4] <= 8'b00000000;
			registers[5] <= 8'b00000000;
			registers[6] <= 8'b00000000;
			registers[7] <= 8'b00000000;
			registers[8] <= 8'b00000000;
			registers[9] <= 8'b00000000;
			registers[10] <= 8'b00000000;
			registers[11] <= 8'b00000000;
			registers[12] <= 8'b00000000;
			registers[13] <= 8'b00000000;
			registers[14] <= THREADS_PER_BLOCK;
			registers[15] <= THREAD_ID;
		end
		else if (enable) begin
			registers[13] <= block_id;
			if (core_state == 3'b011) begin
				rs <= registers[decoded_rs_address];
				rt <= registers[decoded_rt_address];
			end
			if (core_state == 3'b110) begin
				if (decoded_reg_write_enable && (decoded_rd_address < 13))
					case (decoded_reg_input_mux)
						ARITHMETIC: registers[decoded_rd_address] <= alu_out;
						MEMORY: registers[decoded_rd_address] <= lsu_out;
						CONSTANT: registers[decoded_rd_address] <= decoded_immediate;
					endcase
			end
		end
endmodule
`default_nettype none
module scheduler (
	clk,
	reset,
	start,
	decoded_mem_read_enable,
	decoded_mem_write_enable,
	decoded_ret,
	fetcher_state,
	lsu_state,
	current_pc,
	next_pc,
	core_state,
	done
);
	parameter THREADS_PER_BLOCK = 4;
	input wire clk;
	input wire reset;
	input wire start;
	input wire decoded_mem_read_enable;
	input wire decoded_mem_write_enable;
	input wire decoded_ret;
	input wire [2:0] fetcher_state;
	input wire [(THREADS_PER_BLOCK * 2) - 1:0] lsu_state;
	output reg [7:0] current_pc;
	input wire [(THREADS_PER_BLOCK * 8) - 1:0] next_pc;
	output reg [2:0] core_state;
	output reg done;
	localparam IDLE = 3'b000;
	localparam FETCH = 3'b001;
	localparam DECODE = 3'b010;
	localparam REQUEST = 3'b011;
	localparam WAIT = 3'b100;
	localparam EXECUTE = 3'b101;
	localparam UPDATE = 3'b110;
	localparam DONE = 3'b111;
	always @(posedge clk) begin : sv2v_autoblock_1
		reg [0:1] _sv2v_jump;
		_sv2v_jump = 2'b00;
		if (reset) begin
			current_pc <= 0;
			core_state <= IDLE;
			done <= 0;
		end
		else
			case (core_state)
				IDLE:
					if (start)
						core_state <= FETCH;
				FETCH:
					if (fetcher_state == 3'b010)
						core_state <= DECODE;
				DECODE: core_state <= REQUEST;
				REQUEST: core_state <= WAIT;
				WAIT: begin : sv2v_autoblock_2
					reg any_lsu_waiting;
					any_lsu_waiting = 1'b0;
					begin : sv2v_autoblock_3
						reg signed [31:0] i;
						begin : sv2v_autoblock_4
							reg signed [31:0] _sv2v_value_on_break;
							for (i = 0; i < THREADS_PER_BLOCK; i = i + 1)
								if (_sv2v_jump < 2'b10) begin
									_sv2v_jump = 2'b00;
									if ((lsu_state[i * 2+:2] == 2'b01) || (lsu_state[i * 2+:2] == 2'b10)) begin
										any_lsu_waiting = 1'b1;
										_sv2v_jump = 2'b10;
									end
									_sv2v_value_on_break = i;
								end
							if (!(_sv2v_jump < 2'b10))
								i = _sv2v_value_on_break;
							if (_sv2v_jump != 2'b11)
								_sv2v_jump = 2'b00;
						end
					end
					if (_sv2v_jump == 2'b00) begin
						if (!any_lsu_waiting)
							core_state <= EXECUTE;
					end
				end
				EXECUTE: core_state <= UPDATE;
				UPDATE:
					if (decoded_ret) begin
						done <= 1;
						core_state <= DONE;
					end
					else begin
						current_pc <= next_pc[(THREADS_PER_BLOCK - 1) * 8+:8];
						core_state <= FETCH;
					end
				DONE:
					;
			endcase
	end
endmodule
`default_nettype none
module alu (
	clk,
	reset,
	enable,
	core_state,
	decoded_alu_arithmetic_mux,
	decoded_alu_output_mux,
	rs,
	rt,
	alu_out
);
	input wire clk;
	input wire reset;
	input wire enable;
	input wire [2:0] core_state;
	input wire [1:0] decoded_alu_arithmetic_mux;
	input wire decoded_alu_output_mux;
	input wire [7:0] rs;
	input wire [7:0] rt;
	output wire [7:0] alu_out;
	localparam ADD = 2'b00;
	localparam SUB = 2'b01;
	localparam MUL = 2'b10;
	localparam DIV = 2'b11;
	reg [7:0] alu_out_reg;
	assign alu_out = alu_out_reg;
	always @(posedge clk)
		if (reset)
			alu_out_reg <= 0;
		else if (enable) begin
			if (core_state == 3'b101) begin
				if (decoded_alu_output_mux == 1)
					alu_out_reg <= {5'b00000, (rs - rt) > 0, (rs - rt) == 0, (rs - rt) < 0};
				else
					case (decoded_alu_arithmetic_mux)
						ADD: alu_out_reg <= rs + rt;
						SUB: alu_out_reg <= rs - rt;
						MUL: alu_out_reg <= rs * rt;
						DIV: alu_out_reg <= rs / rt;
						default: alu_out_reg <= 0;
					endcase
			end
		end
endmodule