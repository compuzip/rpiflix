require File.expand_path('../config/application', __FILE__)

Rpiflix::Application.initialize!

ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActiveRecord::Base.logger.level = Logger::INFO
	
m = Model.where(klass: :Baseline).take
m.handler.train

# connection = ActiveRecord::Base.connection
# connection.add_index(:probes, :customer)


