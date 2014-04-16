# class Array
  # def bindex element, lower = 0, upper = length - 1
    # while upper >= lower
      # mid = (upper + lower) / 2
      # if self[mid] < element
        # lower = mid + 1
      # elsif self[mid] > element
        # upper = mid - 1
      # else
        # return mid
      # end
    # end

    # return nil
  # end
# end

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
	
		def train_single(mf, cf, rating)
			pred = 0.0
			FEATURE_RANGE.each do |f|
				pred += mf[f] * cf[f]
			end
			
			err = rating - pred
			
			# puts err

			FEATURE_RANGE.each do |f|
				mtemp = mf[f]
				ctemp = cf[f]
				
				# puts "mtemp: #{mtemp}, ctemp: #{ctemp}"
				
				mf[f] += LRATE * (err * ctemp - KREG * mtemp)
				cf[f] += LRATE * (err * mtemp - KREG * ctemp)
			end
			
			err ** 2
		end
	
		def train_do
			m_feat = MovieFeature.order(:id).pluck(:id, *FEATURE_COLUMNS, 'false')
			c_feat = CustomerFeature.order(:id).pluck(:id, *FEATURE_COLUMNS, 'false')
			
			# cust id -> position lookup; to avoid custID searches
			cust_map = Array.new(c_feat.last[0])
			c_feat.each_index{|i| cust_map[c_feat[i][0]] = i}
			
			
			
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
			
			
			# records = Rating.order(:movie).first(10000)
			# records = Rating.order(:movie).first(20)
			ratings = Rating.where(:movie => 1..199).pluck(:movie, :customer, :rating)
			# records = Rating.where(:movie => 1..3)
			
			puts 'records: ' + ratings.size.to_s
		
			(1..500).each do
				sse = 0.0
				
				ratings.each do |r|				
					# movie ids are consecutive
					mf = m_feat[r[0] - 1]
					if mf[0] != r[0]
						raise "unexpected movie id: #{mf[0]} vs. #{r[0]}"
					end
					
					# customer ids not consecutive, need to search
					# cf = c_feat.bsearch{|e| r[1] <=> e[0]}
					cf = c_feat[cust_map[r[1]]]
					if cf[0] != r[1]
						raise "unexpected customer id: #{cf[0]} vs. #{r[1]}"
					end
				
					sse += train_single(mf, cf, r[2])
					
					mf[FEATURES + 1] = true
					cf[FEATURES + 1] = true
				end
				
				puts "training SSE: #{sse}"
			end
			
			m_feat = m_feat.select{|m| m[FEATURES + 1]}.map{|f| f.slice 0..FEATURES}
			c_feat = c_feat.select{|c| c[FEATURES + 1]}.map{|f| f.slice 0..FEATURES}
			
			MovieFeature.delete(m_feat.map{|f| f[0]})
			MovieFeature.import([:id] + FEATURE_COLUMNS, m_feat, :validate => false)
			
			CustomerFeature.delete(c_feat.map{|f| f[0]})
			CustomerFeature.import([:id] + FEATURE_COLUMNS, c_feat, :validate => false)
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