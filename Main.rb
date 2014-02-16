require 'set'
require 'sqlite3'
require 'active_record'

require_relative 'Movie'
require_relative 'Rating'

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.db',
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)

Rating.initDB('./nf_prize_dataset/training_set')

puts Rating.count

Rating.where(customer: 862759).each do |r|
	puts r
end

movies = Hash.new

Movie.list('./nf_prize_dataset/movie_titles.txt') do |m|
	movies[m.id] = m
end

puts movies.size