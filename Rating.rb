class Rating < ActiveRecord::Base
	
	def self.initDB(prizeDatasetDir)
		if not connection.table_exists?('ratings')
			connection.exec_query "create table ratings (movie int, customer int, rating int, date date, probe bool)"
			
			transaction do
				Dir.glob(prizeDatasetDir + "/training_set/mv*.txt") do |mv|
					puts mv
					
					File.open(mv) do |f|
						inserts = []
						id = f.gets.delete(":").strip
						
						while line = f.gets
							split = line.strip.split(',',3)
							inserts.push "(#{id}, #{split[0]}, #{split[1]}, '#{split[2]}', 0)"
						end
						
						inserts.each_slice(500) do |s|
							stmt = "INSERT INTO ratings(movie, customer, rating, date, probe) VALUES #{s.join(", ")}"
							connection.exec_query stmt
						end
					end
				end
			end
			
			puts "creating indices..."
			connection.exec_query "CREATE INDEX 'movies' ON 'ratings' ('movie')"
			connection.exec_query "CREATE INDEX 'customers' ON 'ratings' ('customer')"
			
			puts "marking probe entries..."
			probes = []
			
			File.open(prizeDatasetDir + '/probe.txt') do |f|
				
				movie = 0

				while line = f.gets
					if line.strip.end_with?(':')
						movie = line.strip.delete(':').to_i
						# puts movie
					else
						customer = line.strip.to_i
						probes.push "(customer = #{customer} AND movie=#{movie})"
					end
				end
			end

			# no primary key, so can't use activerecord's UPDATE
			transaction do
				probes.each_slice(500) do |s|
					stmt = "UPDATE ratings SET probe=1 WHERE #{s.join(" OR ")}"
					connection.exec_query stmt
				end
			end
			
			puts "creating probe index..."
			connection.exec_query "CREATE INDEX 'probe' ON 'ratings' ('probe')"
		end
	end
end