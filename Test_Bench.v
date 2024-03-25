`timescale 1ns / 1ps
module testbench();
parameter sizeOfWidth = 8;   // data width
parameter sizeOfLengthReal = 307200; //total data bytes
parameter INFILE  = "C:/Users/auroa/Desktop/acceleratortest/testPic1.hex";
parameter OUTFILE  = "C:/Users/auroa/Desktop/acceleratortest/testPicout.hex";
reg [7 : 0]   total_memory [0 : sizeOfLengthReal-1];// memory to store  8-bit data image
reg [7:0] temp_BMP [0 :sizeOfLengthReal-1]; // Temp memory to store memory
//wire read=1;
//wire write=1;
initial begin
    $readmemh(INFILE,total_memory,0,sizeOfLengthReal-1); // read file from INFILE
end


parameter t_c = 10;
parameter [22:0] mem_base = 23'h000000;
parameter [22:0] sobel_reg_base = 23'h400000;
parameter sobel_int_reg_offset = 0;
parameter sobel_start_reg_offset = 4;
parameter sobel_O_base_reg_offset = 8;
parameter sobel_D_base_reg_offset = 12;
parameter sobel_status_reg_offset = 0;
reg clk, rst;
wire bus_cyc, bus_stb, bus_we;
wire [3:0] bus_sel;
wire [22:0] bus_adr;
wire bus_ack;
wire [31:0] bus_dat;
wire int_req;
wire sobel_cyc_o, sobel_stb_o, sobel_we_o;
wire [21:0] sobel_adr_o;
wire sobel_ack_i;
wire sobel_stb_i;
wire sobel_ack_o;
wire [31:0] sobel_dat_o;


reg cpu_cyc_o, cpu_stb_o, cpu_we_o;
reg [3:0] cpu_sel_o;
reg [22:0] cpu_adr_o;
wire cpu_ack_i;
reg [31:0] cpu_dat_o;
wire[31:0] cpu_dat_i ;

wire mem_stb_i;
//wire [3:0] mem_sel_i;
reg mem_ack_o;
reg [31:0] mem_dat_o;

parameter sobel = 1'b0, cpu = 1'b1;
reg arbiter_current_state, arbiter_next_state;
reg sobel_gnt, cpu_gnt;

wire sobel_sel, mem_sel;
reg int_req;
reg [21:0] loc;
integer loc1=640;
integer i;
always begin // Clock generator
clk = 1'b1; #(t_c/2);
clk = 1'b0; #(t_c/2);
end
initial begin // Reset generator
rst <= 1'b1;
#(2.5*t_c) rst = 1'b0;
end
sobel s( .clk_i(clk), .rst_i(rst),
 .cyc_o(sobel_cyc_o), .stb_o(sobel_stb_o),.we_o(sobel_we_o),
 .adr_o(sobel_adr_o), .ack_i(sobel_ack_i),
 .cyc_i(bus_cyc), .stb_i(sobel_stb_i),
 .we_i(bus_we), .adr_i(bus_adr[3:2]),
 .ack_o(sobel_ack_o),
 .dat_o(sobel_dat_o), .dat_i(bus_dat),
 .int_req(int_req) );


task bus_write ( input [22:0] adr, input [31:0] dat );
begin
cpu_adr_o = adr;
cpu_sel_o = 4'b1111;
cpu_dat_o = dat;
cpu_cyc_o = 1'b1; cpu_stb_o = 1'b1; cpu_we_o = 1'b1;
@(posedge clk); while (!cpu_ack_i) @(posedge clk);
end
endtask

initial begin // Processor bus-functional model
cpu_adr_o = 23'h000000;
cpu_sel_o = 4'b0000;
cpu_dat_o = 32'h00000000;
cpu_cyc_o = 1'b0; cpu_stb_o = 1'b0; cpu_we_o = 1'b0;
@(negedge rst);
@(posedge clk);
// Write 008000 (hex) to 0_base_addr register
bus_write(sobel_reg_base
 + sobel_O_base_reg_offset, 32'h00008000);
// Write 053000 + 280 (hex) to D_base_addr register
bus_write(sobel_reg_base
 + sobel_D_base_reg_offset, 32'h00053280);
// Write 1 to interrupt control register (enable interrupt)
bus_write(sobel_reg_base
 + sobel_int_reg_offset, 32'h00000001);
// Write to start register (data value ignored)
bus_write(sobel_reg_base
 + sobel_start_reg_offset, 32'h00000000);
// End of write operations
cpu_cyc_o = 1'b0; cpu_stb_o = 1'b0; cpu_we_o = 1'b0;
begin: loop
forever begin
#10000;
@(posedge clk);
// Read status register
cpu_adr_o = sobel_reg_base + sobel_status_reg_offset;
cpu_sel_o = 4'b1111;
cpu_cyc_o = 1'b1; cpu_stb_o = 1'b1; cpu_we_o = 1'b0;
@(posedge clk); while (!cpu_ack_i) @(posedge clk);
cpu_cyc_o = 1'b0; cpu_stb_o = 1'b0; cpu_we_o = 1'b0;
if (bus_dat[0]) begin
//disable loop;
$display("done");
for(i=0;i<=640;i=i+1)
temp_BMP[i] = 8'h00;
for(i=0;i<640;i=i+1)
temp_BMP[307199-i]=8'h00;
 $writememh(OUTFILE,temp_BMP,0,sizeOfLengthReal-1); // Write file to OUTFILE
$finish;
end
end
end
end

always begin // Memory bus-functional model
mem_ack_o = 1'b0;
//mem_dat_o = 32'h00000000;
@(posedge clk);
while (!(bus_cyc && mem_stb_i))  @(posedge clk); 
if (!bus_we)begin
loc = bus_adr[21:0]-22'h008000;
mem_dat_o = {total_memory[loc],total_memory[loc+1],total_memory[loc+2],total_memory[loc+3]};
end // in place of read data
else begin
{temp_BMP[loc1],temp_BMP[loc1+1],temp_BMP[loc1+2],temp_BMP[loc1+3]}={bus_dat[31:24],bus_dat[23:16],bus_dat[15:8],bus_dat[7:0]};
//$display("%h,%h,%h,%h ",temp_BMP[loc1],temp_BMP[loc1+1],temp_BMP[loc1+2],temp_BMP[loc1+3]);
loc1 = loc1+4;
end
mem_ack_o = 1'b1;
@(posedge clk);
end

always @(posedge clk) // Arbiter FSM register
if (rst)
arbiter_current_state <= sobel;
else
arbiter_current_state <= arbiter_next_state;
always @* // Arbiter logic
case (arbiter_current_state)
sobel: if (sobel_cyc_o) begin
sobel_gnt <= 1'b1; cpu_gnt <= 1'b0;
arbiter_next_state <= sobel;
end
else if (!sobel_cyc_o && cpu_cyc_o) begin
sobel_gnt <= 1'b0; cpu_gnt <= 1'b1;
arbiter_next_state <= cpu;
end
else begin
sobel_gnt <= 1'b0; cpu_gnt <= 1'b0;
arbiter_next_state <= sobel;
end
cpu: if (cpu_cyc_o) begin
sobel_gnt <= 1'b0; cpu_gnt <= 1'b1;
arbiter_next_state <= cpu;
end else if (sobel_cyc_o && !cpu_cyc_o) begin
sobel_gnt <= 1'b1; cpu_gnt <= 1'b0;
arbiter_next_state <= sobel;
end else begin
sobel_gnt <= 1'b0; cpu_gnt <= 1'b0;
arbiter_next_state <= sobel;
end
endcase


// Bus master multiplexers and logic
assign bus_cyc = sobel_gnt ? sobel_cyc_o : cpu_cyc_o;
assign bus_stb = sobel_gnt ? sobel_stb_o : cpu_stb_o;
assign bus_we = sobel_gnt ? sobel_we_o : cpu_we_o;
assign bus_sel = sobel_gnt ? 4'b1111 : cpu_sel_o;
assign bus_adr = sobel_gnt ? {1'b0, sobel_adr_o} : cpu_adr_o;
assign sobel_ack_i = bus_ack & sobel_gnt;
assign cpu_ack_i = bus_ack & cpu_gnt;
// Bus slave logic
assign sobel_sel = (bus_adr & 23'h7FFFF0) == sobel_reg_base;
assign mem_sel = (bus_adr & 23'h400000) == mem_base;
assign sobel_stb_i = bus_stb & sobel_sel;
assign mem_stb_i = bus_stb & mem_sel;
assign bus_ack = sobel_sel ? sobel_ack_o :
 mem_sel ? mem_ack_o :
 1'b0;
// Bus data multiplexer
assign bus_dat = sobel_gnt && bus_we || sobel_sel && !bus_we
 ? sobel_dat_o :
 cpu_gnt && bus_we
 ? cpu_dat_o :
 mem_dat_o;


endmodule
