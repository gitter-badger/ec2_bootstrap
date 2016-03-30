require 'yaml'
require 'open3'
require 'logger'
require 'aws-sdk'

require 'ec2_bootstrap/version'
require 'ec2_bootstrap/instance'

class EC2Bootstrap

	DEFAULT_AWS_REGION = 'us-east-1'

	DEFAULT_IMAGE_FILTERS = [
			{name: 'image-type', values: ['machine']},
			{name: 'state', values: ['available']}
		]

	attr_accessor :cloud_config
	attr_accessor :instances
	attr_accessor :dryrun
	attr_accessor :default_image_id

	def initialize(config, dryrun=true, verbose=false)
		@logger = Logger.new(STDOUT)
		verbose ? @logger.level = Logger::DEBUG : @logger.level = Logger::INFO

		@cloud_config = config['cloud_config']
		@default_image_id = config['default_ami'] ? self.find_newest_image_id(config['default_ami']) : nil
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

	def find_newest_image_id(image_search_config)
		image_search_config['filters'] = self.format_filters_from_config(image_search_config['filters']) + DEFAULT_IMAGE_FILTERS
		images = self.fetch_eligible_images(image_search_config)

		newest_image = images.max_by(&:creation_date)
		newest_image_id = newest_image ? newest_image.id : nil

		@logger.error("Couldn't find any AMIs matching your specifications. Can't set a default AMI.") unless newest_image_id
		@logger.info("Using #{newest_image_id} as the default AMI.") if newest_image_id

		return newest_image_id
	end

	def format_filters_from_config(filters_hash)
		filters_array = filters_hash.to_a.map {|filter| {name: filter.first, values: filter.last}}
		return filters_array
	end

	def fetch_eligible_images(image_search_config)
		ENV['AWS_REGION'] = image_search_config.delete('region') || DEFAULT_AWS_REGION
		return Aws::EC2::Resource.new.images(image_search_config)
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
