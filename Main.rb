require 'pp'
require 'rubyvis'
require 'matrix'

require_relative 'Record'

require_relative 'Tree'
require_relative 'SVM'

require_relative 'Plot'

require 'java'
require 'lib/joptimizer-3.2.0.jar'
require 'lib/colt-1.2.0.jar'
require 'lib/commons-math3-3.2.jar'
require 'lib/commons-logging-1.1.1.jar'
require 'lib/commons-lang3-3.1.jar'

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

def optimize
	# // Objective function
	pMat = [[1.0, 0.4], [0.4, 1.0]].to_java([].to_java(Java::double).class)
	
	objectiveFunction = com.joptimizer.functions.PDQuadraticMultivariateRealFunction.new(pMat, nil, 0)

	# //equalities
	aMat = [[1,1]].to_java([].to_java(Java::double).class)
	bVec = [1]
	
	# //inequalities
	inequalities = []
	inequalities[0] = com.joptimizer.functions.LinearMultivariateRealFunction.new([-1, 0], 0)
	inequalities[1] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, -1], 0)
	
	# //optimization problem
	oR = com.joptimizer.optimizers.OptimizationRequest.new
	oR.setF0(objectiveFunction)
	oR.setInitialPoint([0.1, 0.9])
	# //or.setFi(inequalities); //if you want x>0 and y>0
	oR.setA(aMat)
	oR.setB(bVec)
	oR.setToleranceFeas(1.0e-12)
	oR.setTolerance(1.0e-12)
	
	# //optimization
	opt = com.joptimizer.optimizers.JOptimizer.new()
	opt.setOptimizationRequest(oR)
	returnCode = opt.optimize()

	puts returnCode
	
	sol = opt.getOptimizationResponse().solution
	puts sol.to_a.to_s
end

def sumproduct(a, b)
	(0...a.count).inject(0) {|r, i| r + a[i]*b[i]}
end

class Matrix
  def symmetric?
    return false if not square?
    (0 ... row_size).each do |i|
      (0 .. i).each do |j|
        return false if self[i,j] != self[j,i]
      end
    end
    true
  end
 
  def cholesky_factor
    raise ArgumentError, "must provide symmetric matrix" unless symmetric?
    l = Array.new(row_size) {Array.new(row_size, 0)}
    (0 ... row_size).each do |k|
      (0 ... row_size).each do |i|
        if i == k
          sum = (0 .. k-1).inject(0.0) {|sum, j| sum + l[k][j] ** 2}
          val = Math.sqrt(self[k,k] - sum)
          l[k][k] = val
        elsif i > k
          sum = (0 .. k-1).inject(0.0) {|sum, j| sum + l[i][j] * l[k][j]}
          val = (self[k,i] - sum) / l[k][k]
          l[i][k] = val
        end
      end
    end
    Matrix[*l]
  end
end


def optimize2(records)
	# // Objective function
	# pMat = [[1.0, 0.4], [0.4, 1.0]].to_java([].to_java(Java::double).class)
	
	attMat = Matrix.build(records.size, records.first.attributes.size) do |r,c|
		records[r].attributes[c]
	end
	
	# puts attMat
	
	pMat2 = attMat * attMat.transpose
	
	puts pMat2
	
	y = records.map{|r| r.klass}
	yMat = Matrix.diagonal(*y)
	
	puts yMat
	
	pMat2 = (pMat2 * yMat).transpose * yMat
	
	puts pMat2
	
	# puts pMat2.symmetric?
	
	# l, u, p = pMat2.lup
	
	# puts l
	# puts u
	# puts p
	
	# pMat2 = p * pMat2
	
	# v, d, v_inv = pMat2.eigen
	
	# puts v
	# puts d
	# puts v_inv
	
	# pMat3 = v * d * v_inv
	
	# puts pMat3
	
	# d2 = Matrix.build(d.row_size, d.column_size) do |r,c|
		# if d[r,c] < 0
			# 0
		# else
			# d[r,c]
		# end
	# end
	
	# pMat3 = v * d2 * v_inv
	
	# puts pMat3
	
	# v, d, v_inv = pMat3.eigen
	
	# puts v
	# puts d
	# puts v_inv
	
	# d.each_with_index do |e, r, c|
		# d[r,c] = e.abs
	# end
	
	# puts pMat3.cholesky_factor
	
	pMat2 = pMat2.to_a.to_java([].to_java(Java::double).class)
	# pMat3 = pMat3.to_a.to_java([].to_java(Java::double).class)
	
	
	qVec = [-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0]
	
	objectiveFunction = com.joptimizer.functions.QuadraticMultivariateRealFunction.new(pMat2, qVec, 0)

	# //equalities
	
	aMat2 = Matrix[y]
	puts aMat2
	
	aMat2 = aMat2.to_a.to_java([].to_java(Java::double).class)
	puts aMat2
	
	puts aMat2.to_a.to_s
	
	bVec2 = [0.0]
	
	# aMat = [[1,1]].to_java([].to_java(Java::double).class)
	# bVec = [1]
	
	# //inequalities
	inequalities = []
	inequalities[0] = com.joptimizer.functions.LinearMultivariateRealFunction.new([-1, 0, 0, 0, 0, 0, 0, 0], 0)
	inequalities[1] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, -1, 0, 0, 0, 0, 0, 0], 0)
	inequalities[2] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, -1, 0, 0, 0, 0, 0], 0)
	inequalities[3] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, 0, -1, 0, 0, 0, 0], 0)
	inequalities[4] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, 0, 0, -1, 0, 0, 0], 0)
	inequalities[5] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, 0, 0, 0, -1, 0, 0], 0)
	inequalities[6] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, 0, 0, 0, 0, -1, 0], 0)
	inequalities[7] = com.joptimizer.functions.LinearMultivariateRealFunction.new([0, 0, 0, 0, 0, 0, 0, -1], 0)
	
	# //optimization problem
	oR = com.joptimizer.optimizers.OptimizationRequest.new
	# oR.setInteriorPointMethod(com.joptimizer.optimizers.JOptimizer::BARRIER_METHOD)
	oR.setF0(objectiveFunction)
	# oR.setInitialPoint([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	oR.setInitialPoint([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
	# //or.setFi(inequalities); //if you want x>0 and y>0
	oR.setFi(inequalities)
	oR.setA(aMat2)
	oR.setB(bVec2)
	oR.setToleranceFeas(1.0e-12)
	oR.setTolerance(1.0e-12)
	oR.setMaxIteration(50)
	
	# //optimization
	opt = com.joptimizer.optimizers.JOptimizer.new()
	opt.setOptimizationRequest(oR)
	returnCode = opt.optimize()

	puts returnCode
	
	sol = opt.getOptimizationResponse().solution
	puts sol.to_a.to_s
end

data_file = 'breast-cancer-wisconsin.data'
train_perc = 0.5

# records = Record.read(data_file)

records = Record.data_p265

# records = records.map{|r| Record.new(r.id, r.attributes.first(5), r.klass)}

optimize2(records)
aaaaaaaaaaaaa


train, test = split_set(records, train_perc)

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