class Record
	attr_accessor :id
	attr_accessor :attributes
	attr_accessor :klass
	
	def initialize(id, attributes, klass)
		@id = id
		@attributes = attributes
		@klass = klass
	end
	
	def self.read(file_name)
		out_map = {'2' => 1, '4' => -1}
	
		records = {}
	
		File.open(file_name) do |f|
			seq = (1..100).each

			while line = f.gets
				if line.include? ',?,'
					puts 'skipping: ' + line
				else
					split = line.strip.split(',')
					
					r = Record.new(split[0], 
						split[1,split.size - 2].map{|x| x.to_i}, 
						out_map[split[-1]])
					
					if records.key?(r.id)
						# puts 'duplicate record id: ' + r.id.to_s
						r.id = r.id + '_' + seq.next.to_s
					end
					
					records[r.id] = r
				end
			end
		end
	
		return records.values.to_a
	end
end