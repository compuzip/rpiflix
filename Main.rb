require 'pp'
require 'rubyvis'

require_relative 'Tree'
require_relative 'Record'

require "java"
require "lib/jcommon-1.0.22.jar"
require "lib/jfreechart-1.0.17.jar"

# include_class "org.jfree.chart.ChartPanel"
# include_class "org.jfree.chart.plot.PlotOrientation"
# include_class "org.jfree.chart.ChartFactory"
# include_class "org.jfree.data.xy.XYSeries"
# include_class "org.jfree.data.xy.XYSeriesCollection"

# -- Code to build the Swing Frame
# include_class "javax.swing.JFrame"
# include_class "java.awt.BorderLayout"


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

def create_chart(records, xidx, yidx)
  
	series_collection = org.jfree.data.xy.XYSeriesCollection.new
    
	records.group_by{|r| r.klass}.each do |k,v|
		series = org.jfree.data.xy.XYSeries.new(k.to_s);
		v.each do |r|
			series.add(r.attributes[xidx], r.attributes[yidx])
		end
		
		series_collection.addSeries(series)
	end
  
	xAxis = org.jfree.chart.axis.NumberAxis.new(xidx.to_s)
	# xAxis.setAutoRangeIncludesZero(false);
	yAxis = org.jfree.chart.axis.NumberAxis.new(yidx.to_s)
	# yAxis.setAutoRangeIncludesZero(false);

	plot = org.jfree.chart.plot.XYPlot.new(series_collection, xAxis, yAxis, nil)

	renderer = org.jfree.chart.renderer.xy.XYLineAndShapeRenderer.new(false, true)
	# renderer.setBaseToolTipGenerator(toolTipGenerator);
	# renderer.setURLGenerator(urlGenerator);
	plot.setRenderer(renderer)
	plot.setOrientation(org.jfree.chart.plot.PlotOrientation::VERTICAL)

	chart3 = org.jfree.chart.JFreeChart.new("#{xidx} vs. #{yidx}", org.jfree.chart.JFreeChart::DEFAULT_TITLE_FONT, plot, true);
	# currentTheme.apply(chart) 
  
  # chart2 = ChartFactory.createScatterPlot(
            # "Scatter Plot",
            # "X",
            # "Y",
            # series_collection,
            # PlotOrientation::VERTICAL,
            # true,
            # true,
            # false
	# )
end


def create_frame chart
  frame = javax.swing.JFrame.new("jRuby using JFreeChart")
  frame.content_pane.add(org.jfree.chart.ChartPanel.new(chart), java.awt.BorderLayout::CENTER)
  frame.setSize(600, 400)
  frame.visible = true
  frame.default_close_operation = javax.swing.JFrame::EXIT_ON_CLOSE
end

def save_chart(name, chart)
	org.jfree.chart.ChartUtilities.saveChartAsPNG(java.io.File.new(name), chart, 600, 400)
end

def filter(records, xidx, yidx, vals, idx = 0)
	if idx == vals.size
		name = vals.join('_')
		puts vals.to_s + ': ' + name + ': ' + records.size.to_s
		
		save_chart('plots/test_' + name + '_' + records.size.to_s + '.png', create_chart(records, xidx, yidx))
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
train_perc = 0.5

# records = Record.read(data_file)

records = Record.data_p265

# records = records.map{|r| Record.new(r.id, r.attributes.first(5), r.klass)}


train, test = split_set(records, train_perc)

# save_chart("test123.png", create_chart(train, 5, 1))

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

aaaaaaaaaaaaa


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