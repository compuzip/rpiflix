class ProbesController < ApplicationController
	def index
		@grid = ProbesGrid.new(params[:probes_grid])		
		@assets = @grid.assets.page params[:page]
	end
  
	def show
		
	end
end
