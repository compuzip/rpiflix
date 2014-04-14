require "java"
require "lib/jcommon-1.0.22.jar"
require "lib/jfreechart-1.0.17.jar"

module Plot
	def self.scatter(records, xidx, yidx, svm, file)
  
		series_collection = org.jfree.data.xy.XYSeriesCollection.new
		
		if not svm.nil?
			series = org.jfree.data.xy.XYSeries.new('boundary');
			
			min, max = records.map{|r| r.attributes[xidx]}.minmax
			
			xs = (0..20).map {|a| min + a * (max - min) / 20.0}
			
			xs.zip(svm.boundary(xidx, yidx, xs)).each do |e|
				puts e.to_s
				series.add(e[0], e[1])
			end
			
			# series.add(0.0, -b / w[yidx])
			# series.add(1.0, (-w[xidx] - b) / w[yidx])
			
			series_collection.addSeries(series)
		end
		
		records.group_by{|r| r.klass}.each do |k,v|
			series = org.jfree.data.xy.XYSeries.new(k.to_s);
			v.each do |r|
				series.add(r.attributes[xidx].to_f, r.attributes[yidx].to_f)
			end
			
			series_collection.addSeries(series)
		end
	  
		xAxis = org.jfree.chart.axis.NumberAxis.new(xidx.to_s)
		# xAxis.setAutoRangeIncludesZero(false);
		yAxis = org.jfree.chart.axis.NumberAxis.new(yidx.to_s)
		# yAxis.setAutoRangeIncludesZero(false);

		plot = org.jfree.chart.plot.XYPlot.new(series_collection, xAxis, yAxis, nil)

		renderer = org.jfree.chart.renderer.xy.XYLineAndShapeRenderer.new(false, true)
		
		if not svm.nil?
			renderer.setSeriesLinesVisible(0,true)
		end
		
		# renderer.setBaseToolTipGenerator(toolTipGenerator);
		# renderer.setURLGenerator(urlGenerator);
		plot.setRenderer(renderer)
		plot.setOrientation(org.jfree.chart.plot.PlotOrientation::VERTICAL)

		chart = org.jfree.chart.JFreeChart.new("#{xidx} vs. #{yidx}", org.jfree.chart.JFreeChart::DEFAULT_TITLE_FONT, plot, true);
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
		
		org.jfree.chart.ChartUtilities.saveChartAsPNG(java.io.File.new(file), chart, 600, 400)
	end
end