require 'pp'

def Entropy(records)
	sum = 0.0
	sz = records.size.to_f
	
	records.group_by{|r| r.klass}.each do |k, v|
		sum += (v.size / sz) * Math.log(v.size / sz, 2)
	end
	
	-sum
end

def GINI(records)
	sum = 0.0
	sz = records.size.to_f
	
	records.group_by{|r| r.klass}.each do |k, v|
		sum += (v.size / sz) ** 2
	end
	
	1.0 - sum
end

class Record
	attr_accessor :id
	attr_accessor :attrs
	attr_accessor :klass
end

out_map = {'2' => 1, '4' => -1}

data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.5

train = []
test = []

File.open(data_file) do |f|
	records = Hash.new
	seq = (1..100).each
	rng = Random.new(3211)

	while line = f.gets
		if line.include? ',?,'
			puts 'skipping: ' + line
		else
			split = line.strip.split(',')
			
			r = Record.new()
			r.id = split[0]
			r.attrs = split[1,split.size - 2].map{|x| x.to_i}
			r.klass = out_map[split[-1]]
			
			if records.key?(r.id)
				puts 'duplicate record id: ' + r.id.to_s
				r.id = r.id + '_' + seq.next.to_s
			end
			
			records[r.id] = r
			
			# pp r
			
			if rng.rand < train_perc
				train << r
			else
				test << r
			end
		end
	end
end

puts train.size
puts test.size


c1 = Record.new
c1.klass = 'c1'

c2 = Record.new
c2.klass = 'c2'

puts GINI([] << c2 << c2 << c2 << c2)
puts GINI([] << c1 << c2 << c2 << c2 << c2 << c2)
puts GINI([] << c1 << c1 << c2 << c2 << c2 << c2)
puts GINI([] << c1 << c1 << c1 << c2 << c2 << c2)

puts Entropy([] << c2 << c2 << c2 << c2)
puts Entropy([] << c1 << c2 << c2 << c2 << c2 << c2)
puts Entropy([] << c1 << c1 << c2 << c2 << c2 << c2)

puts '============================'

puts GINI(train)
puts GINI(test)

puts Entropy(train)
puts Entropy(test)


# puts records.size	683

