require 'pp'

class Tester
	def initialize(model)
		@model = model
	end
	
	def error(records)
		err = 0
		records.each do |t|
			pred = @model.classify(t)
			
			if t.klass != pred
				err += 1
				# pp t
				# puts 'expected: ' + t.klass.to_s + ', got: ' + pred.to_s
			end
		end
		
		err
	end
end