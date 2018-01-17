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