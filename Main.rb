require 'active_record'

require_relative 'DBLoader'
require_relative 'Movie'
require_relative 'Rating'
require_relative 'Probe'

require_relative 'models/Random'
require_relative 'models/Baseline'

require_relative 'Oracle'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.db',
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)

DBLoader.resetDB

DBLoader.populateRatings('./nf_prize_dataset')
DBLoader.populateMovies('./nf_prize_dataset')

puts Rating.count
puts Probe.count
puts Movie.count

# Rating.where(customer: 669077).each do |r|
	# puts r.probe
# end

# model = Random.new
model = Baseline.new

model.calibrate

oracle = Oracle.new

rmse = oracle.score(model)
puts 'rmse: ' + rmse.to_s

# movies = Hash.new
# Movie.list('./nf_prize_dataset/movie_titles.txt') do |m|
	# movies[m.id] = m
# end
# puts movies.size