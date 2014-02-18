class Random
	def initialize
		# no-op
	end
	
	def rate(customer, movie, date)
		return rand * 4 + 1
	end
end