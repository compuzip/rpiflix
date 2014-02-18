class Random
	def calibrate
		# no-op
	end
	
	def rate(movie, customer, date)
		return rand * 4 + 1
	end
end