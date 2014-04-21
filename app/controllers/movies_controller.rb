class MoviesController < ApplicationController
	def index
		@grid = MoviesGrid.new(params[:movies_grid])		
		@assets = @grid.assets.page params[:page]
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
		
		@freq_data = Rating.where(:movie => @movie.id).group(:rating).order(:rating).pluck(:rating, 'count(*)')
		puts @freq_data.to_s
	end
end
