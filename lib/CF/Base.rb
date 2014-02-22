module CF	
	class Base
		def initialize(id)
			@modelID = id
		end
		
		def enqueue(job)
			Model.find(@modelID).update(state: :enqueued)
		end
		
		
		def before(job)
			case job.payload_object.method_name.to_s
			when "train"
				Model.find(@modelID).update(state: :training)
			when "reset"
				Model.find(@modelID).update(state: :resetting)
			else
				Model.find(@modelID).update(state: :UNKNOWN)
			end
		end

		def after(job)
			case job.payload_object.method_name.to_s
			when "train"
				Model.find(@modelID).update(state: :trained)
			when "reset"
				Model.find(@modelID).update(state: :reset)
			else
				Model.find(@modelID).update(state: :UNKNOWN)
			end
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