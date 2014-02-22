module CF	
	class Base
		def initialize(model)
			@model = model
		end
		
		def train
			@model.update(state: :training)
			train_do
			@model.update(state: :trained)
		end
	
		def reset
			@model.update(state: :resetting)
			reset_do
			@model.update(state: :reset)
		end
	end
end