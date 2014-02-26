module CF	
	class Base
		def initialize(id)
			@modelID = id
			@progress_prev_s = '0'
			@progress_prev_f = 0.0
			@mutex = Mutex.new
		end
		
		def enqueue(job)
			Model.find(@modelID).update(state: :queued)
			Model.find(@modelID).update(progress: 0)
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
			sse = 0.0
			count = 0
		
			Probe.all.each do |r|
				error = r.rating - rate(r.movie, r.customer, r.date)
				sse += error * error
				count += 1
			end
		
			return Math.sqrt(sse / count)
		end
		
		# def success(job)
			# record_stat 'newsletter_job/success'
		# end

		# def error(job, exception)
			# Airbrake.notify(exception)
		# end

		# def failure(job)
			# page_sysadmin_in_the_middle_of_the_night
		# end
		
		# def train
			# Model.find(@modelID).update(state: :training)
			# train_do
			# Model.find(@modelID).update(state: :trained)
		# end
	
		# def reset
			# Model.find(@modelID).update(state: :resetting)
			# reset_do
			# Model.find(@modelID).update(state: :reset)
		# end
	end
end