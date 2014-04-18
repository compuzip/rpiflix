module CF

	# 'average' rating for everyone
	class Average < Base
		class Stats < ActiveRecord::Base
			self.table_name_prefix = 'average_'
		end
		
		def train_do
			puts 'calculating global stats'
			globalCount = Rating.count
			globalSum = Rating.sum('rating')
			
			globalMean = globalSum / globalCount.to_f
			
			Stats.create(mean: globalMean, count: globalCount)
		end
		
		def reset_do
			Stats.connection.create_table(Stats.table_name, force: true) do |t|
				t.float 	:mean
				t.integer	:count
			end
		end
		
		def rate(movie, customer, date)
			populate_cache
			
			@cache_global_mean
		end
	
	private
		def populate_cache
			if @cache_global_mean.nil?
				@cache_global_mean =  Stats.first.mean
			end
		end
	end	
end