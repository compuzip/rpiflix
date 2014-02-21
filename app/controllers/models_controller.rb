class ModelsController < ApplicationController
	def index
		@models = Model.all
	end
	
	def train
		model = Model.find(params[:id])
		m = model.handler
		m.train
		
		redirect_to action: 'index', notice: ('training model ' + model.id)
	end
	
	def reset
		model = Model.find(params[:id])
		m = model.handler
		m.reset
		
		redirect_to action: 'index', notice: ('resetting model ' + model.id)
	end
end