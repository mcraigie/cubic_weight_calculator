#!/usr/bin/env ruby

require 'net/http'
require 'json'

def load_configuration
  begin
    config = JSON.parse(File.read('./config.json'), symbolize_names: true)
  rescue SystemCallError => e
    abort("Error: Unable to read configuration file\n#{e.message}")
  rescue JSON::ParserError => e
    abort("Error: Unable to parse configuration file\n#{e.message}")
  end

  validate_configuration_presence(config)
  validate_configuration_values(config)

  config
end

def validate_configuration_presence(config)
  required = %i[
    api_host
    categories
    include_sizeless
    conversion_factor_kg_m3
    result_rounding
    result_unit
    starting_page
  ]

  missing = required - config.keys
  abort("Error: Missing configuration options: (#{missing})") unless missing.empty?

  unused = config.keys - required
  abort("Error: Unused configuration options: (#{unused})") unless unused.empty?
end

def validate_configuration_values(config)
  abort('Error: Configuration options cannot be nil') if config.values.include?(nil)

  unless config[:conversion_factor_kg_m3].is_a?(Numeric)
    abort('Error: Conversion factor must be numeric')
  end

  unless config[:result_rounding].is_a?(Integer) && config[:result_rounding] >= 0
    abort('Error: Rounding must be a positive integer')
  end

  abort('Error: Result unit must be "kg" or "g"') unless %w[kg g].include?(config[:result_unit])

  abort('Error: Must specify a category') if config[:categories].empty?
end

def retrieve_page(http, page_path)
  response = http.request(Net::HTTP::Get.new(page_path)).body
  JSON.parse(response, symbolize_names: true)
rescue JSON::ParserError => e
  abort("Error: Unable to parse page\n#{e.message}")
rescue StandardError => e
  # Rescuing StandardError isn't usually a good idea. In this case it is a trade-off between
  # verbosity (since Net::HTTP can throw a very large variety of errors) and the slim chance that
  # something unexpected will occur when retrieving a page that shouldn't also be a trigger to abort
  abort("Error: Unable to retrieve page\n#{e.message}")
end

def filter_products(products)
  categories = CONFIG[:categories]
  filtered = products.select { |product| categories.include?(product[:category]) }
  CONFIG[:include_sizeless] ? filtered : filtered.reject { |product| product[:size].empty? }
end

def cubic_weight(product) # in grams
  size = product[:size]
  size.empty? ? 0 : size.values.reduce(:*) * (CONFIG[:conversion_factor_kg_m3] / 1000.0)
end

def average(array)
  array.sum / array.length.to_f
end

def format_result(average)
  result = case CONFIG[:result_unit]
           when 'g'
             average
           when 'kg'
             average / 1000
           end

  "#{result.round(CONFIG[:result_rounding])}#{CONFIG[:result_unit]}"
end

def search_params
  "#{CONFIG[:categories].join(' & ')} (sizeless: #{CONFIG[:include_sizeless] ? 'in' : 'ex'}cluded)"
end

def display_results(cubic_weights)
  if cubic_weights.empty?
    puts "No products found matching #{search_params}"
  else
    puts "Average Cubic Weight for #{search_params}: #{format_result(average(cubic_weights))}"
  end
end

CONFIG = load_configuration
next_page_path = CONFIG[:starting_page]
cubic_weights = []

# maintain a single connection to the API backend (reduces overhead when making mutliple queries)
Net::HTTP.start(URI(CONFIG[:api_host]).host) do |http|
  while next_page_path
    page = retrieve_page(http, next_page_path)
    next_page_path = page[:next]
    products = filter_products(page[:objects])
    cubic_weights.concat(products.map { |product| cubic_weight(product) })
  end
end

display_results(cubic_weights)
