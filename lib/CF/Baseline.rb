module CF
	class Baseline < Base
		class CustomerAvg < ActiveRecord::Base
			self.table_name_prefix = 'baseline_'
		end
	
		def train_do
			reset_do
			
			connection = CustomerAvg.connection
			
			connection.create_table(CustomerAvg.table_name) do |t|
				t.float :avg
				t.integer :count
			end
			
			# res = Rating.group(:customer).pluck('COUNT(*)', 'SUM(rating)')
			
			customers = Rating.distinct.pluck(:customer)
			data = []
			
			idx = 0
			custCount = customers.size
			
			puts 'custCount: ' + custCount.to_s
			
			customers.each do |c|
				ratings = Rating.where(customer: c).pluck(:rating)
				
				count = ratings.size
				avg = ratings.reduce(:+) / (1.0 * count)
				data.push [count, avg]
				
				idx += 1
				progress(idx / (1.0 * custCount))
			end
			
			idx = 0
			
			connection.transaction do
				customers.each do |c|
					CustomerAvg.create({ :id => c, :count => data[idx][0], :avg => data[idx][1]})
					idx += 1
				end
			end
			
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