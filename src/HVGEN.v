// Copyright (c) 2019 MiSTer-X

module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [14:0]		iRGB,

	output reg [14:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1,

	input					H240,

	input   [8:0]		HOFFS,
	input	  [8:0]		VOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-9'd16;
assign VPOS = vcnt;

wire  H240B = H240 ? ((hcnt<24)|(hcnt>=264)) : 0;

wire [8:0] HS_B = 288+(HOFFS*2);
wire [8:0] HS_E =  32+(HS_B);
wire [8:0] HS_N = 447+(HS_E-320);

wire [8:0] VS_B = 226+(VOFFS*4);
wire [8:0] VS_E =   4+(VS_B);
wire [8:0] VS_N = 481+(VS_E-230);

always @(posedge PCLK) begin
	case (hcnt)
	    15: begin HBLK <= 0; hcnt <= hcnt+9'd1; end
		272: begin HBLK <= 1; hcnt <= hcnt+9'd1; end
		511: begin hcnt <= 0;
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt+9'd1; end
				511: begin VBLK <= 0; vcnt <= 0; end
				default: vcnt <= vcnt+9'd1;
			endcase
		end
		default: hcnt <= hcnt+9'd1;
	endcase

	if (hcnt==HS_B) begin HSYN <= 0; end
	if (hcnt==HS_E) begin HSYN <= 1; hcnt <= HS_N; end

	if (vcnt==VS_B) begin VSYN <= 0; end
	if (vcnt==VS_E) begin VSYN <= 1; vcnt <= VS_N; end
	
	oRGB <= (HBLK|VBLK|H240B) ? 12'h0 : iRGB;
end

endmodule

