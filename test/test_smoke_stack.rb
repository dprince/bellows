$:.unshift File.dirname(__FILE__)
require 'helper'
require 'yaml'

class SmokeStackTest < Test::Unit::TestCase

  def test_job_types_default

    Bellows::Util.stubs(:load_configs).returns({})
    assert_equal 1, Bellows::SmokeStack.job_types.size

  end

  def test_job_types_config

    sample_config = fixture('config.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))
    assert_equal 3, Bellows::SmokeStack.job_types.size

    unit_tester_type = Bellows::SmokeStack.job_types[0]
    assert_equal 'job_unit_tester', unit_tester_type['name']
    assert_equal 'Unit', unit_tester_type['description']
    assert_equal true, unit_tester_type['auto_approved']

    unit_tester_type = Bellows::SmokeStack.job_types[1]
    assert_equal 'job_puppet_vpc', unit_tester_type['name']
    assert_equal 'Libvirt (Fedora 16)', unit_tester_type['description']
    assert_equal false, unit_tester_type['auto_approved']

  end

end
