require 'fileutils'
require 'unirest'

class Depot
  def initialize(term)
    @term = term
  end

  def get_links(count, width, height)
    save_images(count, width, height) unless images_exists
    build_links
  end

  def spelling_correction
    term_data.fetch('spelling', {}).fetch('correctedQuery', '')
  end

  def get_img(identifier)
    images = s3_bucket.objects(prefix: "#{serialized_term}/#{identifier}")
    return nil unless images.count.positive?

    images.first.get.body
  end

  private

  IMAGES_DIR = Rails.root.join('storage', 'images')
  GOOGLE_SEARCH_URL = 'https://www.googleapis.com/customsearch/v1'.freeze
  GOOGLE_CX = Rails.application.credentials[:GOOGLE_CX]
  GOOGLE_API_KEY = Rails.application.credentials[:GOOGLE_API_KEY]

  def term_data
    @term_data ||= Unirest.get(GOOGLE_SEARCH_URL, parameters: {
      'key': GOOGLE_API_KEY,
      'cx': GOOGLE_CX,
      'searchType': 'image',
      'q': @term
    })

    @term_data.code / 100 == 2 ? @term_data.body : {}
  end

  def fetch_external_links(count)
    term_data.fetch('items', [])[0, count].map { |i| i['link'] }
  end

  def save_images(count, width, height)
    Parallel.each(fetch_external_links(count)) do |link|
      img = MiniMagick::Image.open(link)
      img.resize("#{width}x#{height}")
      img.format('png')
      s3_bucket.object("#{serialized_term}/#{rand.to_s.reverse[0, 5]}.png")
               .put(body: img.to_blob)
    end
  end

  def build_links
    s3_bucket.objects(prefix: serialized_term).map do |obj|
      "#{Rails.configuration.host}/api/links/#{obj.key}"
    end
  end

  def images_exists
    # this can be improved to check if the number of existing images is enough
    # and probably if the size is the same as requested
    s3_bucket.objects(prefix: serialized_term).count.positive?
  end

  def serialized_term
    @serialized_term ||= CGI.escape(@term.downcase)
  end

  def s3_bucket
    @s3_bucket ||= Aws::S3::Resource.new.bucket('images-depot')
  end
end
