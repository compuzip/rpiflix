class Model < ActiveRecord::Base
	def handler
		# instantiate corresponding class from CF::
		CF.const_get(clazz, false).new(id)
	end
end