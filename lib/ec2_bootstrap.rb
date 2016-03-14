require 'yaml'
require 'json'
require 'open3'
require 'ec2_bootstrap/version'
require 'ec2_bootstrap/instance'

class EC2Bootstrap

	def initialize(config_path, dryrun=true)
		config = YAML.load(File.read(config_path))
		@cloud_config = config['cloud_config']

		instances_config = config['instances'].map {|i| i.map {|key, value| [key.to_sym, value]}.to_h}
		@instances = instances_config.map {|n| Instance.new(n)}

		@dryrun = dryrun
	end

	def create_instances
		puts "This was a dry run. No EC2 instances were created.\n\n" if @dryrun

		@instances.each do |instance|
			puts "Instance name: #{instance.name}"

			instance.generate_cloud_config(@cloud_config, @dryrun) if @cloud_config

			knife_shell_command = instance.format_knife_shell_command
			puts 'Knife shell command:', knife_shell_command, "\n"
			
			unless @dryrun
				STDOUT.sync = true
				Open3::popen2e(knife_shell_command) do |stdin, stdout_and_stderr, wait_thr|
					puts "stdout and stderr"
					while (line = stdout_and_stderr.gets) do
						puts line
					end
					status = wait_thr.value
					puts "status", status
				end
			end
		end
	end
end
