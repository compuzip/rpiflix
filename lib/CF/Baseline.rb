module CF
	class Baseline
		def train
			# no-op
		end
		
		def rate(movie, customer, date)
			custAvg = Rating.where(customer: customer).average('rating')
			movieAvg = Rating.where(movie: movie).average('rating')
			
			return (custAvg + movieAvg) / 2.0
		end
	end
end