class ProbesGrid

	include Datagrid

	scope do
		Probe.order(:movie).order(:customer)
	end

	# filter(:year)
	
	include ActionView::Helpers::UrlHelper

	column(:movie) do |p|
		ActionController::Base.helpers.link_to(p.movie, Rails.application.routes.url_helpers.movie_path(p.movie))
	end
	
	column(:title) do |p|
		Movie.find(p.movie).title
	end
	
	column(:customer)

end
