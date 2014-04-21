class MoviesGrid
	include Datagrid

	scope do
		Movie.order(:id)
	end
	
	filter(:title, :string) do |value| 
		where("title ilike '%#{value}%'")
	end
	
	filter(:year)
	
	# filter(:rating_avg, :dynamic)
	
	filter(:rating, :string) do |value|
		puts value
		if value.start_with?('>') or value.start_with?('<') or value.start_with?('=')
			where("rating_avg #{value}")
		else
			where("rating_avg = #{value}")
		end
	end
	
	filter(:count, :string) do |value|
		puts value
		if value.start_with?('>') or value.start_with?('<') or value.start_with?('=')
			where("rating_count #{value}")
		else
			where("rating_count = #{value}")
		end
	end
	
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
