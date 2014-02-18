require 'active_record'

require_relative 'Movie'
require_relative 'Rating'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.db',
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)

Rating.initDB('./nf_prize_dataset')

puts Rating.count
puts Rating.where(probe: 0).count

Rating.where(customer: 669077).each do |r|
	puts r.probe
end

movies = Hash.new

Movie.list('./nf_prize_dataset/movie_titles.txt') do |m|
	movies[m.id] = m
end

puts movies.size