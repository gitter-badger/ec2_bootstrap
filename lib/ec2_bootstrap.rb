require 'yaml'
require 'json'
require 'open3'
require 'ec2_bootstrap/version'

class EC2Bootstrap

	def initialize(config_path, dryrun=true)
		@config = YAML.load(File.read(config_path))
		@nodes = @config['nodes']

		@dryrun = dryrun
	end

	def build_knife_config(node)
		knife_config = node['knife_ec2_flags']
		node_name = node['node_name']

		additional_knife_config = {
			'node-name' => node_name,
			'tags' => "Name=#{node_name}",
		}

		node['knife_ec2_flags'] = knife_config.merge(additional_knife_config)
		return node
	end

	def format_knife_shell_command(knife_flags)
		prefix = 'knife ec2 server create '
		knife_flag_array = knife_flags.map {|key, value| ['--' + key, value]}.flatten.compact
		return prefix + knife_flag_array.join(' ')
	end

	def generate_cloud_config(node)
		cloud_config = @config['cloud_config']
		node_name = node['node_name']

		cloud_config['hostname'] = node_name
		cloud_config['fqdn'] = "#{node_name}.#{node['domain']}"

		formatted_cloud_config = cloud_config.to_yaml.gsub('---', '#cloud-config')
		cloud_config_path = "cloud_config_#{node_name}.txt"

		if @dryrun
			puts "If this weren't a dry run, I would write the following contents to #{cloud_config_path}:"
			puts formatted_cloud_config, "\n"
		else
			File.open(cloud_config_path, 'w') {|f| f.write(formatted_cloud_config)}
			puts "Wrote cloud config to #{cloud_config_path}."
		end

		node['knife_ec2_flags']['user-data'] = cloud_config_path
		return node
	end

	def create_instances
		puts "This was a dry run. No EC2 instances were created.\n\n" if @dryrun

		@nodes.each do |node|
			puts "Node name: #{node['node_name']}"

			node = self.build_knife_config(node)

			node = self.generate_cloud_config(node) if @config['cloud_config']

			knife_shell_command = self.format_knife_shell_command(node['knife_ec2_flags'])
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
