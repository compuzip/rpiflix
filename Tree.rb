require 'graphviz'

class Tree
	class Node
		attr_accessor :attr_idx
		attr_accessor :map
		attr_accessor :total
	
		def decide(record)
			a = record.attributes[attr_idx]
			
			if map.key?(a)
				map[a].decide(record)
			else
				# untrained combination
				# use existing entries, weighted by distance
				res = Hash.new(0)
				map.each do |k,v|
					d = v.decide(record)
					res[d] += 1.0 / (a - k).abs ** 2 * v.total
				end
				
				# puts res
				# puts res.max_by{|e| e[1]}[0]
				
				res.max_by{|e| e[1]}[0]
				# 3
			end
		end
		
		def leaves
			map.values.reduce(0){|sum, v| sum + v.leaves}
		end
	end

	class Leaf
		attr_accessor :klass
		attr_accessor :majority
		attr_accessor :total
		
		def initialize(klass, majority, total)
			@klass = klass
			@majority = majority
			@total = total
		end
		
		def decide(record)
			klass
		end
		
		def leaves
			1
		end
	end

	def self.error(root, records)
		err = 0
		records.each do |t|
			pred = root.decide(t)
			
			if t.klass != pred
				err += 1
				pp t
				puts 'expected: ' + t.klass.to_s + ', got: ' + pred.to_s
			end
		end
		
		err
	end
	
	def self.prune(root, training)
		puts error(root, training)
	end
	
	def self.dump_node(node, g, seq = (1..10000).each)
		if node.is_a? Leaf
			ret = g.add_nodes('id' + seq.next.to_s, {:label => "#{node.klass} (#{node.majority}/#{node.total})"})
		else
			ret = g.add_nodes('id' + seq.next.to_s, {:label => "idx #{node.attr_idx} (#{node.total})"})
			
			node.map.each do |k,v|
				g.add_edges(ret, dump_node(v, g, seq), {:label => k.to_s} )
			end
			
			return ret
		end
	end
	
	def self.build(records, attrs_remaining)
		
		# puts 'GINI: ' + GINI(records).to_s

		# single class
		if records.group_by{|r| r.klass}.size == 1
			return Leaf.new(records.first.klass, records.size, records.size)
		end
		
		if attrs_remaining.count == 0
			grouped = records.group_by{|r| r.klass}
			
			# majority rule
			max = grouped.max{|a,b| a[1].size <=> b[1].size}
			
			return Leaf.new(max[0], max[1].size, records.size)
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
		
		node.total = node.map.values.reduce(0){|sum, r| sum + r.total}
		
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