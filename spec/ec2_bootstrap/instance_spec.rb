require_relative '../spec_helper'

describe 'EC2Bootstrap::Instance' do

	let(:knife_flags_hash) do
		{
			'availability-zone' => 'us-east-1a',
			'environment' => 'production',
			'flavor' => 'm4.large',
			'private-ip-address' => '255.255.255.255'
		}
	end

	let(:logger) do
		logger = Logger.new(STDOUT)
		logger.level = Logger::WARN
		logger
	end

	let(:default_image) do
		'ami-11111111'
	end

	let(:instance_args) do
		{
			instance_name: 'pumpkin',
			domain: 'chocolate.muffins.com',
			knife_ec2_flags: knife_flags_hash,
			logger: logger,
			image: default_image,
			dryrun: true
		}
	end

	context 'picking an image' do

		it "uses the default AMI if it doesn't have one set" do
			instance = EC2Bootstrap::InstanceMock.new(instance_args)
			expect(instance.knife_ec2_flags['image']).to eq(default_image)
		end

		it "doesn't override an existing image flag with the default" do
			image = 'ami-12345678'
			knife_flags_hash_with_image_flag = knife_flags_hash.merge({'image' => image})
			instance_args_with_image_flag = instance_args.merge({knife_ec2_flags: knife_flags_hash_with_image_flag})
			instance = EC2Bootstrap::InstanceMock.new(instance_args_with_image_flag)
			expect(instance.knife_ec2_flags['image']).to eq(image)
		end

		it "raises a KeyError if there is no image" do
			instance_args_without_default_image = instance_args.reject {|k,v| k == :image}
			expect {EC2Bootstrap::InstanceMock.new(instance_args_without_default_image)}.to raise_error(KeyError)
		end

	end

	context 'generating cloud config' do

		let(:default_cloud_config) do
			{
				'manage_etc_hosts': 'true',
				'bootcmd': ['do stuff', 'do some more stuff']
			}
		end

		it "generates a cloud config file if one isn't set and default cloud config exists" do
			instance = EC2Bootstrap::InstanceMock.new(instance_args.merge({cloud_config: default_cloud_config}))
			expect(instance.knife_ec2_flags['user-data']).to be_a(String)
		end

		it "doesn't override existing cloud config with the default" do
			cloud_init_file = 'my_custom_cloud_config.txt'
			knife_flags_hash_with_user_data_flag = knife_flags_hash.merge({'user-data' => cloud_init_file})
			instance_args_with_user_data_flag = instance_args.merge({knife_ec2_flags: knife_flags_hash_with_user_data_flag, cloud_config: default_cloud_config})
			instance = EC2Bootstrap::InstanceMock.new(instance_args_with_user_data_flag)
			expect(instance.knife_ec2_flags['user-data']).to eq(cloud_init_file)
		end

	end

	it 'properly formats the knife shell command' do
		knife_command = 'knife ec2 server create --availability-zone us-east-1a --environment production --flavor m4.large'

		instance = EC2Bootstrap::InstanceMock.new(instance_args)
		expect(instance.format_knife_shell_command).to include(knife_command)
	end

end
