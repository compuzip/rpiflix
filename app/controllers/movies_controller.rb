class MoviesController < ApplicationController
	def index
		@grid = MoviesGrid.new(params[:movies_grid])		
		@assets = @grid.assets.page params[:page]
	end
  
	def show
	  config = Tmdb::Configuration.new
	  
		@movie = Movie.find(params[:id])
		@movie.populateTmdbData!
		
		@poster_urls = {}
		
		if @movie.tmdbid > 0		
			@poster_urls[@movie.id] = config.base_url + 'w500' + @movie.tmdbposter
		else
			@poster_urls[@movie.id] = nil
		end
		
		
		model = Model.where(klass: :SVD).take
		if model.state == 'trained' or model.state == 'scored'
			@similarmovies_svd = model.handler.similar_movies(@movie.id, 10)
			
			@similarmovies_svd.each do |sm|
				m = Movie.find(sm['id'])
				sm['movie'] = m
				m.populateTmdbData!
				@poster_urls[m.id] = m.tmdbid > 0 ? config.base_url + 'w500' + m.tmdbposter : nil
			end
		else
			@similarmovies_svd = []
		end
		
    @similarmovies = Pearson.get_similar_movies(@movie.id, 5)
    
    @similarmovies.each do |sm|
      sm.populateTmdbData!
      if sm.tmdbid > 0
        @poster_urls[sm.id] = config.base_url + 'w500' + sm.tmdbposter
      else
        @poster_urls[sm.id] = nil
      end
    end
		
		@freq_data = Rating.where(:movie => @movie.id).group(:rating).order(:rating).pluck(:rating, 'count(*)')
		puts @freq_data.to_s
	end
end
