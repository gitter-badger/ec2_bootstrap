require 'json'

class EC2Bootstrap
	class Instance

		REQUIRED_KNIFE_EC2_FLAGS = ['image', 'private-ip-address']

		attr_accessor :name
		attr_accessor :knife_ec2_flags

		def initialize(instance_name:, knife_ec2_flags:, logger:, dryrun:, domain: nil, json_attributes_file:nil, image: nil, cloud_config: nil)
			@name = instance_name
			@logger = logger

			@logger.debug("Instance name: #{@name}")

			@dryrun = dryrun
			@json_attributes_file = json_attributes_file
			@image = image
			@domain = domain

			@knife_ec2_flags = build_knife_ec2_flags_hash(knife_ec2_flags, cloud_config)
		end

		def build_knife_ec2_flags_hash(knife_ec2_flags, cloud_config)
			knife_ec2_flags['json-attributes'] = "'#{self.load_json_attributes(@json_attributes_file)}'" if @json_attributes_file and not knife_ec2_flags['json-attributes']
			knife_ec2_flags['user-data'] = self.generate_cloud_init(cloud_config) if cloud_config and not knife_ec2_flags['user-data']
			knife_ec2_flags['image'] = @image unless knife_ec2_flags['image']

			additional_knife_flags = {
				'node-name' => @name,
				'tags' => "Name=#{@name}"
			}

			knife_flags_hash = knife_ec2_flags.merge(additional_knife_flags)

			self.validate_knife_flags(knife_flags_hash)

			return knife_flags_hash
		end

		# Load the JSON and then dump it back out to ensure it's valid JSON.
		# Also makes the JSON easier to read when printing out the command in
		# verbose mode by removing all newlines.
		def load_json_attributes(file_path)
			return JSON.dump(JSON.load(File.read(file_path)))
		end

		# Ensure that all REQUIRED_EC2_FLAGS have values other than nil.
		def validate_knife_flags(given_knife_flags)
			missing_flags = REQUIRED_KNIFE_EC2_FLAGS.select {|flag| given_knife_flags[flag].nil? }
			raise KeyError, "Instance #{@name} is missing one or more required flags. Missing flags are: #{missing_flags}." unless missing_flags.empty?
			return true
		end

		def format_knife_shell_command
			prefix = 'knife ec2 server create '
			knife_flag_array = @knife_ec2_flags.map {|key, value| ['--' + key, value]}.flatten.compact
			return prefix + knife_flag_array.join(' ')
		end

		def generate_cloud_init(cloud_config)
			cloud_config['hostname'] = @name
			cloud_config['fqdn'] = "#{@name}.#{@domain}" if @domain

			formatted_cloud_config = cloud_config.to_yaml.gsub('---', '#cloud-config')
			cloud_config_path = "cloud_config_#{@name}.txt"

			if @dryrun
				msg = "If this weren't a dry run, I would write the following contents to #{cloud_config_path}:\n#{formatted_cloud_config}"
				@logger.info(msg)
			else
				self.write_cloud_config_to_file(cloud_config_path, formatted_cloud_config)
				@logger.info("Wrote cloud config to #{cloud_config_path}.")
			end

			return cloud_config_path
		end

		def write_cloud_config_to_file(path, contents)
			File.open(path, 'w') {|f| f.write(contents)}
		end

	end
end