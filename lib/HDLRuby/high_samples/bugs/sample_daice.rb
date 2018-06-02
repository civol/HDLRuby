require 'HDLRuby'
configure_high

#電子サイコロ
system :saikoro do

	input :ck,:reset,:enable
	[6..0].output :lamp
	[2..0].inner :cnt

#1始まりの6進カウンタ
	par(ck.posedge,reset.posedge) do
	  hif(reset==_b1b1) do
		cnt<=_b3h1
	  end
	  helsif(enable==_b1b1) do
		hif(cnt<=_b3h6) do
			cnt<=_b3h1
	    end
		helse do
			cnt<=cnt+_b3h1
		end
	  end
	end
	
	# [6..0].function :dec
	# [2..0].input    :din
	par do
	    hcase(cnt) 
		hwhen _b3h1 do
			lamp <= _b7b0001000
		end
		hwhen _b3h2 do
			lamp <= _b7b1000001
		end
		hwhen _b3h3 do 
			lamp <= _b7b0011100
		end
		hwhen _b3h4 do 
			lamp <= _b7b1010101
		end
		hwhen _b3h5 do 
			lamp <= _b7b1011101
		end
		hwhen _b3h6 do
			lamp <= _b7b1110111
		end
		helse do
			lamp <= _b7bxxxxxxx
	    end
    end
	
	# lamp<=dec(cnt)
end

saikoro :saikoroI
puts saikoroI.to_low.to_yaml
