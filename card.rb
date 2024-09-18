require 'mini_magick'
require 'httparty'
require 'open-uri'
require 'fileutils'
require 'json'


class Card
  attr_reader :id, :name, :set, :number, :version, :image_url, :image_path, :raw_data

  CACHE_DIR = 'cache/cards/sets/%{set}/%{number}/'

  def initialize(set: nil, number: nil, id: nil)
    @set = set
    @number = number
    @id = id
  end

  def self.fetch(set: nil, number: nil, id: nil)
    identifier = id ? { id: } : { set:, number:}
    card = new(**identifier)
    card.cache! unless card.cached?
    card.load!
    card
  end

  def load!
    @raw_data = data = cache

    @set = data.dig 'set', 'code'
    @number = data['collector_number']
    @id = data['id']
    @name = data['name']
    @version = data['version']
    @image_url = data['image_uris']['digital']['large']
    @image_path = image_cache_file_path
  end

  def cache!
    response = HTTParty.get(lorecast_api_url)
    data = response.code >= 400 ? {} : response.parsed_response

    if response.code >= 400
      puts "Failed to fetch data for card ##{number}: #{response.message}"
    else
      FileUtils.mkdir_p(cache_dir_path) unless File.directory?(cache_dir_path)

      File.open(cache_file_path, 'w') do |file|
        file.write(JSON.pretty_generate(response.parsed_response))
      end

      image_url = data.dig 'image_uris', 'digital', 'large'
      puts "Downloading from #{image_url}"
      File.open(image_cache_file_path('avif'), 'wb') do |file|
        file.write(URI.open(image_url).read)
      end

      MiniMagick::Tool::Convert.new do |convert|
        convert << image_cache_file_path('avif')
        convert << image_cache_file_path('jpg')
      end

    end
  end

  def cached?
    return false if cache_file_path.nil?

    cache.key? 'id'
  end

  def cache
    return {} unless File.directory? cache_dir_path
    return {} unless File.exist? cache_file_path

    JSON.parse(File.read(cache_file_path))
  end

  def cache_dir_path
    return if set.nil? || number.nil?

    CACHE_DIR % { set: set, number: number }
  end

  private

  def cache_file_path
    return if cache_dir_path.nil?

    File.join(cache_dir_path, 'data.json')
  end

  def image_cache_file_path(extension = 'jpg')
    return if cache_dir_path.nil?

    File.join(cache_dir_path, "image.#{extension}")
  end

  def lorecast_api_url
    "https://api.lorcast.com/v0/cards/#{set}/#{number}"
  end
end

# card = Card.fetch set: '2', number: '43'
