require 'json'

class EC2Bootstrap
	class Instance

		attr_accessor :name
		attr_accessor :knife_ec2_flags

		def initialize(instance_name:, knife_ec2_flags:, logger:, domain: nil, json_attributes_file:nil)
			@name = instance_name
			@json_attributes_file = json_attributes_file
			@knife_ec2_flags = build_knife_ec2_flags_hash(knife_ec2_flags)
			@logger = logger
			@domain = domain
		end

		def build_knife_ec2_flags_hash(knife_ec2_flags)
			knife_ec2_flags['json-attributes'] = "'#{self.load_json_attributes(@json_attributes_file)}'" if @json_attributes_file

			additional_knife_flags = {
				'node-name' => @name,
				'tags' => "Name=#{@name}"
			}

			return knife_ec2_flags.merge(additional_knife_flags)
		end

		# Load the JSON and then dump it back out to ensure it's valid JSON.
		# Also makes the JSON easier to read when printing out the command in
		# verbose mode by removing all newlines.
		def load_json_attributes(file_path)
			return JSON.dump(JSON.load(File.read(file_path)))
		end

		def format_knife_shell_command
			prefix = 'knife ec2 server create '
			knife_flag_array = @knife_ec2_flags.map {|key, value| ['--' + key, value]}.flatten.compact
			return prefix + knife_flag_array.join(' ')
		end

		def generate_cloud_config(cloud_config, dryrun)
			cloud_config['hostname'] = @name
			cloud_config['fqdn'] = "#{@name}.#{@domain}" if @domain

			formatted_cloud_config = cloud_config.to_yaml.gsub('---', '#cloud-config')
			cloud_config_path = "cloud_config_#{@name}.txt"

			if dryrun
				msg = "If this weren't a dry run, I would write the following contents to #{cloud_config_path}:\n#{formatted_cloud_config}"
				@logger.debug(msg)
			else
				self.write_cloud_config_to_file(cloud_config_path, formatted_cloud_config)
				@logger.debug("Wrote cloud config to #{cloud_config_path}.")
			end

			@knife_ec2_flags['user-data'] = cloud_config_path
		end

		def write_cloud_config_to_file(path, contents)
			File.open(path, 'w') {|f| f.write(contents)}
		end

	end
end