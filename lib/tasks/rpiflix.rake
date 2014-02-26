namespace :rpiflix do
	desc "TODO"
	task populateMovies: :environment do
		prizeDatasetDir = "./db/nf_prize_dataset"
		
		ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
		connection = ActiveRecord::Base.connection

		puts 'table exists?: ' + connection.table_exists?('movies').to_s
		if connection.table_exists?('movies')
			puts 'old records: ' + Movie.count.to_s
		end
		
		connection.drop_table 'movies' if connection.table_exists?('movies')	
		
		connection.create_table('movies') do |t|
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
				connection.exec_query stmt
			end
		end
		
		# connection.exec_query "SHUTDOWN"
	end

	desc "TODO"
	task populateRatings: :environment do
		prizeDatasetDir = "./db/nf_prize_dataset"
		
		# ActiveRecord::Base.logger = Logger.new(STDOUT)
		
		ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
		connection = ActiveRecord::Base.connection
		
		connection.drop_table 'ratings' if connection.table_exists?('ratings')
		connection.drop_table 'probes' if connection.table_exists?('probes')
		
		connection.exec_query "create table ratings (movie SMALLINT NOT NULL, customer INTEGER NOT NULL, rating TINYINT NOT NULL, date DATE NOT NULL)"
		connection.exec_query "create table probes (movie SMALLINT NOT NULL, customer INTEGER NOT NULL, rating TINYINT NOT NULL, date DATE NOT NULL)"
		
		# connection.add_index(:ratings, :movie)
		# connection.add_index(:ratings, :customer)
		
		# connection.add_index(:probes, :movie)
		# connection.add_index(:probes, :customer)
		
		puts "loading probe list..."
		probes = Set.new
		File.open(prizeDatasetDir + '/probe.txt') do |f|
			while line = f.gets
				if line.strip.end_with?(':')
					movie = line.strip.delete(':')
				else
					customer = line.strip
					probes.add movie + "_" + customer
				end
			end
		end
		
		puts "parsing training set..."
		
		insThread = nil;
		
		# iterate over all files, in chunks
		Dir.glob(prizeDatasetDir + "/training_set/mv*.txt").each_slice(500) do |mv_slice|
			ratingInserts = []
			probeInserts = []
			mv_slice.each do |mv|
				puts mv

				File.open(mv) do |f|
					movieID = f.gets.delete(":").strip

					while line = f.gets
						split = line.strip.split(',',3)
						(probes.include?(movieID + "_" + split[0]) ? probeInserts : ratingInserts).push "(#{movieID}, #{split[0]}, #{split[1]}, '#{split[2]}')"
					end
				end
			end

			if not insThread.nil?
				puts 'waiting for db...'
				insThread.join
			end
			
			insThread = Thread.new {
				ActiveRecord::Base.connection_pool.with_connection do
					ActiveRecord::Base.transaction do
						ratingInserts.each_slice(500) do |s|
							connection.exec_query "INSERT INTO ratings(movie, customer, rating, date) VALUES #{s.join(", ")}"
						end
						
						probeInserts.each_slice(500) do |s|
							connection.exec_query "INSERT INTO probes(movie, customer, rating, date) VALUES #{s.join(", ")}"
						end
					end
				end
			}
		end

		insThread.join unless insThread.nil?
		
		puts 'creating indices...'
		
		threads = []
		
		[:probes, :ratings].each do |t|
			[:movie, :customer].each do |c|
				threads << Thread.new { 
					ActiveRecord::Base.connection_pool.with_connection do
						puts 'adding index on ' + t.to_s + '(' + c.to_s + ')'
						connection.add_index(t, c)
						puts 'done with index on ' + t.to_s + '(' + c.to_s + ')'
					end
				}
			end
		end
		
		threads.each { |t| t.join }
		
		puts 'populated ' + Probe.count.to_s + ' probes'
		puts 'populated ' + Rating.count.to_s + ' ratings'
		
		connection.exec_query "SHUTDOWN"
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
		
		connection.drop_table 'models' if connection.table_exists?('models')
		
		connection.create_table('models') do |t|
			t.string	:klass
			t.string	:state, 	default: 'new'
			t.float		:progress,	default: 0.0
			t.time		:updated_at
		end
		
		Dir[File.join(Rails.root, "/lib/CF/*.rb")].each do |f|
			name = File.basename(f, ".rb")
			if name != "Base"
				Model.create(:klass => name)
			end
		end
		
		puts 'populated ' + Model.count.to_s + ' models'
	end
end
