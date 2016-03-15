require 'json'

class EC2Bootstrap
	class Instance

		attr_accessor :name
		attr_accessor :knife_ec2_flags

		def initialize(instance_name:, knife_ec2_flags:, logger:, domain: nil)
			@name = instance_name
			@domain = domain
			@logger = logger

			additional_knife_flags = {
				'node-name' => @name,
				'tags' => "Name=#{@name}"
			}

			@knife_ec2_flags = knife_ec2_flags.merge(additional_knife_flags)
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