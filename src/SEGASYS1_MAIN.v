// Copyright (c) 2017,19 MiSTer-X

`define EN_MCPU0		(ROMAD[17:15]==3'b00_0 ) 
`define EN_MCPU8		(ROMAD[17:14]==4'b00_10) 

module SEGASYS1_MAIN
(
	input				CLK48M,
	input				CLK3M,

	input				RESET,

	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,

	input				VBLK,
	input				VIDCS,
	input   [7:0]	VIDDO,

	output			CPUCLn,
	output [15:0]	CPUAD,
	output  [7:0]	CPUDO,
	output		  	CPUWR,
	
	output			SNDRQ,
	
	input				ROMCL,		// Downloaded ROM image
	input   [24:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire			AXSCL   = CLK48M;
wire			CPUCL   = CLK3M;
assign 		CPUCLn  = ~CPUCL;

wire  [7:0]	CPUDI;
wire			CPURD;

wire			cpu_cs_video;
wire  [7:0]	cpu_rd_video;

wire	cpu_m1;
wire	cpu_mreq, cpu_iorq;
wire	_cpu_rd, _cpu_wr;

Z80IP maincpu(
	.reset(RESET),
	.clk(CPUCL),
	.adr(CPUAD),
	.data_in(CPUDI),
	.data_out(CPUDO),
	.m1(cpu_m1),
	.mx(cpu_mreq),
	.ix(cpu_iorq),
	.rd(_cpu_rd),
	.wr(_cpu_wr),
	.intreq(VBLK),
	.nmireq(1'b0)
);

assign		CPUWR = _cpu_wr & cpu_mreq;
assign		CPURD = _cpu_rd & cpu_mreq;

assign		SNDRQ = (CPUAD[4:0] == 5'b1_1000) & cpu_iorq & _cpu_wr;

wire			cpu_cs_port1 =  (CPUAD[4:2] == 3'b0_00) & cpu_iorq;
wire			cpu_cs_port2 =  (CPUAD[4:2] == 3'b0_01) & cpu_iorq;
wire			cpu_cs_portS =  (CPUAD[4:2] == 3'b0_10) & cpu_iorq;
wire			cpu_cs_portA =  (CPUAD[4:2] == 3'b0_11) & ~CPUAD[0] & cpu_iorq;
wire			cpu_cs_portB =(((CPUAD[4:2] == 3'b0_11) &  CPUAD[0]) | (CPUAD[4:0] == 5'b1_0000)) & cpu_iorq;
wire			cpu_cs_portI =  (CPUAD[4:2] == 3'b1_10) & cpu_iorq;

wire [7:0]	cpu_rd_port1 = INP0; 
wire [7:0]	cpu_rd_port2 = INP1; 
wire [7:0]	cpu_rd_portS = INP2; 

wire [7:0]	cpu_rd_portA = DSW0;
wire [7:0]	cpu_rd_portB = DSW1;


// Program ROM
wire			cpu_cs_mrom0 = (CPUAD[15]    == 1'b0 );
wire			cpu_cs_mrom1 = (CPUAD[15:14] == 2'b10);

wire [7:0]	cpu_rd_mrom0;
wire [7:0]	cpu_rd_mrom1;

wire [14:0] rad;
wire  [7:0] rdt;

SEGASYS1_PRGDEC decr(AXSCL,cpu_m1,CPUAD,cpu_rd_mrom0, rad,rdt, ROMCL,ROMAD,ROMDT,ROMEN);

DLROM #(15,8) rom0(AXSCL,   rad,         rdt, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0);	// ($0000-$7FFF encrypted)
DLROM #(14,8) rom1(CPUCLn,CPUAD,cpu_rd_mrom1, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8);	// ($8000-$BFFF non-encrypted)


// Work RAM
wire [7:0]	cpu_rd_mram;
wire			cpu_cs_mram = (CPUAD[15:12] == 4'b1100);
SRAM_4096 mainram(CPUCLn, CPUAD[11:0], cpu_rd_mram, cpu_cs_mram & CPUWR, CPUDO );


// Video mode latch
reg [7:0] vidmode;
always @(posedge CPUCLn) begin
	if ((CPUAD[4:0] == 5'b1_1001) & cpu_iorq & _cpu_wr) begin
		vidmode <= CPUDO;
	end
end


dataselector10 mcpudisel(
	CPUDI,
	VIDCS, VIDDO,
	cpu_cs_port1, cpu_rd_port1,
	cpu_cs_port2, cpu_rd_port2,
	cpu_cs_portS, cpu_rd_portS,
	cpu_cs_portA, cpu_rd_portA,
	cpu_cs_portB, cpu_rd_portB,
	cpu_cs_mram,  cpu_rd_mram,
	cpu_cs_mrom0, cpu_rd_mrom0,
	cpu_cs_mrom1, cpu_rd_mrom1,
	1'b0, 8'd0,
	8'hFF
);

endmodule

