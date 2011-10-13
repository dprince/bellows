require 'yaml'
require 'socket'

module Bellows
  module Util

    @@configs=nil

    def self.load_configs

    return @@configs if not @@configs.nil?

    config_file=ENV['BELLOWS_CONFIG_FILE']
    if config_file.nil? then

      config_file=ENV['HOME']+File::SEPARATOR+".bellows.conf"
      if not File.exists?(config_file) then
        config_file="/etc/bellows.conf"
      end

    end

    if File.exists?(config_file) then
      configs=YAML.load_file(config_file)
      raise_if_nil_or_empty(configs, "smokestack_url")
      raise_if_nil_or_empty(configs, "smokestack_username")
      raise_if_nil_or_empty(configs, "smokestack_password")
      @@configs=configs
    else
      raise "Failed to load bellows config file. Please configure /etc/bellows.conf or create a .bellows.conf config file in your HOME directory."
    end

    @@configs

    end

    def self.raise_if_nil_or_empty(options, key)
      if not options or options[key].nil? or options[key].empty? then
        raise "Please specify a valid #{key.to_s} parameter."
      end
    end

    def self.short_spec(refspec)
      refspec.sub(/\/[^\/]*$/, "")
    end

  end
end
