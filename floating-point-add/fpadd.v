module fpadd (
    clk, reset, start,
    a, b,
    sum, 
    done
);
    input clk, reset, start;
    input [31:0] a, b;
    output [31:0] sum;
    output done;
    
    reg sign_a, sign_b, sign_r;
    reg [7:0] exp_a, exp_b, exp_r;
    reg [25:0] mant_a, mant_b;
    reg [25:0] mant_r;
    reg sum, done;
    reg [23:0] mant_sum;
    
    parameter IDLE = 3'b000;
    parameter SIGN = 3'b001;
    parameter SHIFT = 3'b010;
    parameter ADD = 3'b011;
    parameter NORM = 3'b100;
    parameter SEARCH = 3'b101;
    parameter FIN = 3'b110;
    parameter RESSIGN = 3'b111;
    reg[2:0] pres_state, next_state;
    
    always @(posedge clk)
    begin
    if(reset) begin
	exp_a <= 0; exp_b <= 0; 
    end
    // 1.
    else if(start) begin
    	sign_a <= a[31];
    	sign_b <= b[31];
	exp_a <= a[30:23];
	exp_b <= b[30:23];
    	mant_a <= {3'b001, a[22:0]};
    	mant_b <= {3'b001, b[22:0]};
    	done <= 0;
    	pres_state <= IDLE;
    end
    else begin
    	case(pres_state)
    	IDLE: //2.
    	begin
//	   	//$display("IDLE %3b", pres_state);
	    	
	    	if ((exp_a == 8'b0) && (mant_a[22:0] == 22'b0 && mant_a[23] == 1'b1)) begin
			sum <= b;
			done <= 1;
			pres_state <= FIN;
	    	end
	    	else if ((exp_b == 8'b0) && (mant_b[22:0] == 22'b0 && mant_b[23] == 1'b1)) begin
			sum <= a;
			done <= 1;
			pres_state <= FIN;
	    	end
		else if (exp_a == 8'b11111111) begin
			sum <= a;
			done <= 1;
			pres_state <= FIN;
		end
		else if (exp_b == 8'b11111111) begin
			sum <= b;
			done <= 1;
			pres_state <= FIN;
		end
		else begin
			pres_state <= SIGN;
		end

	end	
	
	
	SIGN: //3.1
	begin
		if (sign_a) begin
			//$display("SIGN: b is negative, mant_b is	 	%26b", mant_a);
			mant_a <= ~mant_a + 1;
			//$display("SIGN: a is negative, 2s c of mant_a is %26b", mant_a);
		end
		if (sign_b) begin
			//$display("SIGN: b is negative, mant_b is 		%26b", mant_b);
			mant_b <= ~mant_b + 1;
			//$display("SIGN: b is negative, 2s c of mant_b is %26b", mant_b);
		end
		pres_state <= SHIFT;
	end
	
	SHIFT: //3.2
	begin
		//$display("SHIFT: sign_a %1b, exp_a %8b, mant_a %26b", sign_a, exp_a, mant_a);
		//$display("SHIFT: sign_b %1b, exp_b %8b, mant_b %26b\n", sign_b, exp_b, mant_b);
		if(exp_a > exp_b) begin
			mant_b <= {sign_b, mant_b[25:1]};
			exp_b <= exp_b + 1;
			exp_r <= exp_a;
		end
		else if(exp_a < exp_b) begin
			mant_a <= {sign_a, mant_a[25:1]};
			exp_a <= exp_a + 1;
			exp_r <= exp_b;
		end
		else
			exp_r <= exp_a;
		pres_state <= (exp_a == exp_b) ? ADD : pres_state;
	end
	
	ADD: //3.3
	begin
		mant_r <= mant_a + mant_b;
		pres_state <= RESSIGN;
	end
	
	RESSIGN: //3.4
	begin
		if (mant_r[25] == 1) begin
			sign_r <= 1;
			mant_r <= -mant_r;
		end else begin
			sign_r <= 0;
		end
		//$display("RESSIGN: sign_a %1b, exp_a %8b, mant_a %26b", sign_a, exp_a, mant_a);
		//$display("RESSIGN: sign_b %1b, exp_b %8b, mant_b %26b", sign_b, exp_b, mant_b);
		//$display("RESSIGN: sign_r %1b, exp_r %8b, mant_r %26b\n", sign_r, exp_r, mant_r);
		pres_state <= NORM;
	end
	
	NORM: //3.5
	begin
		//$display("NORM: sign_a %1b, exp_a %8b, mant_a %26b", sign_a, exp_a, mant_a);
		//$display("NORM: sign_b %1b, exp_b %8b, mant_b %26b", sign_b, exp_b, mant_b);
		//$display("NORM: sign_r %1b, exp_r %8b, mant_r %26b\n", sign_r, exp_r, mant_r);*/
		if (mant_r == 0) begin
			// 3.5.1 Only possible if numbers cancelled out!
			exp_r <= 0;
			pres_state <= FIN;
		end else if ((mant_r[24] == 0) && (mant_r[23] == 1)) begin
			// 3.5.2 nothing to do everyone is happy
			pres_state <= FIN;
		end else if (mant_r[24] == 1) begin
			// 3.5.3 Overflow - renormalize
			mant_r <= mant_r >> 1;
			exp_r  <= exp_r + 1;
			pres_state <= FIN;
		end else
			pres_state <= SEARCH;
	end
	
	SEARCH: // 3.5.4 a-b small: search for leading one and renormalize - 
	begin
		if(mant_r[23] != 1) begin
			mant_r <= mant_r << 1;
			exp_r  <= exp_r - 1;
			pres_state <= SEARCH;
		end else
			pres_state <= FIN;
	end
	
	FIN:
	begin
		sum <= {sign_r, exp_r, {mant_r[22:0]}};
		//$display("FIN: sign_r %1b, exp_r %8b, mant_r %26b\n", sign_r, exp_r, mant_r);
		done <= 1;
	end
	
	endcase

	//$display("mant_a is %8b, mant_b is %8b, sum is %8b", mant_a, mant_b, sum);
    end
    end

endmodule
