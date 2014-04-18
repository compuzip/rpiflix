class VisualsController < ApplicationController
	def index
		# @global_freq = Rating.group(:rating).order(:rating).pluck(:rating, 'count(*)')
		# puts @global_freq.to_a
		
		@movie_rating_hist = Stat.where(:name => :movie_rating_hist).take.data
		
		puts @movie_rating_hist.to_s
	end
end
