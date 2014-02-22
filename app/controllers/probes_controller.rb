class ProbesController < ApplicationController
	def index
		@probes = Probe.all
	end
  
	def show
		
	end
end
