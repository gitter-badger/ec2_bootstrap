require 'ec2_bootstrap'
require 'rspec'

class EC2BootstrapMock < EC2Bootstrap

	def find_newest_image_id(owner_ids)
		return 'ami-888888888'
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
end

RSpec.configure do |config|
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
end
