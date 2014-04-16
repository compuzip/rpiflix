# require 'matrix'

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
	
		def refine_customers ids
			ActiveRecord::Base.connection_pool.with_connection do |conn|
				# ids.each do |c|
					sql = "
						update svd_customer_features
						set feat1 = svd_customer_features.feat1 + adj1
						, feat2 = svd_customer_features.feat2 + adj2
						, feat3 = svd_customer_features.feat3 + adj3
						, feat4 = svd_customer_features.feat4 + adj4
						, feat5 = svd_customer_features.feat5 + adj5

						from 
						(	select pred_cust
							, avg(0.001 * err * feat1) as adj1
							, avg(0.001 * err * feat2) as adj2
							, avg(0.001 * err * feat3) as adj3
							, avg(0.001 * err * feat4) as adj4
							, avg(0.001 * err * feat5) as adj5
							from
							(	select rating - pred as err, mout.id as mid, pred_movie, pred_cust

								FROM svd_movie_features mout
							
								left join 
								lateral (select svd_movie_features.feat1 * svd_customer_features.feat1
									+ svd_movie_features.feat2 * svd_customer_features.feat2
									+ svd_movie_features.feat3 * svd_customer_features.feat3
									+ svd_movie_features.feat4 * svd_customer_features.feat4
									+ svd_movie_features.feat5 * svd_customer_features.feat5 as pred
									, svd_movie_features.id as pred_movie
									, svd_customer_features.id as pred_cust
									, ratings.rating

									from svd_movie_features 
									cross join svd_customer_features
									left join ratings on ratings.movie = svd_movie_features.id and ratings.customer = svd_customer_features.id

									where svd_movie_features.id = mout.id
									and svd_customer_features.id in (select distinct customer from ratings where movie = mout.id)
								) p on mout.id = p.pred_movie
								where mout.id BETWEEN 1 and 20
							) p2
							left join svd_customer_features on p2.pred_cust = svd_customer_features.id

							group by p2.pred_cust
						) p3

						 where svd_customer_features.id = pred_cust
						 "
					
					conn.execute sql
				# end
			end
		end
	
		def refine_movies ids
			ActiveRecord::Base.connection_pool.with_connection do |conn|
				# ids.each do |m|
					sql = "update svd_movie_features
						set feat1 = svd_movie_features.feat1 + adj1
						, feat2 = svd_movie_features.feat2 + adj2
						, feat3 = svd_movie_features.feat3 + adj3
						, feat4 = svd_movie_features.feat4 + adj4
						, feat5 = svd_movie_features.feat5 + adj5

						from 
						(	select pred_movie
							, avg(0.001 * err * feat1) as adj1
							, avg(0.001 * err * feat2) as adj2
							, avg(0.001 * err * feat3) as adj3
							, avg(0.001 * err * feat4) as adj4
							, avg(0.001 * err * feat5) as adj5
							from
							(	select rating - pred as err, mout.id as mid, pred_movie, pred_cust

								FROM svd_movie_features mout
							
								left join 
								lateral (select svd_movie_features.feat1 * svd_customer_features.feat1
									+ svd_movie_features.feat2 * svd_customer_features.feat2
									+ svd_movie_features.feat3 * svd_customer_features.feat3
									+ svd_movie_features.feat4 * svd_customer_features.feat4
									+ svd_movie_features.feat5 * svd_customer_features.feat5 as pred
									, svd_movie_features.id as pred_movie
									, svd_customer_features.id as pred_cust
									, ratings.rating

									from svd_movie_features 
									cross join svd_customer_features
									left join ratings on ratings.movie = svd_movie_features.id and ratings.customer = svd_customer_features.id

									where svd_movie_features.id = mout.id
									and svd_customer_features.id in (select distinct customer from ratings where movie = mout.id)
								) p on mout.id = p.pred_movie
								
								where mout.id BETWEEN 1 and 20
							) p2
							left join svd_customer_features on p2.pred_cust = svd_customer_features.id

							group by p2.pred_movie
						) p3


						 where svd_movie_features.id = pred_movie
						"
					conn.execute sql
				# end
			end
		end
	
		def pred_single(mf, cf)
			pred = 0.0
			FEATURE_RANGE.each do |f|
				pred += mf[f] * cf[f]
			end
			
			pred
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
				
				# mf[f] += LRATE * (err * ctemp - KREG * mtemp)
				# cf[f] += LRATE * (err * mtemp - KREG * ctemp)
				
				mf[f] += LRATE * (err * ctemp)
				cf[f] += LRATE * (err * mtemp)
			end
			
			err ** 2
		end
	
		def train_do
			ratings = Rating.where(:movie => 1..30).pluck(:movie, :customer, :rating)
			# records = Rating.where(:movie => 1..3)
			
			puts 'records: ' + ratings.size.to_s
		
			# movie_ids = ratings.map{|r| r[0]}.uniq
			# cust_ids = ratings.map{|r| r[1]}.uniq
		
			# puts cust_ids.to_s


			# refine_movies movie_ids
			# refine_customers cust_ids
		
		
			m_feat = MovieFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
			c_feat = CustomerFeature.order(:id).pluck(:id, *FEATURE_COLUMNS)
			
			# cust id -> position lookup; to avoid custID searches
			cust_map = Array.new(c_feat.last[0] + 1)
			c_feat.each_index{|i| cust_map[c_feat[i][0]] = i}
			
			
			jSVD = org.rpiflix.svd.SVD.new(FEATURES, ratings.size, m_feat.size, c_feat.size, c_feat.last[0], LRATE, KREG)
			
			
			r0 = ratings.map{|r| r[0]}
			r1 = ratings.map{|r| r[1]}
			r2 = ratings.map{|r| r[2]}
			
			jSVD.setRatings(r0, r1, r2)
			
			jSVD.setMovieFeatures(m_feat)
			jSVD.setCustomerFeatures(c_feat)
			
			jSVD.setCustomerMap(cust_map)
			
			sseJ = jSVD.calcSSE
			puts 'sseJ: ' + sseJ.to_s
			
			sseR = 0.0
			ratings.each do |r|
				mf = m_feat[r[0] - 1]
				cf = c_feat[cust_map[r[1]]]
				sseR += (r[2] - pred_single(mf, cf)) ** 2
			end
			
			puts 'sseR: ' + sseR.to_s
			
			# r = ratings.first
			# mf = m_feat[r[0] - 1]
			# if mf[0] != r[0]
				# raise "unexpected movie id: #{mf[0]} vs. #{r[0]}"
			# end

			# cf = c_feat[cust_map[r[1]]]
			# if cf[0] != r[1]
				# raise "unexpected customer id: #{cf[0]} vs. #{r[1]}"
			# end
			
			# predR = pred_single(mf, cf)
			# puts 'predR: ' + predR.to_s
			
			# predJ = jSVD.calcPred(r[0], r[1])
			# puts 'predJ: ' + predJ.to_s
			
			
			10.times do 
				tsse = jSVD.train
				puts 'tsse: ' + tsse.to_s
			end
			
			
			
			# m_mat = Matrix.build(m_feat.size, FEATURES) do |row, col|
				# m_feat[row][col + 1]
			# end
			
			# c_mat = Matrix.build(c_feat.size, FEATURES) do |row, col|
				# c_feat[row][col + 1]
			# end
			
			# sumprod = FEATURE_COLUMNS.map{|f| MovieFeature.table_name + '.' + f + ' * ' + CustomerFeature.table_name + '.' + f}.join(' + ')		
			
			# sql = "SELECT movie, customer, #{sumprod} AS pred FROM #{Rating.table_name}
				# JOIN #{MovieFeature.table_name} on #{Rating.table_name}.movie = #{MovieFeature.table_name}.id
				# JOIN #{CustomerFeature.table_name} on #{Rating.table_name}.customer = #{CustomerFeature.table_name}.id
				# WHERE movie < 20"
				
				# -- where movie=1
				# ( SELECT movie, rating - #{global_mean} - #{CustomerBias.table_name}.bias AS bias FROM ratings
					# JOIN #{CustomerBias.table_name} ON ratings.customer = #{CustomerBias.table_name}.id
					# WHERE movie BETWEEN #{min} AND #{max}
					# ) as t1
				# group by movie"
				
				
				
				# select *, rating - pred as err
				# from (select svd_movie_features.feat1 * svd_customer_features.feat1
				# + svd_movie_features.feat2 * svd_customer_features.feat2
				# + svd_movie_features.feat3 * svd_customer_features.feat3
				# + svd_movie_features.feat4 * svd_customer_features.feat4
				# + svd_movie_features.feat5 * svd_customer_features.feat5 as pred
				# , svd_movie_features.id as pred_movie
				# , svd_customer_features.id as pred_cust
				# , ratings.rating

				# from svd_movie_features 
				# cross join svd_customer_features
				# left join ratings on ratings.movie = svd_movie_features.id and ratings.customer = svd_customer_features.id
				# ) p

				# where p.pred_movie = 1
				# and p.pred_cust in (select customer from ratings where movie=1)
			
			# puts sql
			
			
			# records = Rating.order(:movie).first(10000)
			# records = Rating.order(:movie).first(20)
			# ratings = Rating.where(:movie => 1..199).pluck(:movie, :customer, :rating)
			
		
			# raise 'err'
		
			(1..10).each do
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
					
					# mf[FEATURES + 1] = true
					# cf[FEATURES + 1] = true
				end
				
				puts "training SSE: #{sse}"
			end
			
			
			raise 'errr2'
			
			m_feat = m_feat.select{|m| m[FEATURES + 1]}.map{|f| f.slice 0..FEATURES}
			c_feat = c_feat.select{|c| c[FEATURES + 1]}.map{|f| f.slice 0..FEATURES}
			
			puts m_feat.to_s
			
			raise 'err'
			
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














# update svd_movie_features
# set feat1 = svd_movie_features.feat1 + adj1
# , feat2 = svd_movie_features.feat1 + adj2
# , feat3 = svd_movie_features.feat1 + adj3
# , feat4 = svd_movie_features.feat1 + adj4
# , feat5 = svd_movie_features.feat1 + adj5

# from 
# (	select *, err
	# , 0.001 * err * feat1 as adj1
	# , 0.001 * err * feat2 as adj2
	# , 0.001 * err * feat3 as adj3
	# , 0.001 * err * feat4 as adj4
	# , 0.001 * err * feat5 as adj5
	# from
	# (	select rating - pred as err, pred_movie, pred_cust
		# from (select svd_movie_features.feat1 * svd_customer_features.feat1
		# + svd_movie_features.feat2 * svd_customer_features.feat2
		# + svd_movie_features.feat3 * svd_customer_features.feat3
		# + svd_movie_features.feat4 * svd_customer_features.feat4
		# + svd_movie_features.feat5 * svd_customer_features.feat5 as pred
		# , svd_movie_features.id as pred_movie
		# , svd_customer_features.id as pred_cust
		# , ratings.rating

		# from svd_movie_features 
		# cross join svd_customer_features
		# left join ratings on ratings.movie = svd_movie_features.id and ratings.customer = svd_customer_features.id
		# ) p
	# ) p2
	# left join svd_customer_features on p2.pred_cust = svd_customer_features.id

	# where p2.pred_movie = 1
	# and p2.pred_cust in (915, 2442, 3321)
# ) p3
# where svd_movie_features.id = 1



# -- and p2.pred_cust in (select customer from ratings where movie=1)