require 'yaml'
require 'open3'
require 'logger'

require 'ec2_bootstrap/version'
require 'ec2_bootstrap/instance'
require 'ec2_bootstrap/ami'

class EC2Bootstrap

	attr_accessor :cloud_config
	attr_accessor :instances
	attr_accessor :dryrun
	attr_accessor :default_image_id

	def initialize(config, dryrun=true, verbose=false)
		@logger = self.new_logger(verbose)
		@cloud_config = config['cloud_config']
		@default_image_id = ami_class.from_config(config['default_ami'], @logger).find_newest_image_id
		@instances = self.make_instances(config['instances'])
		@dryrun = dryrun
	end

	def self.from_config(config, *args)
		self.validate_config(config)

		config['instances'].map! {|i| i.map {|key, value| [key.to_sym, value]}.to_h}

		return self.new(config, *args)
	end

	def self.from_config_file(config_path, *args)
		config = YAML.load(File.read(config_path))
		return self.from_config(config, *args)
	end

	def self.validate_config(config)
		instances = config['instances']
		raise KeyError, "Config file is missing 'instances' key." unless instances
		raise TypeError, "'instances' config must be an array of hashes." unless instances.is_a?(Array) && instances.first.is_a?(Hash)

		if config['default_ami']
			raise TypeError, "'default_ami' config must be a hash." unless config['default_ami'].is_a?(Hash)
		end

		return true
	end

	def new_logger(verbose)
		logger = Logger.new(STDOUT)
		verbose ? logger.level = Logger::DEBUG : logger.level = Logger::INFO
		return logger
	end

	def ami_class
		return AMI
	end

	def make_instances(instances_config)
		additional_args = {logger: @logger, image: @default_image_id}
		return instances_config.map {|i| self.instance_class.new(i.merge(additional_args))}
	end

	def instance_class
		return Instance
	end

	def create_instances
		@logger.info("This was a dry run. No EC2 instances were created.") if @dryrun

		@instances.each do |instance|
			@logger.debug("Instance name: #{instance.name}")

			instance.generate_cloud_config(@cloud_config, @dryrun) if @cloud_config

			knife_shell_command = instance.format_knife_shell_command
			@logger.debug("Knife shell command:\n#{knife_shell_command}")
			
			unless @dryrun
				status = self.shell_out_command(knife_shell_command)
				return status
			end
		end
	end

	def shell_out_command(command)
		STDOUT.sync = true
		Open3::popen2e(command) do |stdin, stdout_and_stderr, wait_thr|
			while (line = stdout_and_stderr.gets) do
				@logger.info(line.strip)
			end
			status = wait_thr.value
			@logger.info("status: #{status}")
			return status
		end
	end
end
