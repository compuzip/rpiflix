module CF

	# based on http://sifter.org/~simon/Journal/20061211.html
	class SVD < Base
		FEATURES = 5
		FEATURE_COLUMNS = (1..FEATURES).map {|f| "feat#{f}"}
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
	
		def train_single(mf, cf, rating)
			
			pred = 0.0
			FEATURE_COLUMNS.each do |f|
				pred += mf[f] * cf[f]
			end
			
			
			err = rating.rating - pred
			
			# puts err
			
			FEATURE_COLUMNS.each do |f|
				mtemp = mf[f]
				ctemp = cf[f]
				
				# puts "mtemp: #{mtemp}, ctemp: #{ctemp}"
				
				mf[f] += LRATE * (err * mtemp - KREG * ctemp)
				cf[f] += LRATE * (err * ctemp - KREG * mtemp)
			end
			
			# mf.save
			# cf.save
			
			err ** 2
			
			# uv = userValue[user];
			# userValue[user] += err * movieValue[movie];
			# movieValue[movie] += err * uv;
	
			# userValue[user] += lrate * (err * movieValue[movie] - K * userValue[user]);
			# movieValue[movie] += lrate * (err * userValue[user] - K * movieValue[movie]);
	
	
	 # err=<double>r.rating - \
		# predict(uOffset,vOffset, dataU, dataV, factors)
# sumSqErr+=err*err;
			# for k from 0<=k<factors:
				# uTemp = dataU[uOffset+k]
				# vTemp = dataV[vOffset+k]
				# dataU[uOffset+k]+=lr*(err*vTemp-reg*uTemp)
				# dataV[vOffset+k]+=lr*(err*uTemp-reg*vTemp)
		end
	
		def train_do
			m_feat = MovieFeature.order(:id).all
			c_feat = CustomerFeature.order(:id).all
			
			
			sumprod = FEATURE_COLUMNS.map{|f| MovieFeature.table_name + '.' + f + ' * ' + CustomerFeature.table_name + '.' + f}.join(' + ')
			
			
			sql = "SELECT movie, customer, #{sumprod} AS pred FROM #{Rating.table_name}
				JOIN #{MovieFeature.table_name} on #{Rating.table_name}.movie = #{MovieFeature.table_name}.id
				JOIN #{CustomerFeature.table_name} on #{Rating.table_name}.customer = #{CustomerFeature.table_name}.id
				WHERE movie < 20"
				
				# -- where movie=1
				# ( SELECT movie, rating - #{global_mean} - #{CustomerBias.table_name}.bias AS bias FROM ratings
					# JOIN #{CustomerBias.table_name} ON ratings.customer = #{CustomerBias.table_name}.id
					# WHERE movie BETWEEN #{min} AND #{max}
					# ) as t1
				# group by movie"
			
			puts sql
			
			# aaaaaaaaaaa
			
			# records = Rating.order(:movie).first(10000)
			records = Rating.where(:movie => 1..19)
		
			(1..100).each do
				sse = 0.0
				
				records.each do |r|				
					# movie ids are consecutive
					mf = m_feat[r.movie - 1]
					if mf.id != r.movie
						raise "unexpected movie id: #{mf.id} vs. #{r.movie}"
					end
					
					# customer ids not consecutive, need to search
					cf = c_feat.bsearch {|e| r.customer <=> e.id}
					if cf.id != r.customer
						raise "unexpected customer id: #{cf.id} vs. #{r.customer}"
					end
				
					sse += train_single(mf, cf, r)
				end
				
				# changed = m_feat.map{|m| m.changed?}
				# puts changed.to_s
				
				puts "training SSE: #{sse}"
			end

			m_feat = m_feat.select{|m| m.changed?}
			c_feat = c_feat.select{|c| c.changed?}
			
			ActiveRecord::Base.transaction do
				m_feat.each do |m|
					m.save
				end
				
				c_feat.each do |c|
					c.save
				end
			end
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

			# initialize random feature vectors
			zeros = Range.new(1, FEATURES).map{|f| 1.0 / f}
			
			puts 'initializing movie features'
			movies = Rating.distinct.order(:movie).pluck(:movie)
			# values = movies.map{|m| [m] + Array.new(FEATURES) {rand(0.5)}}
			values = movies.map{|m| [m] + zeros}
			MovieFeature.import( [:id] + FEATURE_COLUMNS, values, :validate => false)
			
			puts 'initializing customer features'
			customers = Rating.distinct.order(:customer).pluck(:customer)
			# values = customers.map{|c| [c] + Array.new(FEATURES) {rand(0.5)}}
			values = customers.map{|c| [c] + zeros}
			CustomerFeature.import( [:id] + FEATURE_COLUMNS, values, :validate => false)
		end
	
		# def pred(movie, customer)
			# mf = MovieFeatures.find(movie)
			# cf = CustomerFeatures.find(customer)
			
			# sum = 0.0
			# FEATURE_COLUMNS.each do |f|
				# sum += mf[c] * cf[c]
			# end
			
			# return sum
		# end
	
		def rate(movie, customer, date)
			
			# pred = @cache_global_mean + @cache_customer[customer] + @cache_movie[movie]
			
			# [[pred, 5].min, 1].max
		end
	
	end
end