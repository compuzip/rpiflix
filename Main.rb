require 'pp'
require 'rubyvis'

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

def split_set(records, train_perc)
	train = []
	test = []
	rng = Random.new(3211)
	
	records.each do |r|
		if rng.rand < train_perc
			train << r
		else
			test << r
		end
	end
	
	return [train, test]
end



def scatter(records, xidx, yidx)
	# data = pv.range(100).map {|x| 
	  # OpenStruct.new({x: x, y: rand(), z: 10**(2*rand)})
	# }

	w = 400
	h = 400

	x = pv.Scale.linear(0, 10).range(0, w)
	y = pv.Scale.linear(0, 10).range(0, h)

	c = pv.Scale.log(1, 100).range("orange", "brown")

	# The root panel.
	vis = pv.Panel.new()
		.width(w)
		.height(h)
		.bottom(20)
		.left(20)
		.right(10)
		.top(5);

	# Y-axis and ticks. 
	vis.add(pv.Rule)
		.data(y.ticks())
		.bottom(y)
		.strokeStyle(lambda {|d| d!=0 ? "#eee" : "#000"})
		.anchor("left").add(pv.Label)
			.text(y.tick_format)
		
		# .visible(lambda {|d|  d > 0 and d < 1})

	# X-axis and ticks. 
	vis.add(pv.Rule)
		.data(x.ticks())
		.left(x)
		.stroke_style(lambda {|d| d!=0 ? "#eee" : "#000"})
		.anchor("bottom").add(pv.Label)
			.text(x.tick_format);
		
		# .visible(lambda {|d|  d > 0 and d < 100})

	# data = records.map do |r|
		# OpenStruct.new({x: r.attributes[xidx], y: r.attributes[yidx], z: (r.klass + 2)})
	# end
	
	#/* The dot plot! */
	vis.add(pv.Panel)
		.data(records)
		.add(pv.Dot)
		.left(lambda {|r| x.scale(r.attributes[xidx])})
		.bottom(lambda {|r| y.scale(r.attributes[yidx])})
		.shape_size(lambda {|r| r.klass + 2})
		.stroke_style(lambda {|r| c.scale(r.klass + 2)})
		.fill_style(lambda {|r| c.scale(r.klass + 2)})

		# .title(lambda {|d| "%0.1f" % d.z})
		
		# .stroke_style(lambda {|d| c.scale(d.z)})
		# .fill_style(lambda {|d| c.scale(d.z).alpha(0.2)})
		
	vis.render()
	
	File.open('scatter.svg', 'w') do |f|
		f.puts vis.to_svg
	end
end

data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.5

records = Record.read(data_file)
train, test = split_set(records, train_perc)

scatter(train, 5, 1)

puts train.size
puts test.size


puts 'GINI train: ' + GINI(train).to_s
puts 'GINI test: ' + GINI(test).to_s

puts 'Entropy train: ' + Entropy(train).to_s
puts 'Entropy test: ' + Entropy(test).to_s


# puts records.size	683

tree = Tree.build(train, 0..8)

g =  GraphViz.new( :G, :type => :digraph )
Tree.dump_node(tree, g)
g.output( :png => "tree.png" )

# pp tree

puts 'testing....'


err = Tree.error(tree, test)
accuracy = (test.size - err) / test.size.to_f
puts 'accuracy: ' + accuracy.to_s