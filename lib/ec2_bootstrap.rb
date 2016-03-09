require 'yaml'
require 'open3'
require 'ec2_bootstrap/version'

class EC2Bootstrap

	DEFAULT_CONFIG_PATH = 'base.yml'

	CLOUD_CONFIG_PATH = 'cloud_config.txt'

	ADDITIONAL_KNIFE_FLAGS = {
		'no-host-key-verify' => nil,
		'node-name'			 => '',
		'tags'				 => '',
		'user-data'			 => CLOUD_CONFIG_PATH
	}

	def initialize(custom_config_path, dryrun=true, default_config=nil)
		@default_config = YAML.load(File.read(default_config || DEFAULT_CONFIG_PATH))
		@custom_config = YAML.load(File.read(custom_config_path))

		@dryrun = dryrun

		@node_name = @custom_config['name']
		@domain = @custom_config['domain']

		@knife_config = build_knife_config
	end

	def build_knife_config
		knife_config = @default_config['knife_ec2_flags'].merge(@custom_config['knife_ec2_flags'])
		additional_knife_config = ADDITIONAL_KNIFE_FLAGS.dup
		additional_knife_config['node-name'] = @node_name
		additional_knife_config['tags'] = "Name=#{@node_name}"
		return knife_config.merge(additional_knife_config)
	end

	def write_cloud_config
		cloud_config = @default_config['cloud_config']
		cloud_config['hostname'] = @node_name
		cloud_config['fqdn'] = "#{@node_name}.#{@domain}"
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
		knife_flag_array = @knife_config.map {|key, value| ['--' + key, value]}.flatten.compact
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
