class Oracle
	def score(model)
		sse = 0.0
		count = 0
	
		Rating.where(probe: 1).each do |r|
			error = r.rating - model.rate(r.movie, r.customer, r.date)
			sse += error * error
			count += 1
		end
	
		return Math.sqrt(sse / count)
	end
end