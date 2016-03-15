require_relative '../spec_helper'

describe 'EC2Bootstrap::Instance' do

	let(:knife_flags_hash) do
		{
			'availability-zone' => 'us-east-1a',
			'environment' => 'production',
			'flavor' => 'm4.large'
		}
	end

	let(:instance) do
		EC2Bootstrap::InstanceMock.new(
			instance_name: 'pumpkin',
			domain: 'chocolate.muffins.com',
			knife_ec2_flags: knife_flags_hash
		)
	end

	it 'properly formats the knife shell command' do
		knife_command = 'knife ec2 server create --availability-zone us-east-1a --environment production --flavor m4.large'

		expect(instance.format_knife_shell_command).to include(knife_command)
	end

	it 'can generate its own cloud config' do
		cloud_config = {
			'manage_etc_hosts': 'true',
			'bootcmd': ['do stuff', 'do some more stuff']
		}

		expect(instance.generate_cloud_config(cloud_config, false)).to eq("cloud_config_#{instance.name}.txt")
	end

end
