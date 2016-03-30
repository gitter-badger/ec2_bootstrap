require 'aws-sdk'

class EC2Bootstrap
	class AMI

		DEFAULT_AWS_REGION = 'us-east-1'

		DEFAULT_IMAGE_FILTERS = [
				{name: 'image-type', values: ['machine']},
				{name: 'state', values: ['available']}
		]

		def initialize(config, logger)
			@region = config.delete('region') || DEFAULT_AWS_REGION
			@search_options = config
			@logger = logger
		end

		def self.from_config(config, logger)
			if config['filters']
				config['filters'] = config['filters'].to_a.map {|filter| {name: filter.first, values: filter.last}}
				config['filters'] += DEFAULT_IMAGE_FILTERS
			end
			return self.new(config, logger)
		end

		def find_newest_image_id
			images = self.fetch_eligible_images

			newest_image = images.max_by{|i| Time.parse(i.creation_date)}
			newest_image_id = newest_image ? newest_image.id : nil

			@logger.error("Couldn't find any AMIs matching your specifications. Can't set a default AMI.") unless newest_image_id
			@logger.info("Using #{newest_image_id} as the default AMI.") if newest_image_id

			return newest_image_id
		end

		def fetch_eligible_images
			ENV['AWS_REGION'] = @region
			return Aws::EC2::Resource.new.images(@search_options)
		end

	end
end
