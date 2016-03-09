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
Also requires either a) a base config file named `base.yml` to exist in the
working directory, or b) a path to a base config file passed in using the `-b`
flag.

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
	$ bundle exec bin/ec2_bootstrap -c CONFIG_FILE -b BASE_CONFIG
	# runs ec2_bootstrap using BASE_CONFIG as the base config instead of the
	# default `base.yml`

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ec2_bootstrap/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
