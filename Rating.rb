require 'set'

class Rating < ActiveRecord::Base

	def self.initDB(prizeDatasetDir)
		if not connection.table_exists?('ratings')
			connection.exec_query "create table ratings (movie int, customer int, rating int, date date, probe bool)"

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
			transaction do
				Dir.glob(prizeDatasetDir + "/training_set/mv*.txt") do |mv|
					puts mv

					File.open(mv) do |f|
						inserts = []
						id = f.gets.delete(":").strip

						while line = f.gets
							split = line.strip.split(',',3)
							probe = probes.include?(id + "_" + split[0]) ? :"1" : :"0"
							inserts.push "(#{id}, #{split[0]}, #{split[1]}, '#{split[2]}', #{probe})"
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
			connection.exec_query "CREATE INDEX 'probe' ON 'ratings' ('probe')"
		end
	end
end