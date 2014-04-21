require 'thread/pool'

require 'java'
require 'lib/java/SVD.jar'

module CF

	# based on http://sifter.org/~simon/Journal/20061211.html
	class SVD < Base
		FEATURES = 20
		FEATURE_COLUMNS = (1..FEATURES).map {|f| "feat#{f}"}
		FEATURE_RANGE = Range.new(1, FEATURES)
		LRATE = 0.001
		KREG = 0.02
		# KREG = 0.0
	
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
			
			pool = Thread.pool(3)
			
			offset = 0
			m_feat.map{|f| f[0]}.each_slice(200) do |s|
				# ratings = Rating.where(:movie => s).pluck(:movie, :customer, :rating)
				
				range = Range.new(s.min, s.max)
				
				r0, r1, r2 = []

				puts 'querying'
				
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do
						r0 = Rating.order(:movie, :customer).where(:movie => range).pluck(:movie).to_java(:short)
					end
					puts 'done with movie'
				end
				
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do
						r1 = Rating.order(:movie, :customer).where(:movie => range).pluck(:customer).to_java(:int)
					end
					puts 'done with customer'
				end
				
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do
						r2 = Rating.order(:movie, :customer).where(:movie => range).pluck(:rating).to_java(:byte)
					end
					puts 'done with rating'
				end
				
				puts 'waiting...'
				pool.wait_done
				
				puts 'calling java'
				
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
			c_feat2 = jSVD.getCustomerFeatures.to_a
			
			m_update = []
			m_feat.each_index do |i|
				m_update << [m_feat[i][0], *m_feat2[i]]
			end
			
			MovieFeature.delete(m_update.map{|f| f[0]})
			MovieFeature.import([:id] + FEATURE_COLUMNS, m_update, :validate => false)
			
			
			c_update = []
			c_feat.each_index do |i|
				c_update << [c_feat[i][0], *c_feat2[i]]
				
				if c_update.size > 10000
					CustomerFeature.delete(c_update.map{|f| f[0]})
					CustomerFeature.import([:id] + FEATURE_COLUMNS, c_update, :validate => false)	
					c_update = []
				end
			end

			if c_update.size > 0
				CustomerFeature.delete(c_update.map{|f| f[0]})
				CustomerFeature.import([:id] + FEATURE_COLUMNS, c_update, :validate => false)	
			end			
		end
		
		def reset_do
			MovieFeature.connection.create_table(MovieFeature.table_name, force: true) do |t|
				FEATURE_COLUMNS.each do |f|				
					t.float		f, null: false, default: 0.0
				end
			end
			
			CustomerFeature.connection.create_table(CustomerFeature.table_name, force: true) do |t|
				FEATURE_COLUMNS.each do |f|				
					t.float 	f, null: false, default: 0.0
				end
			end
			
			puts 'initializing movie features'
			movies = Rating.distinct.order(:movie).pluck(:movie).map{|m| [m]}
			MovieFeature.import([:id], movies, :validate => false)
			
			puts 'initializing customer features'
			customers = Rating.distinct.order(:customer).pluck(:customer).map{|c| [c]}
			CustomerFeature.import([:id], customers, :validate => false)
			
			FEATURE_COLUMNS.each_index do |i|
				val = 1.0 / (i + 1)
				MovieFeature.update_all(FEATURE_COLUMNS[i] + '=' + val.to_s + ' * RANDOM()')
				CustomerFeature.update_all(FEATURE_COLUMNS[i] + '=' + val.to_s + ' * RANDOM()')
			end
		end
	
		def rate(movie, customer, date)
			populate_caches
			
			mf = @cache_movies[movie - 1]
			cf = @cache_customers[@cache_customer_map[customer]]

			pred = pred_single(mf, cf)
			
			[[pred, 5].min, 1].max
		end
	
		def similar_movies(movie, count)
			mf = MovieFeature.find(movie)
			
			l2 = 0.0
			FEATURE_COLUMNS.each do |f|
				l2 += mf[f] * mf[f]
			end
			l2 = Math.sqrt(l2)
			
			# A.B / ( ||A|| ||B|| )
			sql_num = FEATURE_COLUMNS.map{|f| mf[f].to_s + '*' + f}.join('+')		
			sql_den = FEATURE_COLUMNS.map{|f| f + '*' + f}.join('+')
			
			sql = "SELECT id, (#{sql_num}) / (#{l2} * sqrt(#{sql_den})) as similarity 
				FROM #{MovieFeature.table_name} 
				ORDER BY similarity DESC
				LIMIT #{count}
				OFFSET 1"
			puts sql
			
			ActiveRecord::Base.connection.select_all(sql).to_a
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
