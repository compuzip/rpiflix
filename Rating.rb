class Rating < ActiveRecord::Base
	
	def self.initDB(dirName)
		if not connection.table_exists?('ratings')
			connection.exec_query "create table ratings (movie int, customer int, rating int, date date, probe bool)"
			
			transaction do
				Dir.glob(dirName + "/mv*.txt") do |mv|
					puts mv
					
					File.open(mv) do |f|
						inserts = []
						id = f.gets.delete(":").strip
						
						while line = f.gets
							split = line.strip.split(',',3)
							inserts.push "(#{id}, #{split[0]}, #{split[1]}, '#{split[2]}', 'false')"
						end
						
						inserts.each_slice(500) do |s|
							stmt = "INSERT INTO ratings(movie, customer, rating, date, probe) VALUES #{s.join(", ")}"
							connection.exec_query stmt
						end
					end
				end
			end
			
			puts "creating indices..."
			connection.exec_query "CREATE INDEX `movies` ON `ratings` (`movie`)"
			connection.exec_query "CREATE INDEX `customers` ON `ratings` (`customer`)"
		end				
	end
end