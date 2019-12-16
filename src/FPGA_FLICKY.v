/********************************************************************
           FPGA Implimentation of "FLICKY" (Top Module)

											Copyright (c) 2017,19 MiSTer-X
*********************************************************************/
module FPGA_FLICKY
(
	input				clk48M,
	input				reset,

	input   [7:0]	INP0,
	input   [7:0]	INP1,
	input   [7:0]	INP2,

	input   [7:0]	DSW0,
	input   [7:0]	DSW1,
	
	input   [8:0]  PH,         // PIXEL H
	input   [8:0]  PV,         // PIXEL V
	output         PCLK,       // PIXEL CLOCK (to VGA encoder)
	output  [7:0]	POUT, 	   // PIXEL OUT

	output  [15:0] SOUT,			// Sound Out (PCM)

	
	input				ROMCL,		// Downloaded ROM image
	input   [24:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

// Clocks
wire                 clk24M, clk12M, clk6M, clk3M, clk8M ;
CLKGEN clks( clk48M, clk24M, clk12M, clk6M, clk3M, clk8M );

// CPU
wire 			CPUCLn;
wire [15:0] CPUAD;
wire  [7:0] CPUDO,VIDDO;
wire			CPUWR,VIDCS,VBLK;
wire			SNDRQ;

FlickyMAIN Main (
	.RESET(reset),
	.INP0(INP0),.INP1(INP1),.INP2(INP2),
	.DSW0(DSW0),.DSW1(DSW1),
	.CLK48M(clk48M),.CLK3M(clk3M),
	.CPUCLn(CPUCLn),.CPUAD(CPUAD),.CPUDO(CPUDO),.CPUWR(CPUWR),
	.VBLK(VBLK),.VIDCS(VIDCS),.VIDDO(VIDDO),
	.SNDRQ(SNDRQ),
	
	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN)
);

// Video
FlickyVIDEO Video (
	.VCLKx8(clk48M),.VCLKx4(clk24M),.VCLKx2(clk12M),.VCLK(clk6M),
	.PH(PH),.PV(PV),.VBLK(VBLK),.RGB8(POUT),.PALDSW(1'b0),

	.cpu_cl(CPUCLn),.cpu_ad(CPUAD),.cpu_wr(CPUWR),.cpu_dw(CPUDO),
	.cpu_rd(VIDCS),.cpu_dr(VIDDO),

	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN)
);
assign PCLK = clk6M;

// Sound
FlickySND Sound(
	clk8M, reset, CPUDO, SNDRQ, SOUT,
	ROMCL, ROMAD, ROMDT, ROMEN
);

endmodule


//----------------------------------
//  Clock Generator
//----------------------------------
module CLKGEN
(
	input	 clk48M,

	output clk24M,
	output clk12M,
	output clk6M,
	output clk3M,

	output reg clk8M
);

reg [4:0] clkdiv;
always @( posedge clk48M ) clkdiv <= clkdiv+1;
assign clk24M = clkdiv[0];
assign clk12M = clkdiv[1];
assign clk6M  = clkdiv[2];
assign clk3M  = clkdiv[3];

reg [1:0] count;
always @( posedge clk48M ) begin
	if (count > 2'd2) begin
		count <= count - 2'd2;
      clk8M <= ~clk8M;
   end
   else count <= count + 2'd1;
end

endmodule

