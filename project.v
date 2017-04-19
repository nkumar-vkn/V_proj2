`define TOT_CYC 20'd530000
//`define TOT_CYC 20'd100000
// 2000*263 + 2000 + 2000
`define log_TOT_CYC 20

`define SING_CYC 9'd264
//35(ip)+179(DFF)+49(op)+1
`define log_SING_CYC 9

`define GOLDEN_ANS 16'b0001_1001_1000_0001 

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

reg LFSR[16:1];
reg LFSR_sig[16:1];
reg [`log_SING_CYC:0]  s_cyc_count;
reg [`log_TOT_CYC:0]  t_cyc_count;

integer i;
reg firstscan;

reg LFSR_sig_en;
reg LFSR_en;

initial
begin
	for (i=1; i<=16; i=i+1) 
	begin
		LFSR[i] = 1'b1;
		LFSR_sig[i] = 1'b0;
	end
	s_cyc_count = 6'd1;
	t_cyc_count = 11'd1;
     bistdone    = 0;
     bistpass    = 0;
     cut_scanmode= 0;

	LFSR_en = 1 ; //hardcoded 
end

assign cut_sdi = LFSR[1];

always @ (negedge clk) LFSR_sig_en <= cut_scanmode & ~firstscan;

always @ (posedge clk)
begin
  if (t_cyc_count == (`TOT_CYC - 1) )
  begin
    $display("\n ");
    $display("%b %b %b %b %b %b %b %b %b %b %b %b %b %b %b %b ",LFSR_sig[1],LFSR_sig[2],LFSR_sig[3],LFSR_sig[4],LFSR_sig[5],LFSR_sig[6],LFSR_sig[7],LFSR_sig[8],LFSR_sig[9],LFSR_sig[10],LFSR_sig[11],LFSR_sig[12],LFSR_sig[13],LFSR_sig[14],LFSR_sig[15],LFSR_sig[16]);
    if ({LFSR_sig[1],LFSR_sig[2],LFSR_sig[3],LFSR_sig[4],LFSR_sig[5],LFSR_sig[6],LFSR_sig[7],LFSR_sig[8],LFSR_sig[9],LFSR_sig[10],LFSR_sig[11],LFSR_sig[12],LFSR_sig[13],LFSR_sig[14],LFSR_sig[15],LFSR_sig[16]} == `GOLDEN_ANS)
    bistpass <= 1;
    else bistpass <= 0;
  end
  else bistpass <= 0;
end

always @ (posedge clk)
begin
  if(~rst)
  begin
    if (t_cyc_count < (`SING_CYC -1) ) firstscan <= 1;
    else firstscan <= 0;
  end
  else firstscan <= 1;
end

always @ (posedge clk) //not completely necessary 
begin
  //if((s_cyc_count < 13) || (s_cyc_count == 48) || (s_cyc_count == 49)) LFSR_en <= 0;
  if(s_cyc_count == (`SING_CYC - 1)) LFSR_en <= 0;
  else LFSR_en <= 1;
end

always @ (posedge clk) //counters
begin
  if (~rst)
  begin
     if (bistmode)
  	begin
  	   if (s_cyc_count != `SING_CYC) s_cyc_count <= s_cyc_count + 1;
  	   else s_cyc_count <= 1;

  	   if (t_cyc_count != `TOT_CYC) t_cyc_count <= t_cyc_count + 1;
  	   else t_cyc_count <= 1;
  	end
  	else
  	begin
        s_cyc_count <= s_cyc_count;
  	   t_cyc_count <= t_cyc_count;
  	end
  end
  else
  begin
  	s_cyc_count <= 1;
     t_cyc_count <= 1;
  end

end

always @ (posedge clk) //scanmode
begin
  if ((~rst)&&(bistmode))
  begin
	if (s_cyc_count == (`SING_CYC - 1)) cut_scanmode = 0; 
	else cut_scanmode = 1;
  end
  else cut_scanmode = 1;
end

always @ (posedge clk) //bistdone
begin
  if ((~rst)&&(bistmode))
  begin
	if (t_cyc_count == `TOT_CYC ) bistdone = 1;
	else bistdone = 0;
  end
  else bistdone = 0;
end

always @ (posedge clk) //bist_pass to be completed
begin
  bistpass <= 0;
end

always @ (posedge (clk & cut_scanmode) ) //LFSR generator
begin
  if ((~rst)&&(bistmode))
  begin
    if (LFSR_en)
    begin
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
	begin
		LFSR[16] <= LFSR[16]; 
		LFSR[15] <= LFSR[15];
		LFSR[14] <= LFSR[14];
		LFSR[13] <= LFSR[13];
		LFSR[12] <= LFSR[12];
		LFSR[11] <= LFSR[11];
		LFSR[10] <= LFSR[10];
		LFSR[9]  <= LFSR[9] ;
		LFSR[8]  <= LFSR[8] ;
		LFSR[7]  <= LFSR[7] ;
		LFSR[6]  <= LFSR[6] ;
		LFSR[5]  <= LFSR[5] ; 
		LFSR[4]  <= LFSR[4] ; 
		LFSR[3]  <= LFSR[3] ; 
		LFSR[2]  <= LFSR[2] ;
		LFSR[1]  <= LFSR[1] ;
	end
  end
  else for (i=1; i<=16; i=i+1) LFSR[i] = 1'b1;
end

always @ (posedge (clk) ) //LFSR sig_gen
begin
  if ((~rst)&&(bistmode))
  begin
	if (LFSR_sig_en)
	begin
		LFSR_sig[16] <= LFSR_sig[1] ^ cut_sdo;
		LFSR_sig[15] <= LFSR_sig[16];
		LFSR_sig[14] <= LFSR_sig[15];
		LFSR_sig[13] <= LFSR_sig[14];
		LFSR_sig[12] <= LFSR_sig[13];
		LFSR_sig[11] <= LFSR_sig[12];
		LFSR_sig[10] <= LFSR_sig[11];
		LFSR_sig[9]  <= LFSR_sig[10];
		LFSR_sig[8]  <= LFSR_sig[9];
		LFSR_sig[7]  <= LFSR_sig[8];
		LFSR_sig[6]  <= LFSR_sig[7];
		LFSR_sig[5]  <= LFSR_sig[6] ^ LFSR_sig[1];
		LFSR_sig[4]  <= LFSR_sig[5] ^ LFSR_sig[1];
		LFSR_sig[3]  <= LFSR_sig[4] ^ LFSR_sig[1];
		LFSR_sig[2]  <= LFSR_sig[3];
		LFSR_sig[1]  <= LFSR_sig[2];
	end
    else
    begin
	   LFSR_sig[16] <= LFSR_sig[16]; 
	   LFSR_sig[15] <= LFSR_sig[15];
	   LFSR_sig[14] <= LFSR_sig[14];
	   LFSR_sig[13] <= LFSR_sig[13];
	   LFSR_sig[12] <= LFSR_sig[12];
	   LFSR_sig[11] <= LFSR_sig[11];
	   LFSR_sig[10] <= LFSR_sig[10];
	   LFSR_sig[9]  <= LFSR_sig[9] ;
	   LFSR_sig[8]  <= LFSR_sig[8] ;
	   LFSR_sig[7]  <= LFSR_sig[7] ;
	   LFSR_sig[6]  <= LFSR_sig[6] ;
	   LFSR_sig[5]  <= LFSR_sig[5] ; 
	   LFSR_sig[4]  <= LFSR_sig[4] ; 
	   LFSR_sig[3]  <= LFSR_sig[3] ; 
	   LFSR_sig[2]  <= LFSR_sig[2] ;
	   LFSR_sig[1]  <= LFSR_sig[1] ;
    end
  end
  else begin for(i=1; i<=16; i=i+1) LFSR_sig[i] = 1'b0; end
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
