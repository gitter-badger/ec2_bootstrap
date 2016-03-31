require_relative 'spec_helper'

describe 'EC2Bootstrap' do

	let(:knife_flags) do
		{
			'image' => 'ami-12345678',
			'private-ip-address' => '255.255.255.255'
		}
	end

	let(:yaml_content) do
		{
			'default_ami' => {
				'region' => 'us-west-1',
				'owners' => ['111111111111']
			},
			'cloud_config' => {
				'manage_etc_hosts' => 'true',
				'bootcmd' => ['do stuff', 'do some more stuff']
			},
			'instances' => [
				{
					'instance_name' => 'cat',
					'knife_ec2_flags' => knife_flags,
					'domain' => 'cats.com'
				},
				{
					'instance_name' => 'mouse',
					'json_attributes_file' => {},
					'knife_ec2_flags' => knife_flags
				},
				{
					'instance_name' => 'whale',
					'knife_ec2_flags' => knife_flags
				}
			]
		}
	end

	context 'loading from the yaml config' do

		it "raises a KeyError if the yaml content lacks an 'instances' key" do
			yaml = yaml_content.reject {|k,v| k == 'instances'}

			expect {EC2BootstrapMock.from_config(yaml, false)}.to raise_error(KeyError)
		end

		it "raises a TypeError if the 'instances' value is not an array of hashes" do
			yaml = yaml_content.merge({'instances' => ['a thing', 'another thing']})

			expect {EC2BootstrapMock.from_config(yaml, false)}.to raise_error(TypeError)
		end

		it "raises a TypeError if 'default_ami' exists but is not a hash" do
			yaml = yaml_content.merge({'default_ami' => ['an', 'array']})

			expect {EC2BootstrapMock.from_config(yaml, false)}.to raise_error(TypeError)
		end

		it 'loads successfully if the yaml content is properly formatted' do
			bootstrap = EC2BootstrapMock.from_config(yaml_content, false)

			expect(bootstrap.cloud_config).to eq(yaml_content['cloud_config'])
			expect(bootstrap.instances_config).to eq(yaml_content['instances'])
			expect(bootstrap.default_ami_config).to eq(yaml_content['default_ami'])
			expect(bootstrap.dryrun).to be_falsey
		end

	end

	context 'shelling out knife EC2 command' do

		it "doesn't shell out if it's a dryrun" do
			bootstrap = EC2BootstrapMock.from_config(yaml_content, true)

			expect(bootstrap).to_not receive(:shell_out_command)
			bootstrap.create_instances
		end

		it "shells out if it's not a dryrun" do
			bootstrap = EC2BootstrapMock.from_config(yaml_content, false)

			expect(bootstrap).to receive(:shell_out_command)
			bootstrap.create_instances
		end
	end

end
