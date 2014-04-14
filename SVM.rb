require 'matrix'

require 'java'
require 'lib/joptimizer-3.2.0.jar'
require 'lib/colt-1.2.0.jar'
require 'lib/commons-math3-3.2.jar'
require 'lib/commons-logging-1.1.1.jar'
require 'lib/commons-lang3-3.1.jar'
require 'lib/ojalgo-35.0.jar'

class SVM
	module Kernel
		LINEAR = proc {|a,b| a.inner_product(b) }
		POLY_HOMOGENOUS_2 = proc {|a,b| a.inner_product(b) ** 2 }
		GAUSSIAN_RBF_2 = proc {|a,b| Math.exp(-2 * (a-b).norm)}
	end

	attr_accessor :kernel
	attr_accessor :attMat
	attr_accessor :yVec
	attr_accessor :lambdas
	attr_accessor :wVec
	attr_accessor :b
	

	def initialize(records)
		@kernel = Kernel::GAUSSIAN_RBF_2
		
		@attMat, @yVec = a_y_matrix(records)
		
		@lambdas = calc_lambdas
		# calc_lambdas2
		
		@wVec = calc_w
		@b = calc_b
	end

	def classify(record)
		z = Vector.elements(record.attributes)
		
		sum = 0.0
		@lambdas.each_index do |i|
			sum += @lambdas[i] * @yVec[i] * @kernel.call(@attMat.row(i), z)
		end
		
		# sum += @b
		
		return sign(sum)
	end
	
	def boundary(xidx, yidx, xs)
		xs.map do |x|
			(-@wVec[xidx] * x - @b) / @wVec[yidx]
		end
	end
	
	private
	
	def sign(a)
		if a.zero?
			0
		elsif a > 0
			1
		else
			-1
		end
	end
	
	def a_y_matrix(records)
		attMat = Matrix.build(records.size, records.first.attributes.size) do |r,c|
			records[r].attributes[c]
		end
		
		yVec = records.map{|r| r.klass}
		
		[attMat, yVec]
	end

	def calc_w
		yMat = Matrix.diagonal(*@yVec)
		
		w = @attMat.transpose * yMat * Matrix[@lambdas].transpose
		w.column(0)
	end
	
	def calc_b
		b = []
		
		@lambdas.each_index do |i|
			if @lambdas[i] > 0
				b << @yVec[i] - @wVec.inner_product(@attMat.row(i))
			end
		end

		# mean
		b.inject(:+).to_f / b.size
	end
	
	def build_mat(factory, mat)
		builder = factory.getBuilder(mat.row_size, mat.column_size)
		mat.each_with_index do |e,r,c|
			builder.set(r, c, e)
		end
		
		builder.build
	end
	
	def build_arr(factory, arr)
		builder = factory.getBuilder(arr.size, 1)
		(0...arr.size).each do |r|
			builder.set(r, 0, arr[r])
		end
		builder.build
	end
	
	def calc_lambdas2
		# similar to calc_lambdas, but using ojalgo optimizer
		
		puts 'pMat2'
		pMat2 = Matrix.build(attMat.row_size, attMat.row_size) do |row, col|
			@kernel.call(attMat.row(row), attMat.row(col)) * yVec[row] * yVec[col]
		end
		
		mat_factory = org.ojalgo.matrix.PrimitiveMatrix::FACTORY

		qMat = build_mat(mat_factory, pMat2)
		cVec = build_arr(mat_factory, Array.new(@attMat.row_size, 1.0))
		
		puts 'qMat: ' + qMat.to_s
		puts 'cVec: ' + cVec.to_s
		
		eqA = build_mat(mat_factory, Matrix[@yVec])
		eqb = build_arr(mat_factory, [0])
		
		puts 'eqA: ' + eqA.to_s
		puts 'eqb: ' + eqb.to_s
		
		cConst = 100
		
		inequalitiesA = []
		inequalitiesb = []
		
		(0...@attMat.row_size).each do |i|
			g = Array.new(@attMat.row_size, 0.0)
			g[i] = -1.0
			inequalitiesA << g
			inequalitiesb << 0.0
			
			# non-linearly separable constraints
			g = Array.new(@attMat.row_size, 0.0)
			g[i] = 1.0
			inequalitiesA << g
			inequalitiesb << cConst
		end
		
		ineqA = build_mat(mat_factory, Matrix.rows(inequalitiesA))
		ineqb = build_arr(mat_factory, inequalitiesb)
		
		puts 'ineqA: ' + ineqA.to_s
		puts 'ineqb: ' + ineqb.to_s
		
		qsb = org.ojalgo.optimisation.quadratic.QuadraticSolver::Builder.new(qMat.toPrimitiveStore, cVec.toPrimitiveStore)
		qsb.equalities(eqA.toPrimitiveStore, eqb.toPrimitiveStore)
		qsb.inequalities(ineqA.toPrimitiveStore, ineqb.toPrimitiveStore)
		
		opts = org.ojalgo.optimisation.Optimisation::Options.new
		opts.validate = true
		puts opts.validate
		
		# opts.debug_stream = java.lang.System.out
		
		solver = qsb.build(opts)


		result = solver.solve
		
		puts 'result: ' + result.to_s
	end
	
	def calc_lambdas
		puts 'in calc_lambdas'
		
		# File.open('attrs.txt', 'w') do |f|
			# (0..@attMat.row_size).each do |r|
				# f.puts @attMat.row(r).to_a.to_s.tr(',[]', "\t") + "\t" + @yVec[r].to_s
			# end
		# end

		# Objective function
		yMat = Matrix.diagonal(*@yVec)
		
		puts 'pMat2'
		pMat2 = Matrix.build(attMat.row_size, attMat.row_size) do |row, col|
			@kernel.call(attMat.row(row), attMat.row(col)) * yVec[row] * yVec[col]
		end
				
		puts 'qVec'
		qVec = Array.new(@attMat.row_size, -1.0)
		
		puts 'creating objectiveFunction'
		objectiveFunction = com.joptimizer.functions.QuadraticMultivariateRealFunction.new(pMat2.to_a.to_java([].to_java(Java::double).class), qVec, 0)

		# equalities	
		aMat2 = Matrix[@yVec]
		bVec2 = [0.0]
		
		puts 'building inequalities'
		inequalities = Array.new(@attMat.row_size) do |i|
			g = Array.new(@attMat.row_size, 0.0)
			g[i] = -1.0
			com.joptimizer.functions.LinearMultivariateRealFunction.new(g, 0)
		
			# non-linearly seperable constraints
		
			# cConst = 100
		
			# g2 = Array.new(@attMat.row_size, 0.0)
			# g2[i] = 1.0
			# com.joptimizer.functions.LinearMultivariateRealFunction.new(g2, -cConst)
		end

		# initial point must be feasible
		ip_map = {1 => yVec.size / @yVec.count(1).to_f, -1 => yVec.size / @yVec.count(-1).to_f}
		ip = @yVec.map{|e| ip_map[e]}
		
		puts 'ip: ' + ip.to_s
		
		# optimization problem
		oR = com.joptimizer.optimizers.OptimizationRequest.new
		
		oR.setF0(objectiveFunction)
		oR.setInitialPoint(ip)
		
		oR.setFi(inequalities)
		oR.setA(aMat2.to_a.to_java([].to_java(Java::double).class))
		oR.setB(bVec2)
		oR.setToleranceFeas(1.0e-12)
		oR.setTolerance(1.0e-12)
		oR.setMaxIteration(100)

		puts 'calling optimize'
		opt = com.joptimizer.optimizers.JOptimizer.new()
		opt.setOptimizationRequest(oR)
		returnCode = opt.optimize()

		puts 'return code: ' + returnCode.to_s
		
		sol = opt.getOptimizationResponse().solution.to_a
		# puts 'sol: ' + sol.to_s
		
		sol = sol.map{|e| e.abs < 1e-6 ? 0 : e}
		
		puts 'sol: ' + sol.to_s
		
		return sol
	end

end