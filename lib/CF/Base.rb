module CF	
	class Base
		def initialize(id)
			@modelID = id
			@progress_prev_s = '0'
			@progress_prev_f = 0.0
			@mutex = Mutex.new
		end
		
		def train
				Model.find(@modelID).update(message: '', state: :training, progress: 0)
				train_do
				Model.find(@modelID).update(message: '', state: :trained, progress: 1, rmse: 0)
			rescue Exception => e 
				msg = "error: #{e.class}: #{e.message} at #{e.backtrace.inspect}"
				ActiveRecord::Base.logger.error msg
				Model.find(@modelID).update(state: :error, message: msg, progress: 0)
		end
		
		def reset
				Model.find(@modelID).update(message: '', state: :resetting, progress: 0)
				reset_do
				Model.find(@modelID).update(message: '', state: :reset, progress: 1, rmse: 0)
			rescue Exception => e 
				msg = "error: #{e.class}: #{e.message} at #{e.backtrace.inspect}"
				ActiveRecord::Base.logger.error msg
				Model.find(@modelID).update(state: :error, message: msg, progress: 0)
		end

		def progress(prog)
			@mutex.synchronize {
				# limit to three digits to avoid frequent updates
				prog_s = '%1.3f' % prog
				
				# prevent backwards updates
				if prog_s != @progress_prev_s 
					Model.find(@modelID).update(progress: prog)
					@progress_prev_s = prog_s
					@progress_prev_f = prog
				end
			}
		end
		
		def score
				Model.find(@modelID).update(message: '', state: :scoring, progress: 0)
				score_do
				Model.find(@modelID).update(message: '', state: :scored, progress: 1)
			rescue Exception => e 
				msg = "error: #{e.class}: #{e.message} at #{e.backtrace.inspect}"
				ActiveRecord::Base.logger.error msg
				Model.find(@modelID).update(state: :error, message: msg, progress: 0)
		end
		
		def score_do
			sse = 0.0
			count = Probe.count
			processed = 0
			
			puts 'pruning table'
			Prediction.where(model: @modelID).delete_all
			
			columns = [:model, :customer, :movie, :prediction]
			
			puts 'calculating predictions'
			
			Probe.all.each_slice(100000) do |slice|
				values = []
				
				slice.each do |probe|
					prediction = rate(probe.movie, probe.customer, probe.date)
					error = probe.rating - prediction
					sse += error * error
				
					values << [@modelID, probe.customer, probe.movie, prediction]
				end
			
				puts 'saving predictions'
				Prediction.import(columns, values, :validate => false)	
				
				processed += slice.size
				progress(processed / (1.0 * count))
			end
			
			rmse = Math.sqrt(sse / count)

			Model.find(@modelID).update(rmse: rmse)
		end
	end
end