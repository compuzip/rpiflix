class Model < ActiveRecord::Base
	def handler
		CF.const_get(id, false).new(self)
	end
end