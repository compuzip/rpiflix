require 'thread/pool'

module CF

	# loosely based on GrandPrize2009_BPC_BellKor.pdf	
	class Baseline < Base
		class GlobalStats < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
		
		class MovieBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
		
		class CustomerBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
	
		def train_do
			reset_do
			
			pool = Thread.pool(Rails.configuration.max_threads)
			
			puts 'calculating global stats'
			globalCount = Rating.count
			globalSum = Rating.sum('rating')
			
			# globalCount = 99072112
			# globalSum = 356986963
			
			globalMean = globalSum / globalCount.to_f
			
			GlobalStats.create(mean: globalMean, count: globalCount)
			
			puts 'calculating movie bias'
			# id, bias, count
			movieStats = Array.new(Movie.count + 1)
			
			Movie.all.each do |m|
				movieStats[m.id] = [m.id, m.rating_avg - globalMean, m.rating_count]
			end
			
			MovieBias.import( [:id, :bias, :rating_count], movieStats.last(movieStats.size - 1), :validate => false)
			
			puts 'calculating customer bias'
			customers = Rating.distinct.order(:customer).pluck(:customer)
			
			customers.each_slice(1000) do |task_slice|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						# id, bias, count
						values = []
						
						min = task_slice.min
						max = task_slice.max
						ratings = Rating.where(customer: min..max)
						r2 = ratings.map do |r|
							[r.customer, r.rating - globalMean - movieStats[r.movie][1]]
						end
						
						# group by customer
						r3 = r2.group_by { |r| r[0]}
						r3.each do |k, v|
							sum = v.inject(0) do |s, o|
								s + o[1]
							end
							
							values << [k, sum / v.size, v.size]
						end
						
						CustomerBias.import( [:id, :bias, :rating_count], values, :validate => false)
					end
				end
			end
			
			puts 'joining...'
			pool.shutdown			
			puts 'joined'
		end
		
		def reset_do
			GlobalStats.connection.create_table(GlobalStats.table_name, force: true) do |t|
				t.float 	:mean
				t.integer	:count
			end
			
			MovieBias.connection.create_table(MovieBias.table_name, force: true) do |t|
				t.float 	:bias
				t.integer	:rating_count
			end
			
			CustomerBias.connection.create_table(CustomerBias.table_name, force: true) do |t|
				t.float 	:bias
				t.integer	:rating_count
			end
		end
		
		def rate(movie, customer, date)
			populate_caches
			
			pred = @cache_global_mean + @cache_customer[customer] + @cache_movie[movie]
			
			[[pred, 5].min, 1].max
		end
		
	private
		def populate_caches
			if @cache_global_mean.nil?
				@cache_global_mean =  GlobalStats.first.mean
				@cache_movie = load_movie_cache
				@cache_customer = load_customer_cache
			end
		end
		
		def load_customer_cache
			max = CustomerBias.maximum(:id)
			customer_cache = Array.new(max + 1)
			
			CustomerBias.all.each do |c|
				customer_cache[c.id] = c.bias
			end
			
			customer_cache
		end
		
		def load_movie_cache
			max = MovieBias.maximum(:id)
			movie_cache = Array.new(max + 1)
			
			MovieBias.all.each do |m|
				movie_cache[m.id] = m.bias
			end
			
			movie_cache
		end
		
	end
end