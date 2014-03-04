class ProbesGrid

	include Datagrid

	scope do
		Probe.order(:movie).order(:customer)
	end

	filter(:movie)
	filter(:customer)
	filter(:rating)
	
	include ActionView::Helpers::UrlHelper

	column(:movie) do |p|
		ActionController::Base.helpers.link_to(p.movie, Rails.application.routes.url_helpers.movie_path(p.movie))
	end
	
	column(:title) do |p|
		Movie.find(p.movie).title
	end
	
	column(:customer)

	column(:date)
	column(:rating)
	
	Model.all.each do |m|
		if m.state == "scored"
			column(:"#{m.klass} prediction") do |p|
				pred = Prediction.where(model: m.id, movie: p.movie, customer: p.customer).take
				pred.nil? ? 0.0 : pred.prediction
			end
		end
	end
	
end
