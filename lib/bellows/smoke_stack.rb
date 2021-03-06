require 'json'
require 'bellows/http'
require 'bellows/util'

module Bellows
  class SmokeStack

    PROJ_REVISIONS = {
      'openstack/nova' => 'nova_revision',
      'openstack/glance' => 'glance_revision',
      'openstack/keystone' => 'keystone_revision',
      'openstack/swift' => 'swift_revision',
      'openstack/cinder' => 'cinder_revision',
      'openstack/neutron' => 'neutron_revision',
      'openstack/ceilometer' => 'ceilometer_revision',
      'openstack/heat' => 'heat_revision',
      'stackforge/puppet-nova' => 'nova_conf_module_revision',
      'stackforge/puppet-glance' => 'glance_conf_module_revision',
      'stackforge/puppet-keystone' => 'keystone_conf_module_revision',
      'stackforge/puppet-swift' => 'swift_conf_module_revision',
      'stackforge/puppet-cinder' => 'cinder_conf_module_revision',
      'stackforge/puppet-neutron' => 'neutron_conf_module_revision',
      'stackforge/puppet-ceilometer' => 'ceilometer_conf_module_revision',
      'stackforge/puppet-heat' => 'heat_conf_module_revision',
    }

    OBJECT_NAMES = {
      'openstack/nova' => 'nova_package_builder',
      'openstack/glance' => 'glance_package_builder',
      'openstack/keystone' => 'keystone_package_builder',
      'openstack/swift' => 'swift_package_builder',
      'openstack/cinder' => 'cinder_package_builder',
      'openstack/neutron' => 'neutron_package_builder',
      'openstack/ceilometer' => 'ceilometer_package_builder',
      'openstack/heat' => 'heat_package_builder',
      'stackforge/puppet-nova' => 'nova_config_module',
      'stackforge/puppet-glance' => 'glance_config_module',
      'stackforge/puppet-keystone' => 'keystone_config_module',
      'stackforge/puppet-swift' => 'swift_config_module',
      'stackforge/puppet-cinder' => 'cinder_config_module',
      'stackforge/puppet-neutron' => 'neutron_config_module',
      'stackforge/puppet-ceilometer' => 'ceilometer_config_module',
      'stackforge/puppet-heat' => 'heat_config_module',
    }

    ATTRIBUTE_NAMES = {
      'openstack/nova' => 'nova_package_builder_attributes',
      'openstack/glance' => 'glance_package_builder_attributes',
      'openstack/keystone' => 'keystone_package_builder_attributes',
      'openstack/swift' => 'swift_package_builder_attributes',
      'openstack/cinder' => 'cinder_package_builder_attributes',
      'openstack/neutron' => 'neutron_package_builder_attributes',
      'openstack/ceilometer' => 'ceilometer_package_builder_attributes',
      'openstack/heat' => 'heat_package_builder_attributes',
      'stackforge/puppet-nova' => 'nova_config_module_attributes',
      'stackforge/puppet-glance' => 'glance_config_module_attributes',
      'stackforge/puppet-keystone' => 'keystone_config_module_attributes',
      'stackforge/puppet-swift' => 'swift_config_module_attributes',
      'stackforge/puppet-cinder' => 'cinder_config_module_attributes',
      'stackforge/puppet-neutron' => 'neutron_config_module_attributes',
      'stackforge/puppet-ceilometer' => 'ceilometer_config_module_attributes',
      'stackforge/puppet-heat' => 'heat_config_module_attributes',
    }

    def self.jobs()
      JSON.parse(Bellows::HTTP.get("/jobs.json?limit=99999"))
    end

    def self.jobs_with_hash(git_hash, jobs=nil)
      if jobs.nil?
        jobs = JSON.parse(Bellows::HTTP.get("/jobs.json?limit=99999"))
      end
      jobs_found = []
      jobs.each do |job|
        data = job.values[0]
        Util.projects.each do |project|
          revision = data[PROJ_REVISIONS[project]]
          if revision and revision == git_hash then
            jobs_found << job 
          end
        end
      end
      jobs_found
    end

    # Return a reference to the first job matching the criteria for
    # the specified comment config
    def self.job_data_for_comments(jobs, comment_config)
      jobs.each do |job|
        if job.keys[0] == comment_config['name']
          job_values = job.values[0]
          if comment_config['config_template_id'].nil? and job.keys[0] == 'job_unit_tester' then
            # will be nil for unit tests (which don't use a config template)
            return job_values
          elsif comment_config['config_template_id'] and job_values['config_template_id'] == comment_config['config_template_id'] then
            return job_values
          end
        end
      end
      nil
    end

    DEFAULT_COMMENT_CONFIGS=[{'name' => 'job_unit_tester', 'auto_approved' => false, 'description' => 'Unit'}]
    def self.comment_configs(project=nil)
      configs=Util.load_configs

      comment_config_list = nil

      if not project.nil? and configs[project] then
        if configs[project]['comment_configs']
          comment_config_list = configs[project]['comment_configs']
        end
      else
        comment_config_list = configs['comment_configs']
      end

      if comment_config_list.nil? or comment_config_list.empty? then
        comment_config_list = DEFAULT_COMMENT_CONFIGS
      end

      comment_config_list

    end

    def self.smoke_tests(projects)
      tests = {}
      data = JSON.parse(Bellows::HTTP.get("/smoke_tests.json"))
      data.each do |item|
        projects.each do |project|
          # core projects use this
          branch = item['smoke_test'][OBJECT_NAMES[project]]['branch']
          if branch and not branch.empty? then
            tests.store(Bellows::Util.short_spec(branch), item['smoke_test'])
          end
        end
      end
      tests
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
      Util.projects.each do |proj|
        if updates[OBJECT_NAMES[proj]]
          data["smoke_test"][OBJECT_NAMES[proj]].merge!(updates[OBJECT_NAMES[proj]])
          updates.delete(OBJECT_NAMES[proj])
        end
      end
      data['smoke_test'].merge!(updates)
      post_data = format_request(data['smoke_test'])
      Bellows::HTTP.put("/smoke_tests/#{id}", post_data)

    end

    # returns the ID of the created SmokeTest 
    def self.create_smoke_test(project, description, refspec, config_template_ids, test_suite_ids)

      post_data = { "smoke_test[description]" => description }

      Util::ALL_PROJECTS.each do |proj|
        base_name="smoke_test[#{ATTRIBUTE_NAMES[proj]}]"
        if project == proj then
          post_data.store("#{base_name}[url]", "https://review.openstack.org/#{proj}")
          post_data.store("#{base_name}[branch]", refspec)
          post_data.store("#{base_name}[merge_trunk]", "1")
        else
          post_data.store("#{base_name}[merge_trunk]", "0")
          post_data.store("#{base_name}[url]", "git://github.com/#{proj}.git")
          post_data.store("#{base_name}[branch]", "master")
        end
      end

      configurations = []
      config_template_ids.each {|id| configurations << id.to_s}
      post_data.store("smoke_test[config_template_ids][]", configurations)

      test_suites = []
      test_suite_ids.each {|id| test_suites << id.to_s}
      post_data.store("smoke_test[test_suite_ids][]", test_suites)

      # Return the ID of the created smoke test
      Bellows::HTTP.post("/smoke_tests", post_data).sub(/^.*\//, '')

    end

    #returns true if jobs all passed (green) or all failed results are approved
    def self.complete?(job_datas)
      complete = true
      job_datas.each do |arr|
        job_type = arr[0]
        job_data = arr[1]
        return false if job_data.nil? or (job_data['status'] and ['Pending', 'Running'].include?(job_data['status'])) # waiting on pending jobs or data

        # if bellows doesn't understand the status then we fail
        if not ['Pending', 'Running', 'Success', 'Failed', 'BuildFail', 'TestFail'].include?(job_data['status']) then
          return false
        end

        next if job_type['auto_approved'] # global auto_approved

        # special case for build failures
        if job_data['status'] == 'BuildFail' and not job_type['buildfail_auto_approved'] and not job_data['approved_by'] then
          complete = false
        end

        # special case for test failures
        if job_data['status'] == 'TestFail' and not job_type['testfail_auto_approved'] and not job_data['approved_by'] then
          complete = false
        end

        if job_data['status'] == 'Failed' and not job_data['approved_by'] then
          complete = false
        end

      end
      complete
    end

  end
end
