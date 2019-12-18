// Copyright (c) 2017,19 MiSTer-X

`define EN_MCPU0		(ROMAD[17:15]==3'b00_0 ) 
`define EN_MCPU8		(ROMAD[17:14]==4'b00_10) 

`define EN_DEC1TBL	(ROMAD[17:7]==11'b10_1100_0001_0)	// $2C100	 

`define EN_DEC2XOR	(ROMAD[17:7]==11'b10_1100_0001_0) 	// $2C100
`define EN_DEC2SWP	(ROMAD[17:7]==11'b10_1100_0001_1)	// $2C180 


//----------------------------------------
//  Program ROM with Decryptor (Type 1)
//----------------------------------------
module SEGASYS1_PRGROMT1
(
	input 				clk,

	input					mrom_m1,
	input     [15:0]	mrom_ad,
	output reg [7:0]	mrom_dt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

reg  [16:0] madr;
wire  [7:0] mdat;

wire			f		  = mdat[7];
wire  [7:0] xorv    = { f, 1'b0, f, 1'b0, f, 3'b000 }; 
wire  [7:0] andv    = ~(8'hA8);
wire  [1:0] decidx0 = { mdat[5],  mdat[3] } ^ { f, f };
wire  [6:0] decidx  = { madr[12], madr[8], madr[4], madr[0], ~madr[16], decidx0 };
wire  [7:0] dectbl;
wire  [7:0] mdec    = ( mdat & andv ) | ( dectbl ^ xorv );

wire  [7:0] md1;

DLROM #(7,8)  dect( clk, decidx,     dectbl, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC1TBL );
DLROM #(15,8) rom0( clk, madr[14:0],   mdat, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0   );	// ($0000-$7FFF encrypted)
DLROM #(14,8) rom1( clk, mrom_ad[13:0], md1, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8   );	// ($8000-$BFFF non-encrypted)

reg phase = 1'b0;
always @( negedge clk ) begin
	if ( phase ) mrom_dt <= madr[15] ? md1 : mdec;
	else madr <= { mrom_m1, mrom_ad };
	phase <= ~phase;
end

endmodule


//----------------------------------------
//  Program ROM with Decryptor (Type 2)
//----------------------------------------
module SEGASYS1_PRGROMT2
(
	input 				clk,

	input					mrom_m1,
	input     [15:0]	mrom_ad,
	output reg [7:0]	mrom_dt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

function [7:0] bsw;
input [7:0] v;
input [2:0] a;
input [2:0] b;
input [2:0] c;
input [2:0] d;

	bsw = {v[7],v[a],v[5],v[b],v[3],v[c],v[1],v[d]};

endfunction

function [7:0] bswp;
input [4:0] m;
input [7:0] v;

   case (m)

	  0: bswp = bsw(v,6,4,2,0);
	  1: bswp = bsw(v,4,6,2,0);
     2: bswp = bsw(v,2,4,6,0);
     3: bswp = bsw(v,0,4,2,6);
	  4: bswp = bsw(v,6,2,4,0);
     5: bswp = bsw(v,6,0,2,4);
     6: bswp = bsw(v,6,4,0,2);
	  7: bswp = bsw(v,2,6,4,0);
	  8: bswp = bsw(v,4,2,6,0);
     9: bswp = bsw(v,4,6,0,2);
    10: bswp = bsw(v,6,0,4,2);
    11: bswp = bsw(v,0,6,4,2);
	 12: bswp = bsw(v,4,0,6,2);
    13: bswp = bsw(v,0,4,6,2);
    14: bswp = bsw(v,6,2,0,4);
    15: bswp = bsw(v,2,6,0,4);
    16: bswp = bsw(v,0,6,2,4);
    17: bswp = bsw(v,2,0,6,4);
    18: bswp = bsw(v,0,2,6,4);
    19: bswp = bsw(v,4,2,0,6);
	 20: bswp = bsw(v,2,4,0,6);
    21: bswp = bsw(v,4,0,2,6);
    22: bswp = bsw(v,2,0,4,6);
    23: bswp = bsw(v,0,2,4,6);

    default: bswp = 0;
   endcase

endfunction


wire [7:0] rd0, rd1;
reg		  a15;

wire [7:0] sd,xd;
wire [6:0] ix = {mrom_ad[14],mrom_ad[12],mrom_ad[9],mrom_ad[6],mrom_ad[3],mrom_ad[0],mrom_m1};
wire [7:0] dd = bswp(sd,rd0) ^ xd;

DLROM #(7,8)  xort(clk,ix,xd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2XOR);
DLROM #(7,8)  swpt(clk,ix,sd, ROMCL,ROMAD,ROMDT,ROMEN & `EN_DEC2SWP);

DLROM #(15,8) rom0(clk,mrom_ad[14:0],rd0, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0);	// ($0000-$7FFF encrypted)
DLROM #(14,8) rom1(clk,mrom_ad[13:0],rd1, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8);	// ($8000-$BFFF non-encrypted)

always @(posedge clk) a15 <= mrom_ad[15];
always @(negedge clk) mrom_dt <= a15 ? rd1 : dd;

endmodule


//----------------------------------
//  Program ROM (Decrypted)
//----------------------------------
module SEGASYS1_PRGROMD
(
	input 				clk,

	input					mrom_m1,
	input     [15:0]	mrom_ad,
	output 	  [7:0]	mrom_dt,

	input					ROMCL,		// Downloaded ROM image
	input     [24:0]	ROMAD,
	input	     [7:0]	ROMDT,
	input					ROMEN
);

reg madr;
always @(posedge clk) madr <= mrom_ad[15];

wire [7:0] md0,md1;

DLROM #(15,8) rom0( clk, mrom_ad[14:0], md0, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU0 );
DLROM #(14,8) rom1( clk, mrom_ad[13:0], md1, ROMCL,ROMAD,ROMDT,ROMEN & `EN_MCPU8 );

assign mrom_dt = madr ? md1 : md0;

endmodule

