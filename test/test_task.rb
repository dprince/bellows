$:.unshift File.dirname(__FILE__)
require 'helper'
require 'tempfile'

class TaskTest < Test::Unit::TestCase

  def test_fire

    jobs_data = fixture('jobs.json')
    Bellows::SmokeStack.stubs(:jobs).returns(JSON.parse(jobs_data))
    
    smoke_tests_data = fixture('nova_smoke_tests.json')
    Bellows::HTTP.stubs(:get).returns(smoke_tests_data)

    gerrit_data = fixture('gerrit.json')
    Bellows::Gerrit.stubs(:run_cmd).returns(gerrit_data)

    response = mock()
    Bellows::HTTP.stubs(:post).returns(response)
    tasks = Bellows::Tasks.new
    tasks.fire('openstack/nova', options={:quiet => true})

  end

  def test_comment

    sample_config = fixture('config.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))

    jobs_data = fixture('jobs.json')
    Bellows::SmokeStack.stubs(:jobs).returns(JSON.parse(jobs_data))
    
    gerrit_data = fixture('gerrit.json')
    Bellows::Gerrit.stubs(:run_cmd).returns(gerrit_data)

    cache_file=Tempfile.new('smokestack')

    response = mock()
    Bellows::HTTP.stubs(:post).returns(response)
    tasks = Bellows::Tasks.new

    tasks.comment('openstack/nova', options={:quiet => true, :cache_file => cache_file.path})

  end

  def test_stream

    sample_config = fixture('config.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))

    smoke_tests_data = fixture('nova_smoke_tests.json')
    Bellows::HTTP.stubs(:get).returns(smoke_tests_data)

    cache_file=Tempfile.new('smokestack')

    response = mock()
    Bellows::HTTP.stubs(:post).returns(response)
    tasks = Bellows::Tasks.new

    stream_data = fixture('stream.json')
    Bellows::Gerrit.stubs(:stream_events_cmd).returns("echo '#{stream_data}'")

    tasks.stream(options={:quiet => true})

  end

end
