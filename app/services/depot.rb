require 'fileutils'
require 'unirest'

module Depot
  extend self

  def get_links(term, count = 10, width = 200, height = 200)
    dir_name = serialize_term(term)
    dir_path = IMAGES_DIR.join(dir_name)

    return build_links(dir_name, dir_path) if images_exists(dir_path)

    external_links = fetch_external_links(term, count)
    save_images(external_links, width, height, dir_name, dir_path)
  end

  def get_img_path(term)
    term, ix = term.split(FILENAME_SEPARATOR) # TODO: validate
    path = IMAGES_DIR.join(term, "#{ix}.png").to_s
    File.exist?(path) ? path : nil
  end

  private

  IMAGES_DIR = Rails.root.join('storage', 'images')
  FILENAME_SEPARATOR = '-'.freeze
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

  def save_images(links, width, height, dir_name, dir_path)
    FileUtils.mkdir_p(dir_path)

    Parallel.each(links) do |link|
      img = MiniMagick::Image.open(link)
      img.resize("#{width}x#{height}")
      img.format('png')
      img.write("#{dir_path}/#{rand.to_s.reverse[0, 5]}.png")
    end

    build_links(dir_name, dir_path)
  end

  def build_links(dir_name, dir_path)
    Dir.entries(dir_path)
       .reject { |f| File.directory? f }
       .map do |file|
         "#{Rails.configuration.host}/api/links/#{dir_name}#{FILENAME_SEPARATOR}#{file}"
       end
  end

  def images_exists(dir_path)
    # this can be improved to check if the number of existing images is enough
    # and probably if the size is the same as requested
    File.directory? dir_path
  end

  def serialize_term(term)
    CGI.escape(term.downcase)
  end
end
