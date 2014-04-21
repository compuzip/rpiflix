require 'histogram/array'

class VisualsController < ApplicationController
	def index
		@global_freq = Stat.where(:name => 'global_rating_hist').take.data
		
		movie_data = Stat.where(:name => :movie_stats_perc).take.data
		
		@movie_rating_perc = [
			movie_data.first ,
			movie_data[(0.01 * movie_data.size).to_i], 
			movie_data[(0.05 * movie_data.size).to_i], 
			movie_data[(0.5 * movie_data.size).to_i], 
			movie_data[(0.95 * movie_data.size).to_i], 
			movie_data[(0.99 * movie_data.size).to_i], 
			movie_data.last
		]
		
		customer_data = Stat.where(:name => :customer_stats_perc).take.data
		
		@customer_rating_perc = [
			customer_data.first ,
			customer_data[(0.01 * customer_data.size).to_i], 
			customer_data[(0.05 * customer_data.size).to_i], 
			customer_data[(0.5 * customer_data.size).to_i], 
			customer_data[(0.95 * customer_data.size).to_i], 
			customer_data[(0.99 * customer_data.size).to_i], 
			customer_data.last
		]
		
		@movie_rating_hist = Stat.where(:name => :movie_stats_hist).take.data
		@customer_rating_hist = Stat.where(:name => :customer_stats_hist).take.data
	end
end
