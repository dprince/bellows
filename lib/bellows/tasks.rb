require 'json'
require 'bellows/http'
require 'bellows/util'
require 'bellows/gerrit'
require 'bellows/smoke_stack'

module Bellows
  class Tasks < Thor

    desc "sync PROJECT", "Create tests & update refspecs for active reviews."
    method_options :test => :boolean
    def sync(project)
      if not ['nova', 'glance', 'keystone'].include?(project) then
        puts "ERROR: Please specify a valid project name."
        exit 1
      end
      test = options[:test]
      smoke_tests = Bellows::SmokeStack.get_smoke_tests(project)
      configs=Util.load_configs
      test_suite_ids = configs['test_suite_ids'].collect {|x| x.to_s }
      config_template_ids = configs['config_template_ids'].collect {|x| x.to_s }

      Bellows::Gerrit.reviews(project) do |review|
        owner = review['owner']['name']
        refspec = review['currentPatchSet']['ref']
        review_id = Bellows::Util.short_spec(refspec)
        smoke_test = smoke_tests[review_id]
        desc = owner + ": " +review['subject']
        if not smoke_test
          puts "Creating... " + desc
          Bellows::SmokeStack.create_smoke_test(project, desc, refspec, config_template_ids, test_suite_ids) if not test
        else
          if smoke_test["#{project}_package_builder"]['branch'] != refspec then
            puts "Updating... " + desc
            puts "refspec: " + refspec
            Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {"#{project}_package_builder" => { "branch" => refspec}, "description" => desc, "status" => "Updated"}) if not test
          end
        end
      end
    end

    desc "purge PROJECT", "Purge merged reviews from SmokeStack"
    method_options :test => :boolean
    def purge(project)
      if not ['nova', 'glance', 'keystone'].include?(project) then
        puts "ERROR: Please specify a valid project name."
        exit 1
      end
      test = options[:test]
      smoke_tests = Bellows::SmokeStack.get_smoke_tests(project)
      Bellows::Gerrit.reviews(project, "merged") do |review|
        refspec = review['currentPatchSet']['ref']
        review_id = Bellows::Util.short_spec(refspec)
        smoke_test = smoke_tests[review_id]
        desc = review['owner']['name'] + ": " +review['subject']
        if smoke_test
          puts "Deleting... " + desc
          Bellows::HTTP.delete("/smoke_tests/#{smoke_test['id']}") if not test
        end
      end
    end

    desc "reconfig PROJECT", "Reconfigure test suite and configuration selections."
    def reconfig(project)
      if not ['nova', 'glance', 'keystone'].include?(project) then
        puts "ERROR: Please specify a valid project name."
        exit 1
      end
      test = options[:test]
      smoke_tests = Bellows::SmokeStack.get_smoke_tests(project)
      configs=Util.load_configs
      test_suite_ids = configs['test_suite_ids'].collect {|x| x.to_s }
      config_template_ids = configs['config_template_ids'].collect {|x| x.to_s }
      Bellows::Gerrit.reviews(project) do |review|
        refspec = review['currentPatchSet']['ref']
        review_id = Bellows::Util.short_spec(refspec)
        smoke_test = smoke_tests[review_id]
        desc = review['owner']['name'] + ": " +review['subject']
        if smoke_test
          Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {"test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids, "description" => desc})
        end
      end
    end

  end
end
