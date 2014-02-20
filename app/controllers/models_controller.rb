class ModelsController < ApplicationController
	def index
		@models = CF::Base.list
	end
end