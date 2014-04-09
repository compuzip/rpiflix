class Record
	attr_accessor :id
	attr_accessor :attributes
	attr_accessor :klass
	
	def initialize(id, attributes, klass)
		@id = id
		@attributes = attributes
		@klass = klass
	end
end