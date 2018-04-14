require 'HDLRuby'
configure_high

#電子サイコロ
system :saikoro do

	input :ck,:reset,:enable
	[6..0].output :lamp
	[2..0].inner :cnt

#1始まりの6進カウンタ
	behavior(ck.posedge,reset.posedge) do
	  hif(reset==b1b1) do
		cnt<=b3h1
	  end
	  helsif(enable==b1b1) do
		hif(cnt<=b3h6) do
			cnt<=b3h1
	    end
		helse do
			cnt<=cnt+b3h1
		end
	  end
	end
	
	# [6..0].function :dec
	# [2..0].input    :din
	behavior do
	    hcase(cnt) 
		hwhen b3h1 do
			lamp <= b7b0001000
		end
		hwhen b3h2 do
			lamp <= b7b1000001
		end
		hwhen b3h3 do 
			lamp <= b7b0011100
		end
		hwhen b3h4 do 
			lamp <= b7b1010101
		end
		hwhen b3h5 do 
			lamp <= b7b1011101
		end
		hwhen b3h6 do
			lamp <= b7b1110111
		end
		helse do
			lamp <= b7bxxxxxxx
	    end
    end
	
	# lamp<=dec(cnt)
end

saikoro :saikoroI
puts saikoroI.to_low.to_yaml
