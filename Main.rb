require 'set'
require 'sqlite3'
require_relative 'Movie'
require_relative 'Rating'

db = SQLite3::Database.new "test.db"

movies = Hash.new

Movie.list('./nf_prize_dataset/movie_titles.txt') do |m|
	movies[m.id] = m
end

puts movies.size



ratings = Array.new


puts "fetching ratings..."

Rating.listDB(db) do |r|
	ratings.push(r)
end

# Rating.list('./nf_prize_dataset/training_set') do |r|
	# ratings.push(r)
	# stmt.execute r.movie, r.customer, r.rating, r.date
# end

# db.commit

