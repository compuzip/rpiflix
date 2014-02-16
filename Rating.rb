class Rating
	attr_reader :movie
	attr_reader :customer
	attr_reader :rating
	attr_reader :date
	
	def initialize(movie, customer, rating, date, probe)
		@movie = movie.to_i
		@customer = customer.to_i
		@rating = rating.to_i
		@date = date
		@probe = probe
	end
	
	def self.listDB(db)
		db.execute( "select * from ratings" ) do |row|
			yield new(*row)
		end
	end
	
	def self.createDB(dirName, db)
		db.execute "DROP TABLE IF EXISTS ratings"
		db.execute "create table ratings (movie int, customer int, rating int, date date, probe bool)"

		db.transaction

		stmt = db.prepare("INSERT INTO ratings(movie, customer, rating, date) VALUES (:movie, :customer, :rating, :date)")
		
		Rating.listFiles(firName) do |r|
			stmt.execute r.movie, r.customer, r.rating, r.date
		end

		db.commit
	end
	
	def self.listFiles(dirName)
		Dir.glob(dirName + "/mv*.txt") do |mv|
			puts mv
			
			File.open(mv) do |f|
				id = f.gets.delete(":").to_i
				while line = f.gets
					yield new(id, *line.strip.split(',',3))
				end
			end
		
		end
	end
	
end