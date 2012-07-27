require 'yaml'

module Bellows
  module Util

    DEFAULT_PROJECTS = ['nova', 'glance', 'keystone']
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
        configs = YAML.load_file(config_file) || {}
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

    def self.validate_project(project)
      configs=self.load_configs
      projects = configs['projects']
      if projects.nil? or projects.empty? then
        projects = DEFAULT_PROJECTS
      end
      if not projects.include?(project) then
        puts "ERROR: Please specify a valid project name."
        exit 1
      end
    end

    # If a single project is provided return an array of that.
    # Otherwise return the default projects from the config file or the default
    # project list.
    def self.projects(project=nil)
      if not project.nil?
        validate_project(project)
        return [project]
      end
      configs=self.load_configs
      proj_list = configs['projects']
      if proj_list.nil? or proj_list.empty? then
        proj_list = DEFAULT_PROJECTS
      end
      return proj_list
    end

    def self.test_configs(project=nil)
      configs=load_configs
      test_suite_ids = nil
      config_template_ids = nil
      # per project configs may be specified in the config file
      if not project.nil? and configs[project] then
        test_suite_ids = configs[project]['test_suite_ids'].collect {|x| x.to_s }
        config_template_ids = configs[project]['config_template_ids'].collect {|x| x.to_s }
      else
        # if no configs specified use the configured defaults
        test_suite_ids = configs['test_suite_ids'].collect {|x| x.to_s }
        config_template_ids = configs['config_template_ids'].collect {|x| x.to_s }
      end
      return test_suite_ids, config_template_ids
    end

  end
end
