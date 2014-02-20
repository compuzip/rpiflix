class MoviesController < ApplicationController
	def index
		@movies = Movie.all
		@tmdbconfig = Tmdb::Configuration.new
	end
  
	def show
		@movie = Movie.find(params[:id])
		@movie.populateTmdbData!
		
		if @movie.tmdbid > 0
			config = Tmdb::Configuration.new			
			@poster_url = config.base_url + 'w500' + @movie.tmdbposter
		else
			@poster_url = nil
		end
		
		@ratingCount = Rating.where(movie: @movie.id).count
		
		@ratingAvg = @ratingCount > 0 ? Rating.where(movie: @movie.id).average('rating') : 0.0
	end
end