require 'pp'

require_relative 'Tree'
require_relative 'Record'

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



out_map = {'2' => 1, '4' => -1}

data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.75

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
			
			r = Record.new(split[0], 
				split[1,split.size - 2].map{|x| x.to_i}, 
				out_map[split[-1]])
			
			if records.key?(r.id)
				# puts 'duplicate record id: ' + r.id.to_s
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


c1 = Record.new('1', [], 'c1')
c2 = Record.new('1', [], 'c2')

# puts GINI([] << c2 << c2 << c2 << c2)
# puts GINI([] << c1 << c2 << c2 << c2 << c2 << c2)
# puts GINI([] << c1 << c1 << c2 << c2 << c2 << c2)
# puts GINI([] << c1 << c1 << c1 << c2 << c2 << c2)

# puts Entropy([] << c2 << c2 << c2 << c2)
# puts Entropy([] << c1 << c2 << c2 << c2 << c2 << c2)
# puts Entropy([] << c1 << c1 << c2 << c2 << c2 << c2)

# puts '============================'

puts 'GINI train: ' + GINI(train).to_s
puts 'GINI test: ' + GINI(test).to_s

puts 'Entropy train: ' + Entropy(train).to_s
puts 'Entropy test: ' + Entropy(test).to_s


# puts records.size	683

puts 'parent: ' + GINI(train).to_s

# puts '0: ' + try_split(train, 0).to_s
# puts '1: ' + try_split(train, 1).to_s
# puts '2: ' + try_split(train, 2).to_s
# puts '3: ' + try_split(train, 3).to_s
# puts '4: ' + try_split(train, 4).to_s
# puts '5: ' + try_split(train, 5).to_s
# puts '6: ' + try_split(train, 6).to_s
# puts '7: ' + try_split(train, 7).to_s
# puts '8: ' + try_split(train, 8).to_s

tree = Tree.build(train, 0..8)

Tree.dump(tree)

# pp tree

correct = 0

test.each do |t|
	pp t
	
	pred = tree.decide(t)
	
	
	if t.klass == pred
		correct += 1
	else
		puts 'expected: ' + t.klass.to_s + ', got: ' + pred.to_s
	end
end

accuracy = correct / test.size.to_f

puts 'accuracy: ' + accuracy.to_s