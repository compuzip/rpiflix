class Movie
	attr_reader :id
	attr_reader :year
	attr_reader :title

	def initialize(id, year, title)
		@id = id.to_i
		@year = year.to_i
		@title = title
	end
	
	def self.list(fileName)
		File.open(fileName) do |f|
			while line = f.gets
				yield new(*line.split(',',3))
			end
		end
	end
end