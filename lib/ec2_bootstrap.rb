require 'yaml'
require 'json'
require 'open3'
require 'ec2_bootstrap/version'

class EC2Bootstrap

	CLOUD_CONFIG_PATH = 'cloud_config.txt'

	ADDITIONAL_KNIFE_FLAGS = {
		'no-host-key-verify' => nil,
		'node-name'			 => '',
		'tags'				 => '',
		'user-data'			 => CLOUD_CONFIG_PATH
	}

	def initialize(config_path, dryrun=true)
		@config = YAML.load(File.read(config_path))
		@node_name = @config['nodes'].keys.first
		@node_config = @config['nodes'][@node_name]

		@dryrun = dryrun

		@knife_flags = build_knife_flags()
	end

	def build_knife_flags
		knife_config = @node_config['knife_ec2_flags']
		additional_knife_config = ADDITIONAL_KNIFE_FLAGS.dup
		additional_knife_config['node-name'] = @node_name
		additional_knife_config['tags'] = "Name=#{@node_name}"
		additional_knife_config['json-attribute-file'] = @node_config['json_attributes'] if @node_config['json_attributes']
		return knife_config.merge(additional_knife_config)
	end

	def write_cloud_config
		cloud_config = @config['cloud_config']
		cloud_config['hostname'] = @node_name
		cloud_config['fqdn'] = "#{@node_name}.#{@node_config['domain']}"
		formatted_cloud_config = cloud_config.to_yaml.gsub('---', '#cloud-config')

		if @dryrun
			puts "If this weren't a dry run, I would write the following contents to #{CLOUD_CONFIG_PATH}:"
			puts formatted_cloud_config, "\n"
		else
			File.open(CLOUD_CONFIG_PATH, 'w') {|f| f.write(formatted_cloud_config)}
			puts "Wrote cloud config to #{CLOUD_CONFIG_PATH}."
		end
	end

	def knife_shell_command
		prefix = 'knife ec2 server create '
		knife_flag_array = @knife_flags.map {|key, value| ['--' + key, value]}.flatten.compact
		return prefix + knife_flag_array.join(' ')
	end

	def create_instance
		puts "This was a dry run. No EC2 instances were created.\n\n" if @dryrun

		self.write_cloud_config

		puts 'Knife shell command:', knife_shell_command
		
		unless @dryrun
			stdout, stderr, status = Open3::capture3(knife_shell_command)
			puts "stdout", stdout
			puts "stderr", stderr
			puts "status", status
		end
	end

  # "--security-group-ids #{knife_config_data[:security_group_ids].join(',')}"
  # TODO: make the commas explicit in knife config example.yml
end
