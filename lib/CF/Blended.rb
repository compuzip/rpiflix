module CF
	# simple linear blend of SVD and Baseline
	class Blended < Base
	
		def train_do
		end
		
		def reset_do
		end
		
		def rate(movie, customer, date)
			if @baseline.nil?
				@baseline = Model.where(klass: :Baseline2).take.handler
			end
			
			if @svd.nil?
				@svd = Model.where(klass: :SVD).take.handler
			end

			svd_weight = 0.85
			
			(1 - svd_weight) * @baseline.rate(movie, customer, date) + svd_weight * @svd.rate(movie, customer, date)
		end
	
	end
end