require 'json'
require 'set'
require 'bellows/http'
require 'bellows/util'
require 'bellows/gerrit'
require 'bellows/smoke_stack'

module Bellows
  class Tasks < Thor

    desc "sync PROJECT", "Create tests & update refspecs for active reviews."
    method_options :test => :boolean
    method_options :all => :boolean
    method_options :quiet => :boolean
    def sync(project=nil, options=(options or {}))
      projects = Util.projects(project)
      test = options[:test]
      all = options[:all]
      smoke_tests = Bellows::SmokeStack.smoke_tests(projects)
      configs=Util.load_configs

      projects.each do |project|
        Bellows::Gerrit.reviews(project) do |review|
          owner = review['owner']['name']
          refspec = review['currentPatchSet']['ref']
          review_id = Bellows::Util.short_spec(refspec)
          smoke_test = smoke_tests[review_id]
          desc = owner + ": " +review['subject']
          test_suite_ids, config_template_ids = Util.test_configs(project)
          if not smoke_test
            puts "Creating... " + desc
            Bellows::SmokeStack.create_smoke_test(project, desc, refspec, config_template_ids, test_suite_ids) if not test
          else
            if smoke_test[Bellows::SmokeStack::OBJECT_NAMES[project]]['branch'] != refspec then
              puts "Updating... " + desc if not options[:quiet]
              puts "refspec: " + refspec if not options[:quiet]
              Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {Bellows::SmokeStack::OBJECT_NAMES[project] => { "branch" => refspec}, "description" => desc, "status" => "Updated", "test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids}) if not test
            elsif all then
              puts "Updating (all)... " + desc if not options[:quiet]
              Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {Bellows::SmokeStack::OBJECT_NAMES[project] => { "branch" => refspec}, "description" => desc, "test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids}) if not test
            end
          end
        end # reviews
      end # projects
    end

    desc "purge PROJECT", "Purge merged reviews from SmokeStack"
    method_options :test => :boolean
    method_options :quiet => :boolean
    def purge(project=nil, options=(options or {}))
      projects = Util.projects(project)
      test = options[:test]
      smoke_tests = Bellows::SmokeStack.smoke_tests(projects)
      projects.each do |project|
        reviews = Bellows::Gerrit.reviews(project, "merged")
        reviews += Bellows::Gerrit.reviews(project, "abandoned") 
        reviews.each do |review|
          refspec = review['currentPatchSet']['ref']
          review_id = Bellows::Util.short_spec(refspec)
          smoke_test = smoke_tests[review_id]
          desc = ""
          if review['owner']['name'] then
            desc = review['owner']['name']
          end
          if review['subject'] then
            desc += ": " +review['subject']
          end
          if smoke_test
            puts "Deleting... " + desc if not options[:quiet]
            Bellows::HTTP.delete("/smoke_tests/#{smoke_test['id']}") if not test
          end
        end
      end #projects
    end

    desc "fire PROJECT", "Run jobs for reviews without results."
    method_options :test => :boolean
    method_options :quiet => :boolean
    method_options :limit => :integer
    def fire(project=nil, options=(options or {}))
      projects = Util.projects(project)
      test = options[:test]
      limit = options[:limit] || 5
      jobs = Set.new
      Bellows::SmokeStack.jobs.each do |job|
          projects.each do |project|
            data = job.values[0]
            if data
                revision = data[Bellows::SmokeStack::PROJ_REVISIONS[project]]
                if revision and not revision.empty?
                    jobs.add(revision[0,7])
                end
            end
          end
      end
      smoke_tests = Bellows::SmokeStack.smoke_tests(projects)

      count=0
      projects.each do |project|
        Bellows::Gerrit.reviews(project) do |review|
          revision = review['currentPatchSet']['revision'][0,7]
          desc = review['owner']['name'] + ": " +review['subject']
          if not jobs.include? revision
            puts "Running ... " + desc if not options[:quiet]
            refspec = review['currentPatchSet']['ref']
            review_id = Bellows::Util.short_spec(refspec)
            smoke_test = smoke_tests[review_id]
            if smoke_test then
              count += 1
              Bellows::HTTP.post("/smoke_tests/#{smoke_test['id']}/run_jobs", {}) if not test
            else
              puts "WARNING: no smoke test exists for: #{refspec}" if not options[:quiet]
            end
            if count >= limit.to_i then
              break
            end
          end
        end # reviews
       end # project
    end

    desc "comment PROJECT", "Add gerrit comments for reviews w/ results."
    method_options :test => :boolean
    method_options :quiet => :boolean
    method_options :cache_file => :string, :required => true
    def comment(project=nil, options=(options or {}))
      projects = Util.projects(project)
      test = options[:test]
      cache_file = options[:cache_file]
      jobs = Bellows::SmokeStack.jobs
      configs=Util.load_configs

      if cache_file.nil? or cache_file.empty?
        puts "ERROR: cache_file is required."
        exit 1
      end

      cached_hashes = Set.new
      if File.exists?(cache_file) then
        IO.read(cache_file).each_line do |line|
          cached_hashes << line.chomp
        end
      end

      File.open(cache_file, 'a') do |file|
        projects.each do |project|
          Bellows::Gerrit.reviews(project) do |review|
            revision = review['currentPatchSet']['revision'][0,7]
            desc = review['owner']['name'] + ": " +review['subject']
            if not cached_hashes.include? revision
              refspec = review['currentPatchSet']['ref']
              patchset_num = review['currentPatchSet']['number']
              jobs_for_rev = Bellows::SmokeStack.jobs_with_hash(revision, jobs)
              if jobs_for_rev.count > 0 then
  
                comment_configs = Bellows::SmokeStack.comment_configs(project)
                job_datas = []
                comment_configs.each do |comment_config|
                  job_data=Bellows::SmokeStack.job_data_for_comments(jobs_for_rev, comment_config)
                  job_datas << [comment_config, job_data]
                end
  
                if Bellows::SmokeStack.complete?(job_datas) then
                  puts "Commenting ... " + desc if not options[:quiet]
                  message = "SmokeStack Results (patch set #{patchset_num}):\n"
                  verify_vote = 1
                  job_datas.each do |arr|
                      comment_config = arr[0]
                      job_data = arr[1]
                      status = 'UNKNOWN'
                      if job_data['status'] == 'Success' then
                        status = 'SUCCESS'
                      elsif ['Failed', 'BuildFail', 'TestFail'].include?(job_data['status']) then
                        status = 'FAILED'
                        verify_vote = -1
                      end

                      message += "- #{comment_config['description']} #{configs['smokestack_url']}/?go=/jobs/#{job_data['id']} : #{status} #{job_data['msg']}\n"

                  end
                  puts message if not options[:quiet]
                  out = Bellows::Gerrit.comment(review['currentPatchSet']['revision'], message, verify_vote) if not test
                  puts out if not options[:quiet] and not test
                  file.write revision + "\n" if not test
                end
                
              end
  
            end
          end # reviews
        end # projects
      end # file
    end

    desc "stream", "Stream Gerrit events and sync data to SmokeStack."
    method_options :test => :boolean
    method_options :fire => :boolean
    method_options :quiet => :boolean
    method_options :branch => :string, :default => "master"
    def stream(options=(options or {}))
      test = options[:test]
      fire = options[:fire]
      branch = options[:branch] || "master"
      configs=Util.load_configs
      projects = Util.projects

      Bellows::Gerrit.stream_events('patchset-created') do |patchset|
        project = patchset['change']['project']
        patch_branch = patchset['change']['branch']
        if projects.include?(project) and patch_branch == branch then
          owner = patchset['change']['owner']['name']
          refspec = patchset['patchSet']['ref']
          review_id = Bellows::Util.short_spec(refspec)
          smoke_tests = Bellows::SmokeStack.smoke_tests(projects)
          smoke_test = smoke_tests[review_id]
          desc = owner + ": " +patchset['change']['subject']
          test_suite_ids, config_template_ids = Util.test_configs(project)

          smoke_test_id = nil
          if not smoke_test
            # create new smoke test
            puts "Creating... " + desc
            smoke_test_id = Bellows::SmokeStack.create_smoke_test(project, desc, refspec, config_template_ids, test_suite_ids) if not test
          else
            # update existing smoke test
            puts "Updating... " + desc if not options[:quiet]
            puts "refspec: " + refspec if not options[:quiet]
            Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {Bellows::SmokeStack::OBJECT_NAMES[project] => { "branch" => refspec}, "description" => desc, "status" => "Updated", "test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids}) if not test
            smoke_test_id = smoke_test['id']

          end

          # fire off tests
          if not test and fire then
            Bellows::HTTP.post("/smoke_tests/#{smoke_test_id}/run_jobs", {})
          end

        end # reviews
      end # stream_events
    end

  end
end
