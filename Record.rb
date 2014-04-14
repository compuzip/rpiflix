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
						r.id = r.id + '_' + seq.next.to_s
					end
					
					records[r.id] = r
				end
			end
		end
	
		return records.values.to_a
	end
	
	def self.data_p265
		ret = []
		
		ret << new(1, [0.3858, 0.4687], 1)	# 1
		ret << new(2, [0.4871, 0.611], -1)
		ret << new(3, [0.9218, 0.4103], -1)
		ret << new(4, [0.7382, 0.8936], -1)
		ret << new(5, [0.1763, 0.0579], 1)	# 1
		ret << new(6, [0.4057, 0.3529], 1)	# 1
		ret << new(7, [0.9355, 0.8132], -1)
		ret << new(8, [0.2146, 0.0099], 1)
		# ret << new(9, [0.6, 0.25], 1)
	end
end