require 'pp'
require 'rubyvis'

require_relative 'Tree'
require_relative 'Record'

require "java"
require "lib/jcommon-1.0.22.jar"
require "lib/jfreechart-1.0.17.jar"

include_class "org.jfree.data.general.DefaultPieDataset"
include_class "org.jfree.chart.ChartPanel"
include_class "org.jfree.chart.plot.PlotOrientation"
include_class "org.jfree.chart.ChartFactory"
include_class "org.jfree.data.xy.XYSeries"
include_class "org.jfree.data.xy.XYSeriesCollection"

# -- Code to build the Swing Frame
include_class "javax.swing.JFrame"
include_class "java.awt.BorderLayout"


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

def create_chart(records, xidx, yidx)
  # dataset = DefaultPieDataset.new
  # dataset.set_value("Comet Nuclei", 1.26)
  # dataset.set_value("Mars Asteroids", 7.0)
  # dataset.set_value("Apollo Objects", 0.55)

  # chart = ChartFactory.create_pie_chart(
    # "Impact Craters greater than 20km radius per million square kilometers on Mars",
    # dataset,
    # true,
    # true,
    # false
  # )
	
	series_collection = XYSeriesCollection.new
    
	records.group_by{|r| r.klass}.each do |k,v|
		series = XYSeries.new(k.to_s);
		v.each do |r|
			series.add(r.attributes[xidx], r.attributes[yidx])
		end
		
		series_collection.addSeries(series)
	end
	
	# series = XYSeries.new("Random");
	# records.each do |r|
		# series.add(rand, 2*rand)
	# end
	
	# series2 = XYSeries.new("TWO");
	# records.each do |r|
		# series2.add(rand, 2*rand)
	# end
	
    # for (int i = 0; i <= 100; i++) {
        # double x = r.nextDouble();
        # double y = r.nextDouble();
        # series.add(x, y);
    # }
    # series_collection.addSeries(series)
	# series_collection.addSeries(series2)
  
        xAxis = org.jfree.chart.axis.NumberAxis.new(xidx.to_s)
        # xAxis.setAutoRangeIncludesZero(false);
        yAxis = org.jfree.chart.axis.NumberAxis.new(yidx.to_s)
        # yAxis.setAutoRangeIncludesZero(false);

        plot = org.jfree.chart.plot.XYPlot.new(series_collection, xAxis, yAxis, nil)

        # XYToolTipGenerator toolTipGenerator = null;
        # if (tooltips) {
            # toolTipGenerator = new StandardXYToolTipGenerator();
        # }

        # XYURLGenerator urlGenerator = null;
        # if (urls) {
            # urlGenerator = new StandardXYURLGenerator();
        # }
        renderer = org.jfree.chart.renderer.xy.XYLineAndShapeRenderer.new(false, true)
        # renderer.setBaseToolTipGenerator(toolTipGenerator);
        # renderer.setURLGenerator(urlGenerator);
        plot.setRenderer(renderer)
        plot.setOrientation(PlotOrientation::VERTICAL)

        chart3 = org.jfree.chart.JFreeChart.new("Scatter Plot", org.jfree.chart.JFreeChart::DEFAULT_TITLE_FONT, plot, true);
        # currentTheme.apply(chart)
        # return chart


  
  
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

  ChartPanel.new chart3
end


def create_frame chart
  frame = JFrame.new("jRuby using JFreeChart")
  frame.content_pane.add(chart, BorderLayout::CENTER)
  frame.setSize(600, 400)
  frame.visible = true
  frame.default_close_operation = JFrame::EXIT_ON_CLOSE
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

	vis = Rubyvis::Panel.new do 
		width(w)
		height(h)
		bottom(20)
		left(20)
		right(10)
		top(5)
	end
	
	# The root panel.
	# vis = pv.Panel.new()
		# .width(w)
		# .height(h)
		# .bottom(20)
		# .left(20)
		# .right(10)
		# .top(5);
		
	# Y-axis and ticks. 
	vis.add Rubyvis::Rule do
		data y.ticks
		bottom y
		stroke_style {|d| d!=0 ? "#eee" : "#000"}
		# strokeStyle(lambda {|d| d!=0 ? "#eee" : "#000"})
		# anchor('left').label do
			# text(y.tick_format)
		# end
	end
	
	# vis.add(pv.Rule)
		# .data(y.ticks)
		# .bottom(y)
		# .strokeStyle(lambda {|d| d!=0 ? "#eee" : "#000"})
		# .anchor("left").add(pv.Label)
			# .text(y.tick_format)
		
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

# scatter(train, 5, 1)

create_frame create_chart(train, 5, 1)

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