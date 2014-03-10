require 'thread/pool'

module CF

	# loosely based on GrandPrize2009_BPC_BellKor.pdf	
	class Baseline2 < Base
		class GlobalStats < ActiveRecord::Base
			self.table_name_prefix = 'baseline2_'
		end
		
		class MovieBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline2_'
		end
		
		class CustomerBias < ActiveRecord::Base
			self.table_name_prefix = 'baseline2_'
		end
	
		def refine_movie_bias
			puts 'refining movie bias'
			global_mean = GlobalStats.take.mean
			pool = Thread.pool(Rails.configuration.max_threads)
			
			movies = MovieBias.order(:id).pluck(:id)
			
			MovieBias.delete_all
			
			movies.each_slice(1000) do |task_slice|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						min = task_slice.min
						max = task_slice.max
						
						sql = "SELECT movie, avg(bias), count(*) FROM
							( SELECT movie, rating - #{global_mean} - #{CustomerBias.table_name}.bias AS bias FROM ratings
								JOIN #{CustomerBias.table_name} ON ratings.customer = #{CustomerBias.table_name}.id
								WHERE movie BETWEEN #{min} AND #{max}
								) as t1
							group by movie"
							
						puts sql
		
						data = conn.select_all(sql)
						
						MovieBias.import([:id, :bias, :rating_count], data.rows, :validate => false)
					end
				end
			end
			
			puts 'joining'
			pool.shutdown
			puts 'joined'
		end
		
		def refine_customer_bias
			puts 'refining customer bias'
			global_mean = GlobalStats.take.mean
			pool = Thread.pool(Rails.configuration.max_threads)
			
			customers = CustomerBias.order(:id).pluck(:id)
			
			CustomerBias.delete_all
			
			customers.each_slice(10000) do |task_slice|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						min = task_slice.min
						max = task_slice.max
						
						sql = "SELECT customer, avg(bias), count(*) FROM
							( SELECT customer, rating - #{global_mean} - #{MovieBias.table_name}.bias AS bias FROM ratings
								JOIN #{MovieBias.table_name} ON ratings.movie = #{MovieBias.table_name}.id
								WHERE customer BETWEEN #{min} AND #{max}
								) as t1
							group by customer"
							
						puts sql
		
						data = conn.select_all(sql)
						
						CustomerBias.import([:id, :bias, :rating_count], data.rows, :validate => false)
					end
				end
			end
			
			puts 'joining'
			pool.shutdown
			puts 'joined'
		end
	
		def train_do
			refine_movie_bias
			refine_customer_bias
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
			
			
			puts 'calculating global stats'
			globalCount = Rating.count
			globalSum = Rating.sum('rating')
			
			# globalCount = 99072112
			# globalSum = 356986963
			
			globalMean = globalSum / globalCount.to_f
			
			GlobalStats.create(mean: globalMean, count: globalCount)
			
			puts 'initializing movie bias'
			movies = Rating.distinct.order(:movie).pluck(:movie)
			
			values = []
			movies.each do |mov|
				values << [mov, 0, 0]
			end
			
			MovieBias.import( [:id, :bias, :rating_count], values, :validate => false)
			
			puts 'initializing customer bias'
			customers = Rating.distinct.order(:customer).pluck(:customer)
			
			values = []
			customers.each do |cust|
				values << [cust, 0, 0]
			end
			
			CustomerBias.import( [:id, :bias, :rating_count], values, :validate => false)
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