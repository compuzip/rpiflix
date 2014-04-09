require 'graphviz'

class Tree
	class Node
		attr_accessor :attr_idx
		attr_accessor :map
	
		def decide(record)
			a = record.attributes[attr_idx]
			
			if map.key?(a)
				map[a].decide(record)
			else
				3
			end
		end
	end

	class Leaf
		attr_accessor :klass
		
		def decide(record)
			klass
		end
	end

	def self.dump(node, g = nil, seq = (1..10000).each)
		root = false
		
		if g.nil?
			root = true
			g = GraphViz.new( :G, :type => :digraph )
		else
			root = false
		end

		if node.is_a? Leaf
			ret = g.add_nodes('id' + seq.next.to_s, {:label => node.klass.to_s})
		else
			ret = g.add_nodes('id' + seq.next.to_s, {:label => 'idx ' + node.attr_idx.to_s})
			
			node.map.each do |k,v|
				g.add_edges(ret, dump(v, g, seq), {:label => k.to_s} )
			end
		end

		if root
			# Generate output image
			g.output( :png => "tree.png" )
		end
		
		return ret
	end
	
	def self.build(records, attrs_remaining)
		
		# puts 'GINI: ' + GINI(records).to_s
		
		if GINI(records) == 0.0
			leaf = Leaf.new
			leaf.klass = records.first.klass
			return leaf
		end
		
		if attrs_remaining.count == 2
			# puts 'UNDETERMINED'
			
			# puts 'records'
			# puts records
			
			grouped = records.group_by{|r| r.klass}
			grouped.each do |k, v|
				grouped[k] = v.size
			end
			
			# puts grouped
			
			max = grouped.max{|a,b| a[1] <=> b[1]}
			# puts max
			
			leaf = Leaf.new
			leaf.klass = max[0]
			return leaf
		end
		
		# puts 'record count: ' + records.size.to_s
		# puts 'attrs_remaining: ' + attrs_remaining.to_s
		
		best = attrs_remaining.min do |a,b|
			split_measure(records, a) <=> split_measure(records, b)
		end
		
		attrs_new = attrs_remaining.reject{|a| a == best}
		
		# puts 'best attrib idx: ' + best.to_s
		# puts 'attrs_new: ' + attrs_new.to_s
		
		if records.group_by{|r| r.attributes[best]}.size == 1
			node = build(records, attrs_new)
			return node
		end
		
		node = Node.new
		node.attr_idx = best
		node.map = {}
		
		records.group_by{|r| r.attributes[best]}.each do |k,v|			
			node.map[k] = build(v, attrs_new)
		end
		
		node
	end
	
private
	def self.split_measure(records, attrib)
		sum = 0.0
		sz = records.size.to_f
		
		records.group_by{|r| r.attributes[attrib]}.each do |k, v|
			sum += v.size / sz * GINI(v)
		end
		
		sum
	end
end