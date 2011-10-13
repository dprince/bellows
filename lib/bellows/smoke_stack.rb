require 'json'
require 'bellows/http'
require 'bellows/util'

module Bellows
  class SmokeStack

    def self.get_smoke_tests(project)
      smoke_tests = {}
      data = JSON.parse(Bellows::HTTP.get("/smoke_tests.json"))
      data.each do |item|
        branch = item['smoke_test']["#{project}_package_builder"]['branch']
        if branch and not branch.empty? then
          smoke_tests.store(Bellows::Util.short_spec(branch), item['smoke_test'])
        end
      end
      smoke_tests
    end

    def self.format_request(smoke_test)
      req={}
      smoke_test.each_pair do |name, item|
        #only builders should be hashes
        if item.kind_of?(Hash) then
          item.each_pair do |builder_name, builder|
            req.store("smoke_test[#{name}_attributes][#{builder_name}]", builder)
          end
        elsif item.kind_of?(Array) then
          req.store("smoke_test[#{name}][]", item)
        else
          req.store("smoke_test[#{name}]", item)
        end
      end
      req.delete("smoke_test['id']")
      req
    end

    def self.update_smoke_test(id, updates={})
  
      data = JSON.parse(Bellows::HTTP.get("/smoke_tests/#{id}.json"))
      ['nova', 'glance', 'keystone'].each do |proj|
        if updates["#{proj}_package_builder"]
          data["smoke_test"]["#{proj}_package_builder"].merge!(updates["#{proj}_package_builder"])
          updates.delete("#{proj}_package_builder")
        end
      end
      data['smoke_test'].merge!(updates)
      post_data = format_request(data['smoke_test'])
      Bellows::HTTP.put("/smoke_tests/#{id}", post_data)

    end

    def self.create_smoke_test(project, description, refspec, config_template_ids, test_suite_ids)

      post_data = { "smoke_test[description]" => description }

      ['nova', 'glance', 'keystone'].each do |proj|
        base_name="smoke_test[#{proj}_package_builder_attributes]"
        if project == proj then
          post_data.store("#{base_name}[url]", "https://review.openstack.org/p/openstack/#{project}")
          post_data.store("#{base_name}[branch]", refspec)
          post_data.store("#{base_name}[merge_trunk]", "1")
        else
          post_data.store("#{base_name}[url]", "git://github.com/openstack/#{proj}.git")
          post_data.store("#{base_name}[branch]", "master")
          post_data.store("#{base_name}[merge_trunk]", "0")
        end
      end

      configurations = []
      config_template_ids.each {|id| configurations << id.to_s}
      post_data.store("smoke_test[config_template_ids][]", configurations)

      test_suites = []
      test_suite_ids.each {|id| test_suites << id.to_s}
      post_data.store("smoke_test[test_suite_ids][]", test_suites)

      Bellows::HTTP.post("/smoke_tests", post_data)

    end

  end
end