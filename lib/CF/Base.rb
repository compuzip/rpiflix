module CF	
	class Base
		def initialize(model)
			@model = model
		end
	
		def train_begin
			@model.state = :training
			@model.save
		end
		
		def train_end
			@model.state = :trained
			@model.save
		end
		
		def reset_begin
			@model.state = :resetting
			@model.save
		end
		
		def reset_end
			@model.state = :reset
			@model.save
		end
	end
end