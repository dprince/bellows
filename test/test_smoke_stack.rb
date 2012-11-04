$:.unshift File.dirname(__FILE__)
require 'helper'
require 'yaml'

class SmokeStackTest < Test::Unit::TestCase

  def test_comment_configs_default

    Bellows::Util.stubs(:load_configs).returns({})
    assert_equal 1, Bellows::SmokeStack.comment_configs.size

  end

  def test_comment_configs_config

    sample_config = fixture('config.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))
    assert_equal 3, Bellows::SmokeStack.comment_configs.size

    unit_tester_type = Bellows::SmokeStack.comment_configs[0]
    assert_equal 'job_unit_tester', unit_tester_type['name']
    assert_equal 'Unit', unit_tester_type['description']
    assert_nil unit_tester_type['config_template_id']
    assert_equal true, unit_tester_type['auto_approved']

    puppet_vpc_type = Bellows::SmokeStack.comment_configs[1]
    assert_equal 'job_puppet_vpc', puppet_vpc_type['name']
    assert_equal 1, puppet_vpc_type['config_template_id']
    assert_equal 'Libvirt (Fedora 16)', puppet_vpc_type['description']
    assert_equal false, puppet_vpc_type['auto_approved']

  end

  def test_job_types_custom_project_config

    sample_config = fixture('config_custom_project.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))

    # there should only be 1 set for the default (no project)
    assert_equal 1, Bellows::SmokeStack.comment_configs.size

    # there should only be 1 set for the glance project
    assert_equal 1, Bellows::SmokeStack.comment_configs("glance").size

    # the nova project should have custom job types defined
    unit_tester_type = Bellows::SmokeStack.comment_configs("nova")[0]
    assert_equal 'job_unit_tester', unit_tester_type['name']
    assert_equal 'Unit', unit_tester_type['description']
    assert_nil unit_tester_type['config_template_id']
    assert_equal true, unit_tester_type['auto_approved']

    puppet_vpc_type = Bellows::SmokeStack.comment_configs("nova")[1]
    assert_equal 'job_puppet_vpc', puppet_vpc_type['name']
    assert_equal 3, puppet_vpc_type['config_template_id']
    assert_equal 'Libvirt (Fedora 16)', puppet_vpc_type['description']
    assert_equal false, puppet_vpc_type['auto_approved']

  end

end
