class MoviesController < ApplicationController
	def index
		@movies = Movie.all
	end
  
	def show
		@movie = Movie.find(params[:id])
	 
		@movie.tmdbid = @movie.findTmdbID	
	end
end
