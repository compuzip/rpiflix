module CF
	class Random < Base
		def train
			# no-op
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end