module CF
	class Random < Base
		def initialize(model)
			super(model)
		end
		
		def train
			train_begin
			
			sleep 5
			
			train_end
		end
		
		def reset
			reset_begin
			
			reset_end
		end
		
		def rate(movie, customer, date)
			return rand * 4 + 1
		end
	end
end