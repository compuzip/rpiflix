require 'java'
require 'lib/java/SVD.jar'

module CF

	# based on http://sifter.org/~simon/Journal/20061211.html
	class SVD < Base
		FEATURES = 5
		FEATURE_COLUMNS = (1..FEATURES).map {|f| "feat#{f}"}
		FEATURE_RANGE = Range.new(1, FEATURES)
		LRATE = 0.001
		# LRATE = 0.01
		# KREG = 0.02
		KREG = 0.0
	
		class MovieFeature < ActiveRecord::Base
			self.table_name_prefix = 'svd_'
		end
		
		class CustomerFeature < ActiveRecord::Base
			self.table_name_prefix = 'svd_'
		end
	
		def pred_single(mf, cf)
			pred = 0.0
			FEATURE_RANGE.each do |f|
				pred += mf[f] * cf[f]
			end
			
			pred
		end
	
		def train_do
			rating_count = Rating.count
			puts 'records: ' + rating_count.to_s
		
			m_feat = MovieFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
			c_feat = CustomerFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
			
			jSVD = org.rpiflix.svd.SVD.new(FEATURES, rating_count, m_feat.size, c_feat.size, c_feat.last[0], LRATE, KREG)		
						
			puts 'min: ' + jSVD.minRating.to_s
			puts 'max: ' + jSVD.maxRating.to_s
			
			offset = 0
			m_feat.map{|f| f[0]}.each_slice(200) do |s|
				# ratings = Rating.where(:movie => s).pluck(:movie, :customer, :rating)
				
				range = Range.new(s.min, s.max)
				
				r0 = Rating.order(:movie, :customer).where(:movie => range).pluck(:movie)
				r1 = Rating.order(:movie, :customer).where(:movie => range).pluck(:customer)
				r2 = Rating.order(:movie, :customer).where(:movie => range).pluck(:rating)
				
				# jSVD.setRatings(offset, ratings.map{|r| r[0]}, ratings.map{|r| r[1]}, ratings.map{|r| r[2]})
				jSVD.setRatings(offset, r0, r1, r2)
				offset += r0.size
			end
			
			puts 'min: ' + jSVD.minRating.to_s
			puts 'max: ' + jSVD.maxRating.to_s
						
			jSVD.setMovieFeatures(m_feat)
			jSVD.setCustomerFeatures(c_feat)
			
			jSVD.setCustomerMap(make_customer_map(c_feat))
			
			100.times do 
				t_rmse = jSVD.train
				puts 'train rmse: ' + t_rmse.to_s
			end
			
			m_feat2 = jSVD.getMovieFeatures.to_a
			m_changed = jSVD.getChangedMovies.to_a

			c_feat2 = jSVD.getCustomerFeatures.to_a
			c_changed = jSVD.getChangedCustomers.to_a
			
			m_update = []
			m_feat.each_index do |i|
				if m_changed[i]
					m_update << [m_feat[i][0], *m_feat2[i]]
				end
			end
			
			c_update = []
			c_feat.each_index do |i|
				if c_changed[i]
					c_update << [c_feat[i][0], *c_feat2[i]]
				end
			end
			
			
			MovieFeature.delete(m_update.map{|f| f[0]})
			MovieFeature.import([:id] + FEATURE_COLUMNS, m_update, :validate => false)
			
			CustomerFeature.delete(c_update.map{|f| f[0]})
			CustomerFeature.import([:id] + FEATURE_COLUMNS, c_update, :validate => false)
		end
		
		def reset_do
			MovieFeature.connection.create_table(MovieFeature.table_name, force: true) do |t|
				FEATURE_COLUMNS.each do |f|				
					t.float		f
				end
			end
			
			CustomerFeature.connection.create_table(CustomerFeature.table_name, force: true) do |t|
				FEATURE_COLUMNS.each do |f|				
					t.float 	f
				end
			end

			# initialize feature vectors
			starting = Range.new(1, FEATURES).map{|f| 1.0 / f}
			
			puts 'initializing movie features'
			movies = Rating.distinct.order(:movie).pluck(:movie)
			values = movies.map{|m| [m] + starting}
			MovieFeature.import( [:id] + FEATURE_COLUMNS, values, :validate => false)
			
			puts 'initializing customer features'
			customers = Rating.distinct.order(:customer).pluck(:customer)
			values = customers.map{|c| [c] + starting}
			CustomerFeature.import( [:id] + FEATURE_COLUMNS, values, :validate => false)
		end

	
		def rate(movie, customer, date)
			populate_caches
			
			mf = @cache_movies[movie - 1]
			cf = @cache_customers[@cache_customer_map[customer]]

			pred = pred_single(mf, cf)
			
			[[pred, 5].min, 1].max
		end
	
	private
		def make_customer_map cust_features
			# cust id -> position lookup; to avoid custID searches
			cust_map = Array.new(cust_features.last[0] + 1)
			cust_features.each_index{|i| cust_map[cust_features[i][0]] = i}
			
			cust_map
		end
	
		def populate_caches
			if @cache_movies.nil?
				@cache_movies = MovieFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
				@cache_customers = CustomerFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
				@cache_customer_map = make_customer_map(@cache_customers)
			end
		end
	end
end
