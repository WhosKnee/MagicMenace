`define CLK posedge CLOCK_50

module DE2_115_top(
	//////// CLOCK //////////
	input 							CLOCK_50,
	
	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		    [17:0]		SW,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,
	output		     [6:0]		HEX6,
	output		     [6:0]		HEX7,

	//////////// VGA //////////
	output		     [7:0]		VGA_B,
	output		          		VGA_BLANK_N,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS
	
);

// VGA pixel and letter display referenced from: https://github.com/Derek-X-Wang/VGA-Text-Generator?files=1

//------- VGA PORTION ----------//	
    localparam NO_OF_LETTERS = 16;
 	integer i=0; 	// horizontal counter
	integer j=0;	// Vertical counter
	integer k=1; 	// letter counter
	integer p=1; 	// letterA counter
	reg 	[2:0] colour;
	reg 	[7:0] x[1:NO_OF_LETTERS]; // Pixel Location
	reg 	[6:0] y[1:NO_OF_LETTERS];
	reg 	[7:0] xA[1:NO_OF_LETTERS]; // Pixel Locaiton of Bottom Row
	reg 	[6:0] yA[1:NO_OF_LETTERS];
	reg	[7:0] xB; // Pixel location of the current letter during the game state
	reg 	[6:0] yB;
   reg 			writeEn;	
	wire 			resetn;
	assign resetn = 1;  // Ensure reset is always high so that the user doesn't turn it off
	reg [3:0] letters[1:NO_OF_LETTERS]; 	// The top row of letters
	reg [3:0] lettersA[1:NO_OF_LETTERS];	// The bottom row of letters
	reg [3:0] lettersB;							// The current letter selected during game state
	reg       enable  [1:NO_OF_LETTERS];
	reg       enableA [1:NO_OF_LETTERS];
	reg 		 enableB;

	wire [2:0] letter_color= SW[16:14];// use SW[17:15] to change color of the letter

	wire pixel_writeEn[1:NO_OF_LETTERS]; // indicates whether to write to pixel of a letter or not
	wire pixel_writeEnA[1:NO_OF_LETTERS];
	wire pixel_writeEnB;
	
	// Check whether the pixel should be on or off for the current letter and location
	generate 
        genvar gi;
        for(gi = 1 ; gi <=NO_OF_LETTERS;gi=gi+1) begin:gen_letters1
	        letterROMSV Letter(letters[gi],x[gi],y[gi],pixel_writeEn[gi]);// Letter i
        end
    endgenerate
	generate 
        genvar giA;
        for(giA = 1 ; giA <=NO_OF_LETTERS;giA=giA+1) begin:gen_letters2
	        letterROMSV LetterA(lettersA[giA],xA[giA],yA[giA],pixel_writeEnA[giA]);// Letter A
        end
    endgenerate

	 letterROMSV LetterB(lettersB,xB,yB,pixel_writeEnB); // current letter selected during game state
	 
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(i),
			.y(j),
			.plot(writeEn),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	
always@(`CLK)begin
//----	traverse from top left corner to bottom right corner---//
	if(i<159) 		
		i<=i+1; 
	else begin
		i<=0; // lets sweep from top left corner to bottom right pixels
		if(j<120) j<=j+1; else j<=0;		
	end
	
	// Goes through every letter in the top row array and bottom row array to check whether it should be printed, or else print black
	
	for(k=1;k<=NO_OF_LETTERS;k=k+1)begin // top row
		if( i<8*k && i>=8*(k-1) && j<16 && enable[k])begin  
		    x[k] <= i-(8*(k-1));
			y[k] <= j; 
			if(pixel_writeEn[k])begin
				colour <= letter_color;
				writeEn <= 1'b1;
			end
			else begin
				colour <=3'b000;
				writeEn <= 1'b1;		
			end	
		end
	  else if(i<8*k && i>=8*(k-1) && j<16 && !enable[k])begin
			colour <=3'b000;
			writeEn <= 1'b1;	  
	  end 
	end
	
	// print black where letters will not be shown, prevents extra pixels of the rightmost letter in a row
	
	if(j<96 && j>=80 && (i<80 || i>=88))begin
		colour <=3'b000;
		writeEn <= 1'b1;	
	end
	else if(i>=128)begin
		colour <=3'b000;
		writeEn <= 1'b1;	
	end
	

	// Goes through every letter in the bottom row array and bottom row array to check whether it should be printed, or else print black
    for(p=1;p<=NO_OF_LETTERS;p=p+1)begin // bottom row
		if( i<8*p && i>=8*(p-1) && j<36 && j>=20 && enableA[p])begin  
		    xA[p] <= i-(8*(p-1));
			yA[p] <= j-20; 
			if(pixel_writeEnA[p])begin
				colour <= letter_color;
				writeEn <= 1'b1;
			end
			else begin
				colour <=3'b000;
				writeEn <= 1'b1;		
			end	
		end
	  else if(i<8*p && i>=8*(p-1) && j<36 && j>=20 && !enableA[p])begin
			colour <=3'b000;
			writeEn <= 1'b1;	  
	  end
	end
	
	// Test letter
	if(i<88 && i>=80 && j<96 && j>=80 && enableB)begin //test letter is positioned @ x=80 and y=80 location
		xB <= i - 80;
		yB <= j - 80;
		if(pixel_writeEnB)begin
			colour  <= letter_color;
			writeEn <= 1'b1;
		end
		else begin
			colour  <= 3'b000;
			writeEn <= 1'b1;		
		end

	end	  
	   else if(i<88 && i>=80 && j<96 && j>=80 && !enableB)begin
			colour <=3'b000;
			writeEn <= 1'b1;	  
	   end
end
    
//------- END OF VGA PORTION ----------//		
	localparam INITIAL=0;
	localparam PREGAME=1;
	localparam GAME	=2;
    localparam DEBOUNCE = 3;
    localparam VGA_HELLO=4;
    localparam RANDOM_LETTERS=5;
    localparam DEBOUNCE2 = 6;
    localparam CHECK_ANSWER = 7;

	
	// create the appropriate reg values which will be updated throughout the game
	reg [3:0] word_memory[1:4];   // Memory  which holds 4 words of 4 bits each(4bits=16 letters)
	reg [3:0] state=INITIAL;  	  // state variable
	reg [5:0] time_remaining;
	reg [5:0] score;
	reg [5:0] incorrect;
	reg [24:0] CLK_COUNTER = 16'd0;
   integer wi=0;
   reg [3:0] answer_count=0;
	
	// Always display 4 letters stored in memory
	SEG7_LUT NUMBER1(HEX0,word_memory[1]);  // memory of word 1 into HEX0
	SEG7_LUT NUMBER2(HEX1,word_memory[2]); 	// memory of word 2 into HEX1
	SEG7_LUT NUMBER3(HEX2,word_memory[3]); 	// memory of word 3 into HEX2
	SEG7_LUT NUMBER4(HEX3,word_memory[4]); 	// memory of word 4 into HEX3
	// always display the time remaining
	hex_7seg TIME_DEC_10	(HEX7,time_remaining/10); // time remaining 10th place no
	hex_7seg TIME_DEC_1	    (HEX6,time_remaining%10);  // time remaining unit place no
	// always display the score obtained
	hex_7seg Score_10		(HEX5,score/10); // Score 10th place no
	hex_7seg Score_1		(HEX4,score%10);  // score unit place no
	
   // RANDOM NUMBER GENRATION USING LINEAR FEEDBACK SHIFT REGISTER
	wire 	[3:0]rand_out;
	reg		[3:0]rand_buffer[1:NO_OF_LETTERS];
	
   always@(`CLK)begin
		rand_buffer[1] <= rand_out;
		for(k=2;k<=NO_OF_LETTERS;k=k+1)begin
			rand_buffer[k]<=rand_buffer[k-1];
		end
	end
	
	// creates the random array of letters
	LFSR lfst_inst(rand_out,CLOCK_50);
	
	// State Machine for the program
	always@(`CLK)begin
		case(state)
		// ------------ INITIAL ------------------//
			INITIAL:begin
				time_remaining       <= 6'd60; 		// time remaining is 60
				score				 <= 6'd0;		// Score should be 0
                incorrect            <= 6'd0;
                answer_count        <=0;
				for(wi=1;wi<5;wi=wi+1)begin
					word_memory[wi] = (wi-1) ; // load ABCD					
				end
				state <= VGA_HELLO;
			end
            VGA_HELLO:begin
				    answer_count        <=0;
					 time_remaining       <= 6'd60;
					 incorrect            <= 6'd0;
					 
					 letters[1]		<= 0;	enable[1]	<=0;//
					 letters[2]		<= 0;	enable[2]	<=0;//
					 letters[3]		<= 0;	enable[3]	<=0;//
                letters[4]		<= 0;	enable[4]	<=0;//
                letters[5]		<=12;	enable[5]	<=1;//M
                letters[6]		<= 0;	enable[6]	<=1;//A
                letters[7]		<=12;	enable[7]	<=1;//M
                letters[8]		<= 0;	enable[8]	<=1;//A
					 letters[9]		<= 0;	enable[9]	<=0;//
                letters[10]		<= 0;	enable[10]	<=0;//
                letters[11]		<= 0;	enable[11]	<=0;//
                letters[12]		<=12;	enable[12]	<=1;//M
                letters[13]		<= 8;	enable[13]	<=1;//I
                letters[14]		<= 0;	enable[14]	<=1;//A
                letters[15]		<= 0;	enable[15]	<=0;//
                letters[16]		<= 0;	enable[16]	<=0;//
                
                lettersA[1]		<= 0;		enableA[1]	<=0;//
                lettersA[2]		<= 0;		enableA[2]	<=0;//
                lettersA[3]		<= 0;		enableA[3]	<=0;//
                lettersA[4]		<=12;		enableA[4]	<=1;//M
                lettersA[5]		<= 0;		enableA[5]	<=1;//A
                lettersA[6]		<= 6;		enableA[6]	<=1;//G
                lettersA[7]		<= 8;		enableA[7]	<=1;//I
                lettersA[8]		<= 2;		enableA[8]	<=1;//C
                lettersA[9]		<= 0;		enableA[9]	<=0;//
                lettersA[10]		<=12;		enableA[10]	<=1;//M
                lettersA[11]		<= 4;		enableA[11]	<=1;//E
                lettersA[12]		<=13;		enableA[12]	<=1;//N
                lettersA[13]		<= 0;		enableA[13]	<=1;//A
                lettersA[14]		<= 2;		enableA[14]	<=1;//C
                lettersA[15]		<= 4;		enableA[15]	<=1;//E
					 lettersA[16]		<= 0;		enableA[16]	<=0;//

					 
					 enableB <=0; // turn off current letter in the pre-game state
					 
                state<=PREGAME;
            end
		//------------- PREGAME ----------------------- //
			PREGAME:begin
				//update user input
				if(!KEY[3])begin						 // when user presses the button
					for(wi=1;wi<5;wi=wi+1)begin				 // let us walk over 4 switch 
						if(SW[6+wi])begin				 // from 7 to 10
							word_memory[wi] <= SW[3:0];   // if any of the swithces are high, update the memory with new word [sw[3:0]]
						end	
					end
                    state <= DEBOUNCE2;
				end
				if(!KEY[2])begin// if key[2] is pressed proceed to game state
					state <= RANDOM_LETTERS;
					CLK_COUNTER <= 25'd0;
				end
			end
		//------------- RANDOM LETTERS ----------------------- //
            RANDOM_LETTERS:begin
                for(k=1;k<=NO_OF_LETTERS;k=k+1)begin
                   letters[k]<=rand_buffer[k];//word_memory[(k%4==0)?4:k%4];
                   lettersA[k]<=0;
                   enable[k]<=1'b1;
                   enableA[k]<=1'b0;
                end
                state <= GAME;
					 enableB <= 1;
            end
		// ------------ GAME -------------------- // 
			GAME:begin
				// 1sec counter
				if(SW[17])
					CLK_COUNTER <= CLK_COUNTER + 2'd2;	 // HARD-MODE: lets increase 2by2
				else
					CLK_COUNTER <= CLK_COUNTER + 2'd1;	 // EASY-MODE :lets increase 1by1
					
				if(CLK_COUNTER==25'd0)begin
					if(time_remaining > 0)begin
						time_remaining <= time_remaining - 1'b1;
					end
					else begin
						time_remaining <= 25'd60;
						state <= VGA_HELLO;
					end
				end
					lettersB <= SW[3:0];
        
                if(!KEY[3])begin // user given input
                   enableA[answer_count+1]  <= 1;       
                   if(SW[11:7]!=4'b0000)begin // user has selected preloaded values
                       for(k=1;k<5;k=k+1)begin
                           if(SW[k+6])begin
                               lettersA[answer_count+1] <= word_memory[k];
                           end
                       end
                   end //user has selected preloaded values
                   else begin // user is defining the value
                       lettersA[answer_count+1] <=  SW[3:0];    
                   end // user is defining the value
							answer_count <= answer_count + 1'b1;
							state <= CHECK_ANSWER;
                end//user given input
			end
            DEBOUNCE:begin
                if(KEY[3])state<=GAME;
            end
            DEBOUNCE2:begin
                if(KEY[3])state<=PREGAME;
            end
			CHECK_ANSWER:begin
			score=0;
            incorrect=0;
				for(k=1;k<answer_count;k=k+1)begin
					if(letters[k]==lettersA[k])begin
						score = score + 1'b1;	
					end
                    else begin
                        incorrect = incorrect + 1'b1;
                    end
				end
				if(KEY[3])
					state <= GAME;
			end
        
			default begin
			
			end
		endcase
	end


endmodule


module SEG7_LUT	(segments, hex_value);
    input [3:0] hex_value;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_value)
		// use hexadecimal for the cases
		// note segments are on 'high' when 0
            4'h0: segments = 7'b000_1000;		//A
            4'h1: segments = 7'b000_0011;		//B
            4'h2: segments = 7'b100_0110;		//C
            4'h3: segments = 7'b010_0001;		//D
            4'h4: segments = 7'b000_0110;		//E
            4'h5: segments = 7'b000_1110;		//F
            4'h6: segments = 7'b100_0010;		//G
            4'h7: segments = 7'b000_1001;		//H
            4'h8: segments = 7'b100_1111;		//I
            4'h9: segments = 7'b110_0001;		//J
            4'hA: segments = 7'b000_0101;		//K
            4'hB: segments = 7'b100_0111;		//L
            4'hC: segments = 7'b010_1010;		//M
            4'hD: segments = 7'b010_1011;		//N
            4'hE: segments = 7'b010_0011;		//O
            4'hF: segments = 7'b000_1100;		//P
            default: segments = 7'b000_1000;
        endcase
endmodule

module hex_7seg(segments,hex_digit);
input [3:0] hex_digit;
output [6:0] segments;
reg [6:0] segments;

always @ (hex_digit)
	case (hex_digit)
	// use hexadecimal for the cases
	// note segments are on 'high' when 0
		4'h0: segments = 7'b100_0000;
		4'h1: segments = 7'b111_1001;
		4'h2: segments = 7'b010_0100;
		4'h3: segments = 7'b011_0000;
		4'h4: segments = 7'b001_1001;
		4'h5: segments = 7'b001_0010;
		4'h6: segments = 7'b000_0010;
		4'h7: segments = 7'b111_1000;
		4'h8: segments = 7'b000_0000;
		4'h9: segments = 7'b001_1000;
		4'hA: segments = 7'b000_1000;
		4'hB: segments = 7'b000_0011;
		4'hC: segments = 7'b100_0110;
		4'hD: segments = 7'b010_0001;
		4'hE: segments = 7'b000_0110;
		4'hF: segments = 7'b000_1110; 
	endcase
endmodule

// referenced from: https://vlsicoding.blogspot.com/2014/07/verilog-code-for-4-bit-linear-feedback-shift-register.html

// shifts left one bit, then ~(xor of the popped bit and the new 3rd bit) and puts it as the 0th bit, feedback
module LFSR (out, clk);

  output reg [3:0] out=4'b1011;
  input clk;

  wire feedback;

  assign feedback = ~(out[3] ^ out[2]);

always @(posedge clk)
  begin
      out = {out[2:0],feedback};
  end
endmodule
