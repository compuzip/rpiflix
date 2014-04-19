require 'histogram/array'

class VisualsController < ApplicationController
	def make_histogram(name)
		data = Stat.where(:name => name).take.data.map{|e| e[1][0]}
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
		
		@movie_rating_hist = make_histogram(:movie_stats)
		@customer_rating_hist = make_histogram(:customer_stats)
	end
end
