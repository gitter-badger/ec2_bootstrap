require 'yaml'
require 'json'
require 'open3'
require 'ec2_bootstrap/version'
require 'ec2_bootstrap/instance'

class EC2Bootstrap

	attr_accessor :cloud_config
	attr_accessor :instances
	attr_accessor :dryrun

	def initialize(config, dryrun=true)
		@cloud_config = config['cloud_config']
		@instances = self.make_instances(config['instances'])
		@dryrun = dryrun
	end

	def self.from_config(config_path, dryrun)
		config = self.load_config_from_yaml(config_path)

		instances = config['instances']
		raise KeyError, "Config file is missing 'instances' key." unless instances
		raise TypeError, "'instances' config must be an array of hashes." unless instances.is_a?(Array) && instances.first.is_a?(Hash)
		config['instances'] = instances.map {|i| i.map {|key, value| [key.to_sym, value]}.to_h}

		return self.new(config, dryrun)
	end

	def self.load_config_from_yaml(config_path)
		return YAML.load(File.read(config_path))
	end

	def make_instances(instances_config)
		return instances_config.map {|i| Instance.new(i)}
	end

	def create_instances
		puts "This was a dry run. No EC2 instances were created.\n\n" if @dryrun

		@instances.each do |instance|
			puts "Instance name: #{instance.name}"

			instance.generate_cloud_config(@cloud_config, @dryrun) if @cloud_config

			knife_shell_command = instance.format_knife_shell_command
			puts 'Knife shell command:', knife_shell_command, "\n"
			
			unless @dryrun
				status = self.shell_out_command(knife_shell_command)
				return status
			end
		end
	end

	def shell_out_command(command)
		STDOUT.sync = true
		Open3::popen2e(command) do |stdin, stdout_and_stderr, wait_thr|
			puts "stdout and stderr"
			while (line = stdout_and_stderr.gets) do
				puts line
			end
			status = wait_thr.value
			return status
		end
	end
end
