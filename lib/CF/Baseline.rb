module CF
	class Baseline < Base
		def initialize(model)
			super(model)
		end
	
		def train
			train_begin
			
			train_end
		end
		
		def reset
			reset_begin
			
			reset_end
		end
		
		def rate(movie, customer, date)
			custAvg = Rating.where(customer: customer).average('rating')
			movieAvg = Rating.where(movie: movie).average('rating')
			
			return (custAvg + movieAvg) / 2.0
		end
	end
end