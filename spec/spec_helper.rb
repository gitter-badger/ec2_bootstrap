require 'ec2_bootstrap'
require 'rspec'

class EC2BootstrapMock < EC2Bootstrap

	def new_logger(verbose)
		logger = Logger.new(STDOUT)
		logger.level = Logger::ERROR
		return logger
	end

	def ami_class
		return AMIMock
	end

	def instance_class
		return InstanceMock
	end

	def shell_out_command(command)
		return 0
	end

end

class EC2Bootstrap
	class InstanceMock < Instance

		def write_cloud_config_to_file(path, content)
			return content.bytesize
		end

		def load_json_attributes(json)
			return json
		end

	end

	class AMIMock < AMI

		def fetch_eligible_images
			ids = ['ami-01234567', 'ami-abcdef12', 'ami-87654321']
			return ids.map {|id| Struct::AmazonAMI.new(id, Time.now.to_s)}
		end

	end
end

RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.before(:suite) do
		Struct.new('AmazonAMI', :id, :creation_date)
	end
end
