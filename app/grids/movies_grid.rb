class MoviesGrid

	include Datagrid

	scope do
		Movie.order(:id)
	end

	filter(:year)
	
	include ActionView::Helpers::UrlHelper

	column(:id) do |m|
		ActionController::Base.helpers.link_to(m.id, Rails.application.routes.url_helpers.movie_path(m))
	end
  
	tmdbconfig = Tmdb::Configuration.new

	column(:poster) do |m|
		m.tmdbposter ? ('<img src="' + tmdbconfig.base_url + 'w92' + m.tmdbposter + '">') : ''
	end
  
	column(:title)
	column(:rating_avg) do |m|
		"%2.2f" % m.rating_avg
	end

	column(:rating_count)
	column(:year)
end
