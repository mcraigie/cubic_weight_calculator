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