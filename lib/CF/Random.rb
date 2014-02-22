module CF
	class Random < Base
		def initialize(model)
			super(model)
		end
		
		def train_do
			sleep 10
		end
		
		def reset_do
			sleep 10
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end