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
    def sync(project, options=(options or {}))
      Util.validate_project(project)
      test = options[:test]
      all = options[:all]
      smoke_tests = Bellows::SmokeStack.smoke_tests(project)
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
            puts "Updating... " + desc if not options[:quiet]
            puts "refspec: " + refspec if not options[:quiet]
            Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {"#{project}_package_builder" => { "branch" => refspec}, "description" => desc, "status" => "Updated", "test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids}) if not test
          elsif all then
            puts "Updating (all)... " + desc if not options[:quiet]
            Bellows::SmokeStack.update_smoke_test(smoke_test['id'], {"#{project}_package_builder" => { "branch" => refspec}, "description" => desc, "test_suite_ids" => test_suite_ids, "config_template_ids" => config_template_ids}) if not test
          end
        end
      end
    end

    desc "purge PROJECT", "Purge merged reviews from SmokeStack"
    method_options :test => :boolean
    method_options :quiet => :boolean
    def purge(project, options=(options or {}))
      Util.validate_project(project)
      test = options[:test]
      smoke_tests = Bellows::SmokeStack.smoke_tests(project)
      reviews = Bellows::Gerrit.reviews(project, "merged")
      reviews += Bellows::Gerrit.reviews(project, "abandoned") 
      reviews.each do |review|
        refspec = review['currentPatchSet']['ref']
        review_id = Bellows::Util.short_spec(refspec)
        smoke_test = smoke_tests[review_id]
        desc = review['owner']['name'] + ": " +review['subject']
        if smoke_test
          puts "Deleting... " + desc if not options[:quiet]
          Bellows::HTTP.delete("/smoke_tests/#{smoke_test['id']}") if not test
        end
      end
    end

    desc "fire PROJECT", "Run jobs for reviews without results."
    method_options :test => :boolean
    method_options :quiet => :boolean
    method_options :limit => :integer
    def fire(project, options=(options or {}))
      Util.validate_project(project)
      test = options[:test]
      limit = options[:limit] || 5
      jobs = Set.new
      Bellows::SmokeStack.jobs.each do |job|
          data = job.values[0]
          if data
              revision = data["#{project}_revision"]
              if revision and not revision.empty?
                  jobs.add(revision[0,7])
              end
          end
      end
      smoke_tests = Bellows::SmokeStack.smoke_tests(project)

      count=0
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
      end
    end

    desc "comment PROJECT", "Add gerrit comments for reviews w/ results."
    method_options :test => :boolean
    method_options :quiet => :boolean
    method_options :cache_file => :string, :required => true
    def comment(project, options=(options or {}))
      Util.validate_project(project)
      test = options[:test]
      cache_file = options[:cache_file]
      jobs = Bellows::SmokeStack.jobs

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
        Bellows::Gerrit.reviews(project) do |review|
          revision = review['currentPatchSet']['revision'][0,7]
          desc = review['owner']['name'] + ": " +review['subject']
          if not cached_hashes.include? revision
            refspec = review['currentPatchSet']['ref']
            patchset_num = review['currentPatchSet']['number']
            jobs_for_rev = Bellows::SmokeStack.jobs_with_hash(revision, jobs)
            if jobs_for_rev.count > 0 then

              job_types = Bellows::SmokeStack.job_types
              job_datas = {}
              job_types.each do |job_type|
                job_data=Bellows::SmokeStack.job_data_for_type(jobs_for_rev, job_type['name'])
                job_datas.store(job_type, job_data)
              end

              if Bellows::SmokeStack.complete?(job_datas) then
                puts "Commenting ... " + desc if not options[:quiet]
                message = "SmokeStack Results (patch set #{patchset_num}):\n"
                verify_vote = 1
                job_datas.each_pair do |job_type, job_data|
                    message += "\t#{job_type['description']} #{job_data['status']}:#{job_data['msg']} http://smokestack.openstack.org/?go=/jobs/#{job_data['id']}\n"
                    verify_vote = -1 if job_data['status'] == 'Failed'
                end
                puts message if not options[:quiet]
                out = Bellows::Gerrit.comment(review['currentPatchSet']['revision'], message, verify_vote) if not test
                puts out if not options[:quiet] and not test
                file.write revision + "\n" if not test
              end

            end

          end
        end
      end
    end

  end
end
