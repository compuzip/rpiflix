require 'pp'
require 'rubyvis'
require 'matrix'

require_relative 'Record'

require_relative 'Tree'
require_relative 'SVM'

require_relative 'Plot'



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

def split_set(records, train_perc)
	train = []
	test = []
	rng = Random.new(3211)
	
	records.each do |r|
		(rng.rand < train_perc ? train : test) << r
	end
	
	return [train, test]
end



def filter(records, xidx, yidx, vals, idx = 0)
	if idx == vals.size
		name = vals.join('_')
		puts vals.to_s + ': ' + name + ': ' + records.size.to_s
		
		Plot.scatter(records, xidx, yidx, 'plots/test_' + name + '_' + records.size.to_s + '.png')
		
		# save_chart('plots/test_' + name + '_' + records.size.to_s + '.png', create_chart(records, xidx, yidx))
	else
		if idx == xidx or idx == yidx
			filter(records, xidx, yidx, vals, idx + 1)
		else	
			records.map{|r| r.attributes[idx]}.uniq.each do |a|
				vals[idx] = a
				
				rec = records.select{|r| r.attributes[idx] == a}
				uniq = rec.uniq{|r| r.klass}
				
				if rec.size > 1 and uniq.size > 1
					filter(rec, xidx, yidx, vals, idx + 1)
				end
			end
		end
	end
end




data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.3

records = Record.read(data_file)

# records = Record.data_p265
# SVM.new(Record.data_p265)

# aaaaaaaaaaaaa

# records = records.map{|r| Record.new(r.id, r.attributes.first(5), r.klass)}

# lambdas = SVM.calc_lambdas(records)

# w = SVM.calc_w(records, lambdas)

# b = SVM.calc_b(records, lambdas, w)



# r1 = Record.new('1', [0.4, 0.2], 1)
# r2 = Record.new('2', [0.7, 0.9], -1)

# puts s.classify(r1)
# puts s.classify(r2)




train, test = split_set(records, train_perc)

s = SVM.new(train)

attrs = train[0].attributes.size

Range.new(0, attrs - 2).each do |x|
	Range.new(x + 1, attrs - 1).each do |y|
		puts '==== ' + x.to_s + 'v' + y.to_s

		vals = Array.new(attrs)
		vals[x] = 'x'
		vals[y] = 'y'
		filter(records, x, y, vals)
	end
end




# puts attrs

# puts train.size
# puts test.size


puts 'GINI train: ' + GINI(train).to_s
puts 'GINI test: ' + GINI(test).to_s

puts 'Entropy train: ' + Entropy(train).to_s
puts 'Entropy test: ' + Entropy(test).to_s


tree = Tree.build(train, 0..(attrs - 1))

# g =  GraphViz.new( :G, :type => :digraph )
# Tree.dump_node(tree, g)
# g.output( :png => "tree.png" )

# pp tree

puts 'testing....'


err = Tree.error(tree, test)
accuracy = (test.size - err) / test.size.to_f
puts 'accuracy: ' + accuracy.to_s