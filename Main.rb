require 'active_record'
require 'csv'

class Employee < ActiveRecord::Base
end

class Machine < ActiveRecord::Base
end

# establish connections to two separate databases
Employee.establish_connection(adapter:  'sqlite3', database: 'employee.db')
Machine.establish_connection (adapter:  'sqlite3', database: 'machine.db' )

# create relations
Employee.connection.drop_table 'employees' if Employee.connection.table_exists?('employees')
Employee.connection.create_table('employees') do |t|
	t.string	:name
	t.string	:address
	t.float		:salary
	t.integer	:plant_number
end

Machine.connection.drop_table 'machines' if Machine.connection.table_exists?('machines')
Machine.connection.create_table('machines') do |t|
	t.integer	:machine_number
	t.string	:my_type		# 'type' is a special Active Record column
	t.integer	:plant_number
end

puts 'populating employee data'
# 100 employees spread over 10 plants, roughly 10 employees per plant
Employee.connection.transaction do
	(1..100).each do |n|
		Employee.create(name: "Mr. #{n}", address: "#{n} Main st.", salary: "%6.2f" % (100_000 * rand), plant_number: 10 * rand)
	end
end

puts 'populating machine data'

my_types = [
	'grinder',
	'sharpener',
	'milling',	###
	'sander',
	'bandsaw',
	'sandblast',
	'drill press',
	'lathe',
	'arbor press',
	'bander',
	'roller',
	'cut-off saw',
	'shears',
	'punch',
	'notcher',
	'brake',
	'3D printing',
	'circular saw',
	'dust collector',
	
	'CNC',
	'jig borer',
	'cutter',
	'broaching',
	'endmill',
	'gear sharper',
	'hacksaw',
	'planer',
	'welder'
]

# 200 machines spread over 10 plants, roughly 20 machines per plant
Machine.connection.transaction do
	(1001..1200).each do |n|
		Machine.create(machine_number: n, my_type: my_types[rand * my_types.size], plant_number: 10 * rand)
	end
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)

#############################################################################################################

# (a) Find all employees at the plant that contains machine number 1130
# find which plant the machine resides in, then locate the corresponding employees
plant = Machine.where(machine_number: 1130).take.plant_number
employees = Employee.where(plant_number: plant).to_a
puts "#{employees.size} employees at a plant that contains machine 1130 (plant: #{plant})"
employees.each do |e|
	puts e.name
end


# (b) Find all employees at plants that contain machines whose type is "milling machine"
# similar to above, but this time we have an array of plant numbers
# luckily Rails supports an array in .where(), turning it into a WHERE ... IN clause
plants = Machine.where(my_type: 'milling').distinct.pluck('plant_number')
employees = Employee.where(plant_number: plants).to_a
puts "#{employees.size} employees at plants that contain milling machines (plants: #{plants})"
employees.each do |e|
	puts e.name
end

#############################################################################################################

# save data to csv, for reference
[Employee, Machine].each do |klass|
	CSV.open(klass.table_name + '.csv', 'w') do |csv|
		csv << klass.attribute_names
		klass.all.each do |r|
			csv << r.attributes.values
		end
	end
end