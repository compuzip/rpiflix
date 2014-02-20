module CF

	Dir[File.join(File.dirname(__FILE__), "/*.rb")].each do |file| 
		puts "REQUIRING " + file
		require file
	end
	
	class Base
		@names = []
	
		def register(name)
			@names.push(name)
		end
	
		def self.list
			return @names
		end
	end
end