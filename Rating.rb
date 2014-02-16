class Rating < ActiveRecord::Base
	
	def self.initDB(dirName)
		if not connection.table_exists?('ratings')
			connection.exec_query "create table ratings (movie int, customer int, rating int, date date, probe bool)"
			
			transaction do
				Dir.glob(dirName + "/mv*.txt") do |mv|
					puts mv
					
					File.open(mv) do |f|
						id = f.gets.delete(":").to_i
						while line = f.gets
							a = Hash[[:movie, :customer, :rating, :date, :probe].zip([id, *line.strip.split(',',3), false])]
							create(a)
						end
					end
				end
			end
		end		
	end
	
end