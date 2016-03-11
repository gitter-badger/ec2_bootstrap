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

Requires AWS credentials in a format compatible with the [EC2 Knife plugin](https://github.com/chef/knife-ec2/blob/master/README.md).

Also requires a YAML config file that looks like the example `config.example.yml`. The config file must include a top-level `nodes` key whose value is an array of hashes. Each node must include the keys `node_name` and `knife_ec2_flags`.

You may also want to include some form of cloud-init config. To do this, you can do one of two things:

1. Include a top-level `cloud_config` key with the contents you'd like in the cloud config files used for each node, and ec2_bootstrap will generate separate config files for each node that all include the node's hostname and fqdn.
2. If you'd prefer to write your own cloud config files, you can include the cloud config's path in a `user-data` key in the node's `knife_ec2_flags` hash.

For any `knife_EC2_flags` values that are lists, they need to be formatted as one long string with values separated by commas. Ex: `security-group-ids: sg-12345678,sg-abcdef12`.

## Usage

	$ bundle exec bin/ec2_bootstrap -c CONFIG_FILE [options]

Passing in a config file with `-c` is required.

By default, `ec2_bootstrap` is set to dryrun mode, where `ec2_bootstrap` will
print out what config would be used to create a new EC2 instance without
actually creating the instance.

	$ bundle exec bin/ec2_bootstrap --help
	# help menu
	$ bundle exec bin/ec2_bootstrap -c CONFIG_FILE
	# runs ec2_bootstrap in dryrun mode
	$ bundle exec bin/ec2_bootstrap -c CONFIG_FILE --no-dryrun
	# runs ec2_bootstrap and actually creates a new EC2 instance

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ec2_bootstrap/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
