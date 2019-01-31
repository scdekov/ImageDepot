require 'fileutils'
require 'unirest'

class Depot
  def initialize
    @s3_bucket = Aws::S3::Resource.new.bucket('images-depot')
  end

  def get_links(term, count = 10, width = 200, height = 200)
    serialized_term = serialize_term(term)

    return build_links(serialized_term) if images_exists(serialized_term)

    external_links = fetch_external_links(term, count)
    save_images(external_links, width, height, serialized_term)
  end

  def get_img(term, identifier)
    img_location = "#{term}/#{identifier}"
    images = @s3_bucket.objects(prefix: img_location)

    return nil unless images.count.positive?

    images.first.get.body
  end

  private

  IMAGES_DIR = Rails.root.join('storage', 'images')
  GOOGLE_SEARCH_URL = 'https://www.googleapis.com/customsearch/v1'.freeze
  GOOGLE_CX = Rails.application.credentials[:GOOGLE_CX]
  GOOGLE_API_KEY = Rails.application.credentials[:GOOGLE_API_KEY]

  def fetch_external_links(term, count)
    images_response = Unirest.get(GOOGLE_SEARCH_URL, parameters:{
      'key': GOOGLE_API_KEY,
      'cx': GOOGLE_CX,
      'searchType': 'image',
      'q': term
    })

    return [] unless images_response.code / 100 == 2

    images_response.body['items'][0, count].map { |i| i['link'] }
  end

  def save_images(links, width, height, serialized_term)
    Parallel.each(links) do |link|
      img = MiniMagick::Image.open(link)
      img.resize("#{width}x#{height}")
      img.format('png')
      @s3_bucket.object("#{serialized_term}/#{rand.to_s.reverse[0, 5]}.png")
                .put(body: img.to_blob)
    end

    build_links(serialized_term)
  end

  def build_links(serialized_term)
    @s3_bucket.objects(prefix: serialized_term).map do |obj|
      "#{Rails.configuration.host}/api/links/#{obj.key}"
    end
  end

  def images_exists(serialized_term)
    # this can be improved to check if the number of existing images is enough
    # and probably if the size is the same as requested
    @s3_bucket.objects(prefix: serialized_term).count.positive?
  end

  def serialize_term(term)
    CGI.escape(term.downcase)
  end
end
