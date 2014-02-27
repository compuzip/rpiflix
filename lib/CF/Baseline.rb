require 'thread/pool'

module CF
	class Baseline < Base
		class CustomerAvg < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
	
		def train_do
			reset_do
			
			CustomerAvg.connection.create_table(CustomerAvg.table_name) do |t|
				t.float 	:rating_avg
				t.integer	:rating_count
			end
			
			puts 'running large group...'
			res = Rating.group(:customer).pluck(:customer, 'COUNT(*)', 'SUM(rating)')
			puts 'done'
			
			customers = Rating.distinct.pluck(:customer)

			custCount = customers.size
			custMax = customers.max
			
			puts 'custCount: ' + custCount.to_s
			puts 'custMax: ' + custMax.to_s
			
			pool = Thread.pool(10)
			
			customers.each_slice(10000) do |task_slice|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						data = {}
						# task_slice.each_slice(1000) do |db_slice|
							r3 = Rating.where(customer: task_slice).group(:customer).pluck(:customer, 'COUNT(*)', 'SUM(rating)')
							r3.each do |r|
								data[r[0]] = [r[1], r[2] / (1.0 * r[1])]
							end
						# end
					
						conn.transaction do
							data.each do |k, v|
								CustomerAvg.create({ :id => k, :rating_count => v[0], :rating_avg => v[1]})
							end	
						end
					end
					
					puts task_slice[-1]
					progress(task_slice[-1] / (1.0 * custMax))
				end
			end
			
			puts 'joining...'
			pool.shutdown			
			puts 'joined'
			
			puts CustomerAvg.count
		end
		
		def reset_do
			connection = CustomerAvg.connection
			table = CustomerAvg.table_name
			connection.drop_table table if connection.table_exists?(table)
		end
		
		def rate(movie, customer, date)
			# custAvg = Rating.where(customer: customer).average('rating')
			# movieAvg = Rating.where(movie: movie).average('rating')
			
			custAvg = CustomerAvg.find(customer).avg
			movieAvg = Movie.find(movie).ratingAvg
			
			return (custAvg + movieAvg) / 2.0
		end
	end
end