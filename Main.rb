require_relative 'Record'

require_relative 'Tree'
require_relative 'SVM'

require_relative 'Plot'
require_relative 'Tester'


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

def filter(records, xidx, yidx, svm, vals, idx = 0)
	if idx == vals.size
		name = vals.join('_')
		puts vals.to_s + ': ' + name + ': ' + records.size.to_s
		
		Plot.scatter(records, xidx, yidx, svm, 'plots/test_' + name + '_' + records.size.to_s + '.png')
		
		# save_chart('plots/test_' + name + '_' + records.size.to_s + '.png', create_chart(records, xidx, yidx))
	else
		if idx == xidx or idx == yidx
			filter(records, xidx, yidx, svm, vals, idx + 1)
		else	
			records.map{|r| r.attributes[idx]}.uniq.each do |a|
				vals[idx] = a
				
				rec = records.select{|r| r.attributes[idx] == a}
				uniq = rec.uniq{|r| r.klass}
				
				if rec.size > 1 and uniq.size > 1
					filter(rec, xidx, yidx, svm, vals, idx + 1)
				end
			end
		end
	end
end

# st = SVM.new(Record.data_p265)
# puts 'w: ' + st.wVec.to_s
# puts 'b: ' + st.b.to_s


data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.5

records = Record.read(data_file)


train, test = split_set(records, train_perc)

svm = SVM.new(train)

attrs = records.first.attributes.size

# Range.new(0, attrs - 2).each do |x|
	# Range.new(x + 1, attrs - 1).each do |y|
		# puts '==== ' + x.to_s + 'v' + y.to_s

		# vals = Array.new(attrs)
		# vals[x] = 'x'
		# vals[y] = 'y'
		# filter(records, x, y, svm, vals)
	# end
# end

puts 'train size: ' + train.size.to_s + ', test size: ' + test.size.to_s

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

puts 'tree train accuracy: ' + ((test.size - Tester.new(tree).error(train)) / test.size.to_f).to_s
puts 'svm train accuracy: ' + ((test.size - Tester.new(svm).error(train)) / test.size.to_f).to_s

err_tree = Tester.new(tree).error(test)
accuracy_tree = (test.size - err_tree) / test.size.to_f
puts 'tree test accuracy: ' + accuracy_tree.to_s

err_svm = Tester.new(svm).error(test)
accuracy_svm = (test.size - err_svm) / test.size.to_f
puts 'svm test accuracy: ' + accuracy_svm.to_s

File.open('results.csv', 'w') do |f|
	f.puts ['ID', (0...test.first.attributes.size).map{|a| 'attr' + a.to_s}, 'class', 'tree', 'tree_err', 'SVM', 'SVM_err'].join("\t")
	test.each do |r|
		f.puts [r.id, r.attributes, r.klass, tree.classify(r), (r.klass - tree.classify(r)).abs / 2, svm.classify(r), (r.klass - svm.classify(r)).abs / 2].join("\t")
	end
end