`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2024 21:33:47
// Design Name: 
// Module Name: sobel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sobel(input clk_i, input rst_i, input ack_i, input stb_i, input adr_i, input [31:0] dat_i, input cyc_i, input we_i, output reg cyc_o, output stb_o, output reg we_o, output wire [31:0] adr_o,output reg ack_o, output reg dat_o, output  int_req);
// Computation datapath signals
reg [19:0] O_base;
reg [19:0] O_offset;
reg [19:0] D_base;
reg [19:0] D_offset;
reg [31:0] prev_row, curr_row, next_row;
reg [7:0] O [-1:+1][-1:+1];
reg signed [10:0] Dx, Dy, D;
reg [7:0] abs_D;
reg [31:0] result_row;
parameter [4:0] idle = 5'b00000,
 read_prev_0 = 5'b00001,
 read_curr_0 = 5'b00010,
 read_next_0 = 5'b00011,
 comp1_0 = 5'b00100,
 comp2_0 = 5'b00101,
 comp3_0 = 5'b00110,
 comp4_0 = 5'b00111,
 read_prev = 5'b01000,
 read_curr = 5'b01001,
 read_next = 5'b01010,
 comp1 = 5'b01011,
 comp2 = 5'b01100,
 comp3 = 5'b01101,
 comp4 = 5'b01110,
 write_result = 5'b01111,
 write_158 = 5'b10000,
 comp1_159 = 5'b10001,
 comp2_159 = 5'b10010,
 comp3_159 = 5'b10011,
 comp4_159 = 5'b10100,
 write_159 = 5'b10101;
reg [4:0] current_state, next_state;
reg [9:0] row; // range 0 to 477;
reg [7:0] col; // range 0 to 159;
wire O_base_ce, D_base_ce;
wire start;
reg offset_reset, row_reset, col_reset;
reg prev_row_load, curr_row_load, next_row_load;
reg shift_en;
reg row_cnt_en, col_cnt_en;
reg O_offset_cnt_en, D_offset_cnt_en;
reg int_en, done_set, done;
always @(posedge clk_i) // Row counter
if (row_reset) row <= 0;
else if (row_cnt_en) row <= row + 1;
always @(posedge clk_i) // Column counter
if (col_reset) col <= 0;
else if (col_cnt_en) col <= col + 1;
always @(posedge clk_i) // State register
if (rst_i) current_state <= idle;
else current_state <= next_state;
always @* begin // FSM logic
offset_reset = 1'b0; row_reset = 1'b0;
col_reset = 1'b0;
row_cnt_en = 1'b0; col_cnt_en = 1'b0;
O_offset_cnt_en = 1'b0; D_offset_cnt_en = 1'b0;
prev_row_load = 1'b0; curr_row_load = 1'b0;
next_row_load = 1'b0;
shift_en = 1'b0; cyc_o = 1'b0;
we_o = 1'b0; done_set = 1'b0;
case (current_state)
idle: begin
offset_reset = 1'b1; row_reset = 1'b1;
col_reset = 1'b1;
if (start) next_state = read_prev_0;
else next_state = idle;
end
read_prev_0: begin
col_reset = 1'b1; prev_row_load = 1'b1;
cyc_o = 1'b1;
if (ack_i) next_state = read_curr_0;
else next_state = read_prev_0;
end
read_curr_0: begin
curr_row_load = 1'b1; cyc_o = 1'b1;
if (ack_i) next_state = read_next_0;
else next_state = read_curr_0;
end
read_next_0: begin
next_row_load = 1'b1; cyc_o = 1'b1;
if (ack_i) begin
O_offset_cnt_en = 1'b1;
next_state = comp1_0;
end
else next_state = read_next_0;
end
comp1_0: begin
shift_en = 1'b1;
next_state = comp2_0;
end
comp2_0: begin
shift_en = 1'b1;
next_state = comp3_0;
end
comp3_0: begin
shift_en = 1'b1;
next_state = comp4_0;
end
comp4_0: begin
shift_en = 1'b1;
next_state = read_prev;
end
read_prev: begin
prev_row_load = 1'b1;cyc_o = 1'b1;
if (ack_i) next_state = read_curr;
else next_state = read_prev;
end
read_curr: begin
curr_row_load = 1'b1;cyc_o = 1'b1;
if (ack_i) next_state = read_next;
else next_state = read_curr;
end
read_prev: begin
prev_row_load = 1'b1;cyc_o = 1'b1;
if (ack_i) next_state = read_curr;
else next_state = read_prev;
end
read_next: begin
next_row_load = 1'b1;cyc_o = 1'b1;
if (ack_i) next_state = comp1;
else next_state = read_next;
end
comp1: begin
shift_en = 1'b1;
next_state = comp2;
end
comp2: begin
shift_en = 1'b1;
next_state = comp3;
end
comp3: begin
shift_en = 1'b1;
next_state = comp4;
end
comp4: begin
shift_en = 1'b1;
if (col == 158) next_state = write_158;
else next_state = write_result;
end
write_result: begin
cyc_o = 1'b1; we_o = 1'b1;
if (ack_i) begin
col_cnt_en = 1'b1; D_offset_cnt_en = 1'b1;
next_state = read_prev;
end
else next_state = write_result;
end
write_158: begin
cyc_o = 1'b1; we_o = 1'b1;
if (ack_i) begin
col_cnt_en = 1'b1; D_offset_cnt_en = 1'b1;
next_state = comp1_159;
end
else next_state = write_158;
end
comp1_159: begin
shift_en = 1'b1;
next_state = comp2_159;
end
comp2_159: begin
shift_en = 1'b1;
next_state = comp3_159;
end
comp3_159: begin
shift_en = 1'b1;
next_state = comp4_159;
end
comp4_159: begin
shift_en = 1'b1;
next_state = write_159;
end
write_159: begin
cyc_o = 1'b1; we_o = 1'b1;
if (ack_i) begin
D_offset_cnt_en = 1'b1; 
if (row == 477) begin
done_set = 1'b1;
next_state = idle;
end
else begin
row_cnt_en = 1'b1;
next_state = read_prev_0;
end
end
else next_state = write_159;
end
endcase
end
assign stb_o = cyc_o;



// Computational datapath
always @(posedge clk_i) // Previous row register
if (prev_row_load) prev_row <= dat_i;
else if (shift_en) prev_row[31:8] <= prev_row[23:0];
always @(posedge clk_i) // Current row register
if (curr_row_load) curr_row <= dat_i;
else if (shift_en) curr_row[31:8] <= curr_row[23:0];
always @(posedge clk_i) // Next row register
if (next_row_load) next_row <= dat_i;
else if (shift_en) next_row[31:8] <= next_row[23:0];

function [10:0] abs (input signed [10:0] x);
abs = x>=0?x:-x;
endfunction

always @(posedge clk_i) // Computation pipeline
if (shift_en) begin
D = abs(Dx) + abs(Dy);
abs_D <= D[10:3];
Dx <= - $signed({3'b000, O[-1][-1]}) // – 1 * 0[-1][-1]
 + $signed({3'b000, O[-1][+1]}) // + 1 * 0[-1][+1]
 - ($signed({3'b000, O[ 0][-1]}) // – 2 * 0[ 0][-1]
 << 1)
 + ($signed({3'b000, O[ 0][+1]}) // + 2 * 0[ 0][+1]
 << 1)
 - $signed({3'b000, O[+1][-1]}) // – 1 * 0[+1][-1]
 + $signed({3'b000, O[+1][+1]}); // + 1 * 0[+1][+1]
Dy <= $signed({3'b000, O[-1][-1]}) // + 1 * O[-1][-1]
 + ($signed({3'b000, O[-1][ 0]}) // + 2 * 0[-1][ 0]
 << 1)
 + $signed({3'b000, O[-1][+1]}) // + 1 * 0[-1][+1]
 - $signed({3'b000, O[+1][-1]}) // – 1 * 0[+1][-1]
 - ($signed({3'b000, O[+1][ 0]}) // – 2 * 0[+1][ 0]
 << 1)
 - $signed({3'b000, O[+1][+1]}); // – 1 * 0[+1][+1]
O[-1][-1] <= O[-1][0];
O[-1][ 0] <= O[-1][+1];
O[-1][+1] <= prev_row[31:24];
O[ 0][-1] <= O[0][0];
O[ 0][ 0] <= O[0][+1];
O[ 0][+1] <= curr_row[31:24];
O[+1][-1] <= O[+1][ 0];
O[+1][ 0] <= O[+1][+1];
O[+1][+1] <= next_row[31:24];
end
always @(posedge clk_i) // Result row register
if (shift_en) result_row <= {result_row[23:0], abs_D};




// Address generator
always @(posedge clk_i) // 0 base address register
if (O_base_ce) O_base <= dat_i[21:2];
always @(posedge clk_i) // 0 address offset counter
if (offset_reset) O_offset <= 0;
else if (O_offset_cnt_en) O_offset <= O_offset + 1;
assign O_prev_addr = O_base + O_offset;
assign O_curr_addr = O_prev_addr + 640/4;
assign O_next_addr = O_prev_addr + 1280/4;
always @(posedge clk_i) // D base address register
if (D_base_ce) D_base <= dat_i[21:2];
always @(posedge clk_i) // D address offset counter
if (offset_reset) D_offset <= 0;
else if (D_offset_cnt_en) D_offset <= D_offset + 1;
assign D_addr = D_base + D_offset;
assign adr_o[21:2] = prev_row_load ? O_prev_addr :
 curr_row_load ? O_curr_addr :
 next_row_load ? O_next_addr :
 D_addr;
assign adr_o[1:0] = 2'b00;



// Wishbone slave interface
assign start = cyc_i && stb_i && we_i && adr_i == 2'b01;
assign O_base_ce = cyc_i && stb_i && we_i && adr_i == 2'b10;
assign D_base_ce = cyc_i && stb_i && we_i && adr_i == 2'b11;
always @(posedge clk_i) // Interrupt enable register
if (rst_i)
int_en <= 1'b0;
else if (cyc_i && stb_i && we_i && adr_i == 2'b00)
int_en <= dat_i[0];
always @(posedge clk_i) // Status register
if (rst_i)
done <= 1'b0;
else if (done_set)
// This occurs when last write is acknowledged,
// and so cannot coincide with a read of the
// status register.
done <= 1'b1;
else if (cyc_i && stb_i && !we_i && adr_i == 2'b00 && ack_o)
done <= 1'b0;
assign int_req = int_en && done;
always @(posedge clk_i) // Generate ack output
ack_o <= cyc_i && stb_i && !ack_o;
// Wishbone data output multiplexer
always @*
if (cyc_i && stb_i && !we_i)
if (adr_i == 2'b00)
dat_o = {31'b0, done}; // status register read
else
dat_o = 32'b0; // other registers read as 0
else
dat_o = result_row; // for master write
endmodule
