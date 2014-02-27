require File.expand_path('../config/application', __FILE__)

Rpiflix::Application.initialize!

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::INFO
	
m = Model.where(klass: :Baseline).take
m.handler.train

# connection = ActiveRecord::Base.connection
# connection.add_index(:probes, :customer)


# require 'threadpool'

# pool = ThreadPool.new(4)

# 0.upto(10) { pool.process { sleep 2; puts 'lol' } }

# gets # otherwise the program ends without the pool doing anything