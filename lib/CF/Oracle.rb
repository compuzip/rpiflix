module CF
	class Oracle
		def self.score(model)
			sse = 0.0
			count = 0
		
			Probe.all.each do |r|
				error = r.rating - model.rate(r.movie, r.customer, r.date)
				sse += error * error
				count += 1
			end
		
			return Math.sqrt(sse / count)
		end
	end
end