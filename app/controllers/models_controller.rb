class ModelsController < ApplicationController
	def index
		@models = Model.all
	end
	
	def train
		model = Model.find(params[:id])
		model.handler.delay.train
		
		redirect_to action: 'index', notice: ('training model ' + model.clazz)
	end
	
	def reset
		model = Model.find(params[:id])
		model.handler.delay.reset
		
		redirect_to action: 'index', notice: ('resetting model ' + model.clazz)
	end
end