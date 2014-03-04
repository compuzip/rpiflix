module CF	
	class Base
		def initialize(id)
			@modelID = id
			@progress_prev_s = '0'
			@progress_prev_f = 0.0
			@mutex = Mutex.new
		end
		
		def train
			Model.find(@modelID).update(state: :training)
			Model.find(@modelID).update(progress: 0)
			train_do
			Model.find(@modelID).update(state: :trained)
			Model.find(@modelID).update(progress: 1)
		end
		
		def reset
			Model.find(@modelID).update(state: :resetting)
			Model.find(@modelID).update(progress: 0)
			reset_do
			Model.find(@modelID).update(state: :reset)
			Model.find(@modelID).update(progress: 1)
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
			Model.find(@modelID).update(state: :scoring)
			Model.find(@modelID).update(progress: 0)
			
			sse = 0.0
			count = 0
		
			Prediction.where(model: @modelID).delete_all
		
			Probe.connection.transaction do
				Probe.all.each do |r|
					prediction = rate(r.movie, r.customer, r.date)
					error = r.rating - prediction
					sse += error * error
					count += 1
					
					Prediction.create(:model => @modelID, :customer => r.customer, :movie => r.movie, :prediction => prediction)
				end
			end
		
			Model.find(@modelID).update(state: :scored)
			Model.find(@modelID).update(progress: 1)
			
			return Math.sqrt(sse / count)
		end
	end
end