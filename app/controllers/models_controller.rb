class ModelsController < ApplicationController
	def index
		@models = Model.order(:id)
	end
	
	def train
		model = Model.find(params[:id])
		Thread.new { model.handler.train }
		
		redirect_to action: 'index', notice: ('training model ' + model.klass)
	end
	
	def reset
		model = Model.find(params[:id])		
		Thread.new { model.handler.reset }
		
		redirect_to action: 'index', notice: ('resetting model ' + model.klass)
	end
	
	def score
		model = Model.find(params[:id])
		@score = CF::Oracle.score(model.handler)
		puts @score
	end
end