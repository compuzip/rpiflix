module CF
	class Random < Base
		def initialize(model)
			super(model)
		end
		
		def train
			sleep 5
		end
		
		def reset
			sleep 5
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end