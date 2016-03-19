require 'yaml'
require 'open3'
require 'logger'

require 'ec2_bootstrap/version'
require 'ec2_bootstrap/instance'

class EC2Bootstrap

	DEFAULT_AWS_REGION = 'us-east-1'

	attr_accessor :cloud_config
	attr_accessor :instances
	attr_accessor :dryrun

	def initialize(config, dryrun=true, verbose=false)
		@logger = Logger.new(STDOUT)
		verbose ? @logger.level = Logger::DEBUG : @logger.level = Logger::INFO

		@cloud_config = config['cloud_config']
		@aws_config = config['aws_config']
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

		self.from_config(config, *args)
	end

	def self.validate_config(config)
		instances = config['instances']
		raise KeyError, "Config file is missing 'instances' key." unless instances
		raise TypeError, "'instances' config must be an array of hashes." unless instances.is_a?(Array) && instances.first.is_a?(Hash)

		if @aws_config
			raise KeyError, "AWS config is missing required 'owner_ids' key." unless @aws_config['owner_ids']
		end

		return true
	end

	def find_newest_image_id(owner_ids)
		ENV['AWS_REGION'] = @aws_config['region'] || DEFAULT_AWS_REGION

		filters = [
			{name: 'image-type', values: ['machine']},
			{name: 'owner-id', values: owner_ids},
			{name: 'state', values: ['available']}
		]

		images = Aws::EC2::Resource.new.images({filters: filters})
		newest_image = images.max_by {|i| i.creation_date}
		return newest_image.id
	end

	def make_instances(instances_config)
		additional_args = {logger: @logger}
		additional_args[:image] = self.find_newest_image_id(@aws_config['owner_ids']) if @aws_config

		return instances_config.map {|i| self.instance_class.new(i.merge(additional_args))}
	end

	def instance_class
		return Instance
	end

	def create_instances
		@logger.debug("This was a dry run. No EC2 instances were created.") if @dryrun

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
