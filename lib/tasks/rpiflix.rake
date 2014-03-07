require 'thread/pool'

namespace :rpiflix do
	desc "TODO"
	task populateMovies: :environment do
		prizeDatasetDir = "./db/nf_prize_dataset"
		
		connection = ActiveRecord::Base.connection
		
		connection.create_table('movies', force: true) do |t|
			t.integer	:year
			t.string	:title
			t.integer	:tmdbid
			t.string	:tmdbposter
			t.integer	:rating_count
			t.float		:rating_avg
		end

		puts 'populating movies table...'	
		inserts = []

		File.open(prizeDatasetDir + '/movie_titles.txt') do |f|
			while line = f.gets
				line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
				split = line.strip.split(',',3)
				inserts.push "(#{split[0]}, #{split[1]}, #{connection.quote(split[2])})"
			end
		end
		
		puts "adding " + inserts.size.to_s + " entries"
		
		ActiveRecord::Base.transaction do
			inserts.each_slice(500) do |s|
				stmt = "INSERT INTO movies(id, year, title) VALUES #{s.join(", ")}"
				connection.execute stmt
			end
		end
	end

	desc "TODO"
	task populateRatings: :environment do
		prizeDatasetDir = "./db/nf_prize_dataset"
		
		# ActiveRecord::Base.logger = Logger.new(STDOUT)
		ActiveRecord::Base.logger.level = Logger::INFO
		
		connection = ActiveRecord::Base.connection
		
		['ratings', 'probes'].each do |t|
			connection.drop_table t if connection.table_exists?(t)
			connection.execute "create table #{t} 
				(movie SMALLINT NOT NULL, 
				customer INTEGER NOT NULL, 
				rating SMALLINT NOT NULL, 
				date DATE NOT NULL
				)"
		end
		
		puts "loading probe list..."
		probes = Set.new
		File.open(prizeDatasetDir + '/probe.txt') do |f|
			while line = f.gets
				if line.strip.end_with?(':')
					movie = line.strip.delete(':')
				else
					customer = line.strip
					probes.add movie + '_' + customer
				end
			end
		end
		
		puts "parsing training set..."
				
		pool = Thread.pool(10)
		
		# iterate over all files, in chunks
		Dir.glob(prizeDatasetDir + "/training_set/mv*.txt").each_slice(200) do |mv_slice|
			ratingInserts = []
			probeInserts = []
			mv_slice.each do |mv|
				puts mv

				File.open(mv) do |f|
					movieID = f.gets.delete(":").strip

					while line = f.gets
						split = line.strip.split(',',3)
						(probes.include?(movieID + '_' + split[0]) ? probeInserts : ratingInserts).push "(#{movieID}, #{split[0]}, #{split[1]}, '#{split[2]}')"
					end
				end
			end

			pool.process do			
				ActiveRecord::Base.connection_pool.with_connection do |conn|
					conn.transaction do
						ratingInserts.each_slice(500) do |s|
							conn.execute "INSERT INTO ratings(movie, customer, rating, date) VALUES #{s.join(", ")}"
						end
					end
				end
			end
			
			pool.process do
				ActiveRecord::Base.connection_pool.with_connection do |conn|
					conn.transaction do
						probeInserts.each_slice(500) do |s|
							conn.execute "INSERT INTO probes(movie, customer, rating, date) VALUES #{s.join(", ")}"
						end
					end
				end
			end
		end

		puts 'waiting for db...'		
		pool.wait_done

		puts 'creating indices...'		
		[:probes, :ratings].each do |t|
			[:movie, :customer].each do |c|
				pool.process do
					ActiveRecord::Base.connection_pool.with_connection do |conn|
						puts 'adding index on ' + t.to_s + '(' + c.to_s + ')'
						conn.add_index(t, c)
						puts 'done with index on ' + t.to_s + '(' + c.to_s + ')'
					end
				end
			end
		end
		
		pool.shutdown
		
		puts 'populated ' + Probe.count.to_s + ' probes'
		puts 'populated ' + Rating.count.to_s + ' ratings'
	end
	
	desc "TODO"
	task calculateStats: :environment do
		ActiveRecord::Base.transaction do
			Movie.all.each do |m|
				puts m.id.to_s + ": " + m.title
				# puts m.attributes
				m.rating_count = Rating.where(movie: m.id).count
				m.rating_avg = m.rating_count > 0 ? Rating.where(movie: m.id).average('rating') : 0.0
				m.save
			end
		end
	end
	
	desc "TODO"
	task populateModels: :environment do
		ActiveRecord::Base.logger = Logger.new(STDOUT)
		
		connection = ActiveRecord::Base.connection
		
		connection.create_table('models', force: true) do |t|
			t.string	:klass,						null: false
			t.string	:state, 	default: 'new',	null: false
			t.text		:message
			t.float		:progress,	default: 0.0,	null: false
			t.float		:rmse,		default: 0.0,	null: false
			t.timestamps
		end
		
		Dir[File.join(Rails.root, "/lib/CF/*.rb")].each do |f|
			name = File.basename(f, ".rb")
			if name != "Base"
				Model.create(:klass => name)
			end
		end
		
		puts 'populated ' + Model.count.to_s + ' models'
		
		connection.create_table('predictions', id: false, force: true) do |t|
			t.column :model, :smallint, null: false,	index: true
			t.column :movie, :smallint, null: false, 	index: true
			t.integer	:customer,		null: false,	index: true
			t.float		:prediction,	null: false
		end
	end
end
