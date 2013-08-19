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
    assert_equal 1, Bellows::SmokeStack.comment_configs("openstack/glance").size

    # the nova project should have custom job types defined
    unit_tester_type = Bellows::SmokeStack.comment_configs("openstack/nova")[0]
    assert_equal 'job_unit_tester', unit_tester_type['name']
    assert_equal 'Unit', unit_tester_type['description']
    assert_nil unit_tester_type['config_template_id']
    assert_equal true, unit_tester_type['auto_approved']

    puppet_vpc_type = Bellows::SmokeStack.comment_configs("openstack/nova")[1]
    assert_equal 'job_puppet_vpc', puppet_vpc_type['name']
    assert_equal 3, puppet_vpc_type['config_template_id']
    assert_equal 'Libvirt (Fedora 16)', puppet_vpc_type['description']
    assert_equal false, puppet_vpc_type['auto_approved']

  end

  def test_complete_with_single_success

    comment_config = {'auto_approved' => false}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas = [[comment_config, job_data]]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_single_failed

    comment_config = {'auto_approved' => false}
    job_data = {'status' => 'Failed', 'approved_by' => nil}
    job_datas = [[comment_config, job_data]]

    assert_equal false, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_single_failed_manually_approved

    comment_config = {'auto_approved' => false}
    job_data = {'status' => 'Failed', 'approved_by' => 'dprince'}
    job_datas = [[comment_config, job_data]]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_single_failed_auto_approved

    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Failed', 'approved_by' => nil}
    job_datas = [[comment_config, job_data]]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_invalid_job_status

    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Foo', 'approved_by' => 'dprince'}
    job_datas = [[comment_config, job_data]]

    assert_equal false, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_job_pending

    job_datas = []
    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]
    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Pending', 'approved_by' => 'dprince'}
    job_datas << [comment_config, job_data]

    assert_equal false, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_job_running

    job_datas = []
    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]
    comment_config = {'auto_approved' => true}
    job_data = {'status' => 'Pending', 'approved_by' => 'dprince'}
    job_datas << [comment_config, job_data]

    assert_equal false, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_build_fail_auto_approved

    job_datas = []
    comment_config = {'buildfail_auto_approved' => true}
    job_data = {'status' => 'BuildFail', 'approved_by' => nil}
    job_datas << [comment_config, job_data]
    comment_config = {}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_build_fail_manually_approved

    job_datas = []
    comment_config = {'buildfail_auto_approved' => false}
    job_data = {'status' => 'BuildFail', 'approved_by' => 'dprince'}
    job_datas << [comment_config, job_data]
    comment_config = {}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_build_fail_auto_approved

    job_datas = []
    comment_config = {'testfail_auto_approved' => true}
    job_data = {'status' => 'TestFail', 'approved_by' => nil}
    job_datas << [comment_config, job_data]
    comment_config = {}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

  def test_complete_with_build_fail_manually_approved

    job_datas = []
    comment_config = {'testfail_auto_approved' => false}
    job_data = {'status' => 'TestFail', 'approved_by' => 'dprince'}
    job_datas << [comment_config, job_data]
    comment_config = {}
    job_data = {'status' => 'Success', 'approved_by' => nil}
    job_datas << [comment_config, job_data]

    assert_equal true, Bellows::SmokeStack.complete?(job_datas)

  end

end
