require 'thread/channel'
require 'thread/pool'

module CF
	class Baseline < Base
		class CustomerAvg < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
	
		def train_do
			reset_do
			
			connection = CustomerAvg.connection
			
			connection.create_table(CustomerAvg.table_name) do |t|
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
			channel = Thread.channel
			
			customers.each_slice(1000) do |task_slice|
				pool.process do
					data = {}
					ActiveRecord::Base.connection_pool.with_connection do
						task_slice.each_slice(20) do |db_slice|
							r3 = Rating.where(customer: db_slice).group(:customer).pluck(:customer, 'COUNT(*)', 'SUM(rating)')
							r3.each do |r|
								data[r[0]] = [r[1], r[2]]
							end
							
							# ratings = Rating.where(customer: db_slice).pluck(:customer, :rating)
							# ratings2 = ratings.group_by{ |r| r[0] }
							
							# db_slice.each do |c|
								# rat = ratings.select{|r| r[0] == c}.map{|r| r[1]}
								# rat = ratings2[c].map{|r| r[1]}
								# rat = Rating.where(customer: c).pluck(:rating)
								# count = rat.size
								# avg = rat.reduce(:+) / (1.0 * count)
								# data[c] = [count, avg]
							# end
						end
					end
					puts task_slice[-1]
					progress(task_slice[-1] / (1.0 * custMax))
					channel.send(data)
				end
			end
			
			# customers.each do |c|
				# pool.process do
					# ActiveRecord::Base.connection_pool.with_connection do
						# ratings = Rating.where(customer: c).pluck(:rating)
						# puts c
						# count = ratings.size
						# avg = ratings.reduce(:+) / (1.0 * count)
						# data.push [count, avg]
					# end
				# end
				# ratings = Rating.where(customer: c).pluck(:rating)
				
				# count = ratings.size
				# avg = ratings.reduce(:+) / (1.0 * count)
				# data.push [count, avg]
				
				# idx += 1
				# progress(idx / (1.0 * custCount))
			# end
			
			puts 'joining...'
			pool.shutdown
			
			puts 'joined'
			
			while data = channel.receive!
				connection.transaction do
					data.each do |k, v|
						CustomerAvg.create({ :id => k, :rating_count => v[0], :rating_avg => v[1]})
					end
				end
			end
			
			# idx = 0
			
			# connection.transaction do
				# customers.each do |c|
					# CustomerAvg.create({ :id => c, :count => data[idx][0], :avg => data[idx][1]})
					# idx += 1
				# end
			# end
			
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