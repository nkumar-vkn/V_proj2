`define TOT_CYC 20'd530000
// 2000*263 + 2000 + 2000
`define log_TOT_CYC 20

`define SING_CYC 9'd264
//35(ip)+179(DFF)+49(op)+1
`define log_SING_CYC 9

`define GOLDEN_ANS 16'b0100_1010_0101_0111

module bist_hardware(clk,rst,bistmode,bistdone,bistpass,cut_scanmode,
                     cut_sdi,cut_sdo);
  input          clk;
  input          rst;
  input          bistmode;
  output         bistdone;
  output         bistpass;
  output         cut_scanmode;
  output         cut_sdi;
  input          cut_sdo;

// Add your code here
reg cut_scanmode;
reg bistdone;
reg bistpass;

reg [16:1] LFSR;
reg [16:1] MISR;
reg [`log_SING_CYC:0] s_cyc_count;
reg [`log_TOT_CYC:0] t_cyc_count;

integer i;
reg firstscan;
reg MISR_en;

//initialize all signals & counters
initial begin
    LFSR = 16'hFFFF;
	MISR = 16'h0;

    s_cyc_count = 6'd1;
	t_cyc_count = 11'd1;
    bistdone = 0;
    bistpass = 0;
    cut_scanmode = 0;
end

assign cut_sdi = LFSR[1];

always @ (negedge clk) MISR_en <= cut_scanmode & ~firstscan;

always @ (posedge clk) begin
    if (t_cyc_count == `TOT_CYC) begin   //Check for output mismatch
        $display("Output Sig: %b Golden Sig: %b",MISR, `GOLDEN_ANS);
        if (MISR == `GOLDEN_ANS)
            bistpass <= 1;
        else 
            bistpass <= 0;
    end
    else 
        bistpass <= 0;
end

always @ (posedge clk) begin
    if(~rst) begin
        if (t_cyc_count < (`SING_CYC -1) ) 
            firstscan <= 1;
        else 
            firstscan <= 0;
    end
    else 
        firstscan <= 1;
end

//Counters
always @ (posedge clk) begin
    if (~rst) begin
        if (bistmode) begin
  	        if (s_cyc_count != `SING_CYC) 
                s_cyc_count <= s_cyc_count + 1;
  	        else 
                s_cyc_count <= 1;

  	        if (t_cyc_count != `TOT_CYC) 
                t_cyc_count <= t_cyc_count + 1;
  	        else 
                t_cyc_count <= 1;
  	    end
  	    else begin
            s_cyc_count <= s_cyc_count;
            t_cyc_count <= t_cyc_count;
  	    end
    end
    else begin
        s_cyc_count <= 1;
        t_cyc_count <= 1;
    end
end

//ScanMode
always @ (posedge clk) begin
    if ((~rst) && (bistmode)) begin
	    if (s_cyc_count == (`SING_CYC - 1)) 
            cut_scanmode <= 0; 
	    else 
            cut_scanmode <= 1;
    end
    else 
        cut_scanmode <= 0;   //Shouldn't this be zero?
end

//BistDone
always @ (posedge clk) begin
    if ((~rst) && (bistmode)) begin
	    if (t_cyc_count == `TOT_CYC ) 
            bistdone <= 1;
	    else 
            bistdone <= 0;
    end
    else 
        bistdone <= 0;
end

//LFSR Generator
always @ (posedge (clk & cut_scanmode)) begin
    if ((~rst) && (bistmode)) begin
	    LFSR[16] <= LFSR[1];
	    LFSR[15] <= LFSR[16];
	    LFSR[14] <= LFSR[15];
	    LFSR[13] <= LFSR[14];
	    LFSR[12] <= LFSR[13];
	    LFSR[11] <= LFSR[12];
	    LFSR[10] <= LFSR[11];
	    LFSR[9]  <= LFSR[10];
	    LFSR[8]  <= LFSR[9];
	    LFSR[7]  <= LFSR[8];
	    LFSR[6]  <= LFSR[7];
	    LFSR[5]  <= LFSR[6] ^ LFSR[1];
	    LFSR[4]  <= LFSR[5] ^ LFSR[1];
	    LFSR[3]  <= LFSR[4] ^ LFSR[1];
	    LFSR[2]  <= LFSR[3];
	    LFSR[1]  <= LFSR[2];
  end
  else
        LFSR <= 16'hFFFF;
end

//MISR Generator
always @ (posedge (clk) ) begin
    if ((~rst) && (bistmode)) begin
	    if (MISR_en) begin
		    MISR[16] <= MISR[1] ^ cut_sdo;
		    MISR[15] <= MISR[16];
		    MISR[14] <= MISR[15];
		    MISR[13] <= MISR[14];
		    MISR[12] <= MISR[13];
		    MISR[11] <= MISR[12];
		    MISR[10] <= MISR[11];
		    MISR[9]  <= MISR[10];
		    MISR[8]  <= MISR[9];
		    MISR[7]  <= MISR[8];
		    MISR[6]  <= MISR[7];
		    MISR[5]  <= MISR[6] ^ MISR[1];
		    MISR[4]  <= MISR[5] ^ MISR[1];
		    MISR[3]  <= MISR[4] ^ MISR[1];
		    MISR[2]  <= MISR[3];
		    MISR[1]  <= MISR[2];
	    end
    end
    else 
        MISR <= 16'h0;
end
endmodule  

module chip(clk,rst,pi,po,bistmode,bistdone,bistpass);
  input          clk;
  input          rst;
  input	 [34:0]  pi;
  output [48:0]  po;
  input          bistmode;
  output         bistdone;
  output         bistpass;

  wire           cut_scanmode,cut_sdi,cut_sdo;

  reg x;
  wire w_x;
  assign w_x = x;

  scan_cut circuit(bistmode,cut_scanmode,cut_sdi,cut_sdo,clk,rst,
         pi[0],pi[1],pi[2],pi[3],pi[4],pi[5],pi[6],pi[7],pi[8],pi[9],
         pi[10],pi[11],pi[12],pi[13],pi[14],pi[15],pi[16],pi[17],pi[18],pi[19],
         pi[20],pi[21],pi[22],pi[23],pi[24],pi[25],pi[26],pi[27],pi[28],pi[29],
         pi[30],pi[31],pi[32],pi[33],pi[34],
         po[0],po[1],po[2],po[3],po[4],po[5],po[6],po[7],po[8],po[9],
         po[10],po[11],po[12],po[13],po[14],po[15],po[16],po[17],po[18],po[19],
         po[20],po[21],po[22],po[23],po[24],po[25],po[26],po[27],po[28],po[29],
         po[30],po[31],po[32],po[33],po[34],po[35],po[36],po[37],po[38],po[39],
         po[40],po[41],po[42],po[43],po[44],po[45],po[46],po[47],po[48]);
  bist_hardware bist( clk,rst,bistmode,bistdone,bistpass,cut_scanmode,
                     cut_sdi,cut_sdo);
  
endmodule
