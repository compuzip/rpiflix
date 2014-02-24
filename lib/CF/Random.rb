module CF
	class Random < Base		
		def train_do
			sleep 5
		end
		
		def reset_do
			sleep 5
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end