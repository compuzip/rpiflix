require 'active_record'
require 'themoviedb'

# require_relative 'DBLoader'
require_relative 'app/models/Movie'
# require_relative 'Rating'
# require_relative 'Probe'

# require_relative 'models/Random'
# require_relative 'models/Baseline'

# require_relative 'Oracle'


require_relative 'config/initializers/themoviedb'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'db/development.sqlite3',
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)


# puts Rating.count
# puts Probe.count
# puts Movie.count


# model = Random.new
# model = Baseline.new

# model.calibrate

# oracle = Oracle.new

# rmse = oracle.score(model)
# puts 'rmse: ' + rmse.to_s

# movies = Hash.new
# Movie.list('./nf_prize_dataset/movie_titles.txt') do |m|
	# movies[m.id] = m
# end
# puts movies.size



config = Tmdb::Configuration.new
puts config
puts config.base_url
puts config.poster_sizes

a = Tmdb::Movie.find("batman")

a.each do |m|
	puts m
	puts m.poster_path
	# puts m.id
	# puts m.original_title
	# puts m.release_date
end

puts Movie.count

m = Movie.find(75)
puts m
puts m.title

m.findTmdbID