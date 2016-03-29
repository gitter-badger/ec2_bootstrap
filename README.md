# Ec2Bootstrap

A simple wrapper for the EC2 Knife plugin to automate the creation of new EC2 instances.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ec2_bootstrap'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ec2_bootstrap

## Configuration

This is a simple gem that wraps the functionality of the [EC2 Knife plugin](https://github.com/chef/knife-ec2/blob/master/README.md) and the [aws-sdk gem](https://github.com/aws/aws-sdk-ruby). As a result, there is very little code and a very fussy config file.

### Required Config

Requires AWS credentials in a format compatible with the EC2 Knife plugin.

Also requires a YAML config file that looks like the example `config.example.yml`. The config file must include a top-level `instances` key whose value is an array of hashes. Each individual instance must include the keys `instance_name` and `knife_ec2_flags`, and a `private-ip-address` key nested within `knife_ec2_flags`. Each instance also requires the `image` flag, but if you include a `default_ami` section within your config, `ec2_bootstrap` will set a default AMI so you don't need to define an image for each instance (see "Optional Config" below for more info).

For any `knife_ec2_flags` values that are lists, they need to be formatted as one long string with values separated by commas. Ex: `security-group-ids: sg-12345678,sg-abcdef12`.

### Optional Config

You may also want to include some form of cloud-init config. To do this, you can do one of two things:

1. Include the cloud config's path in a `user-data` key in the `knife_ec2_flags` hash for every instance.
2. Include a top-level `cloud_config` key with the contents you'd like in the cloud config files used for each node. `ec2_bootstrap` will use this to generate separate config files for each node that all include the node's hostname and fqdn. This will be used as the default cloud-init config for any instances that don't have their own defined.

For the `image` flag within an instance's `knife_ec2_flags`, you have two choices:

1. Include the flag for every instance.
2. Include a top-level `default_ami` hash. `ec2_bootstrap` will use the parameters within `default_ami` to search for the most recent available AMI that matches your criteria, then will use that image when as the default for any instances that don't have their own `image` field defined.

You can add any of the options listed in [Amazon's aws-sdk gem docs](http://docs.aws.amazon.com/sdkforruby/api/Aws/EC2/Resource.html#images-instance_method) to search for AMIs through `ec2_bootstrap`. If you don't include a `region` key, `ec2_bootstrap` will default to us-east-1. If you choose to include `filters`, it should be a hash where all values are arrays. All other keys besides `region` and `filters` should also have arrays as values.

## Usage

	$ bundle exec ec2_bootstrap -c CONFIG_FILE [options]

Passing in a config file with `-c` is required.

By default, `ec2_bootstrap` is set to dryrun mode, where `ec2_bootstrap` will
print out what config would be used to create a new EC2 instance without
actually creating the instance.

	$ bundle exec ec2_bootstrap --help
	# help menu
	$ bundle exec ec2_bootstrap -c CONFIG_FILE
	# runs ec2_bootstrap in dryrun mode
	$ bundle exec ec2_bootstrap -c CONFIG_FILE --no-dryrun
	# runs ec2_bootstrap and actually creates a new EC2 instance
	$ bundle exec ec2_bootstrap -c CONFIG_CILE -v
	# runs ec2_bootstrap in verbose mode

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ec2_bootstrap/fork )
2. Install dependencies (`bundle install`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Make your changes.
5. Run the tests and make sure they pass (`bundle exec rspec`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new pull request.
