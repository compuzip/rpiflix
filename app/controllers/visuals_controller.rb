require 'histogram/array'

class VisualsController < ApplicationController
	def make_histogram(data)
		min, max = data.minmax
		
		# log scale (skipping first point(s))
		scale = (2..20).map{|v| min * Math.exp( v / 20.0 * (Math.log(max) - Math.log(min)))}		
		bins,freq = data.histogram(:bins =>  scale)
		
		hist = {}
		bins.each_index do |i|
			hist['%10.0f' % bins[i]] = freq[i]
		end
		
		hist
	end

	def index
		@global_freq = Stat.where(:name => 'global_rating_hist').take.data
		
		movie_data = Stat.where(:name => :movie_stats).take.data.map{|e| e[1][0]}.sort!
		customer_data = Stat.where(:name => :customer_stats).take.data.map{|e| e[1][0]}.sort!
		
		@movie_rating_perc = [
			movie_data.first ,
			movie_data[(0.01 * movie_data.size).to_i], 
			movie_data[(0.05 * movie_data.size).to_i], 
			movie_data[(0.5 * movie_data.size).to_i], 
			movie_data[(0.95 * movie_data.size).to_i], 
			movie_data[(0.99 * movie_data.size).to_i], 
			movie_data.last
		]
		
		@customer_rating_perc = [
			customer_data.first ,
			customer_data[(0.01 * customer_data.size).to_i], 
			customer_data[(0.05 * customer_data.size).to_i], 
			customer_data[(0.5 * customer_data.size).to_i], 
			customer_data[(0.95 * customer_data.size).to_i], 
			customer_data[(0.99 * customer_data.size).to_i], 
			customer_data.last
		]
		
		@movie_rating_hist = make_histogram(movie_data)
		@customer_rating_hist = make_histogram(customer_data)
	end
end
