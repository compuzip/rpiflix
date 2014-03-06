require 'thread/pool'

module CF

	# loosely based on GrandPrize2009_BPC_BellKor.pdf	
	class Baseline < Base
		class GlobalStats < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
		
		class CustomerBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
		
		class MovieBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
	
		def train_do
			reset_do
			
			pool = Thread.pool(10)
			
			puts 'calculating global stats'
			globalCount = Rating.count
			globalSum = Rating.sum('rating')
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
			
			customers.each_slice(10) do |task_slice|
				# pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						# id, bias, count
						values = []
						
						min = task_slice.min
						max = task_slice.max
						ratings = Rating.where(customer: min..max)
						r2 = ratings.map do |r|
							[r.customer, r.rating - globalMean - movieStats[r.movie][1]]
						end
						
						puts r2
						
						r3 = r2.group_by { |r| r[0]}
						r3.each do |r|
							sum = r.map{|i| i[1]}.reduce(:+)
							puts sum
						end
						
						raise 'aaaa'
						
						# task_slice.each do |c|
							bias = 0
							
							ratings.each do |r|
								bias += r.rating - globalMean - movieStats[r.movie][1]
							end
							bias = bias / ratings.size.to_f
							values << [c, bias, ratings.size]
						# end
						
						CustomerBias.import( [:id, :bias, :rating_count], values, :validate => false)
					end
				# end
			end
			
			raise 'pause'
			
			

			custCount = customers.size
			custMax = customers.max
			
			puts 'custCount: ' + custCount.to_s
			puts 'custMax: ' + custMax.to_s
			
			
			
			columns = [:id, :rating_count, :rating_avg]
			
			customers.each_slice(10000) do |task_slice|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						values = []
						min = task_slice.min
						max = task_slice.max
						# task_slice.each_slice(1000) do |db_slice|
							r3 = Rating.where(customer: min..max).group(:customer).pluck(:customer, 'COUNT(*)', 'SUM(rating)')
							r3.each do |r|
								values << [r[0], r[1], r[2] / (1.0 * r[1])]
							end
						# end
					
						CustomerAvg.import(columns, values, :validate => false)	
					end
					
					puts task_slice[-1]
					progress(task_slice[-1] / (1.0 * custMax))
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
			load_movie_cache if @movie_avg_cache.nil?
			load_customer_cache if @customer_avg_cache.nil?
			
			custAvg = @customer_avg_cache[customer]
			movieAvg = @movie_avg_cache[movie]
			
			return (custAvg + movieAvg) / 2.0
		end
		
		def load_customer_cache
			max = CustomerAvg.maximum(:id)
			@customer_avg_cache = Array.new(max + 1)
			
			CustomerAvg.all.each do |c|
				@customer_avg_cache[c.id] = c.rating_avg
			end
		end
		
		def load_movie_cache
			max = Movie.maximum(:id)
			@movie_avg_cache = Array.new(max + 1)
			
			Movie.all.each do |m|
				@movie_avg_cache[m.id] = m.rating_avg
			end
		end
		
	end
end