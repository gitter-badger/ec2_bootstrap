require 'ec2_bootstrap'
require 'rspec'

class EC2BootstrapMock < EC2Bootstrap

	def self.load_config_from_yaml(config)
		return config
	end

	def make_instances(instances_config)
		return instances_config.map {|i| InstanceMock.new(i)}
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

	end

end

RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
end
