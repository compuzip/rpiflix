class Stat < ActiveRecord::Base
	serialize :data, Hash
end