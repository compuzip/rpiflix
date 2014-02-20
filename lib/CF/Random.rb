module CF
	class Random < Base
		puts "registering RANDOM"
		register "Random"
	
		def calibrate
			# no-op
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end