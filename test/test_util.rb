$:.unshift File.dirname(__FILE__)
require 'helper'

class UtilTest < Test::Unit::TestCase

  def test_short_spec
    assert_equal "123/123", Bellows::Util.short_spec("123/123/123")
  end

  # test for Utils.test_configs
  def test_test_configs
    sample_config = fixture('config_custom_project.yaml')
    Bellows::Util.stubs(:load_configs).returns(YAML::load(sample_config))

    # ensure configs are set for a project which specifies them
    test_suite_ids, config_template_ids = Bellows::Util.test_configs("glance")

    assert_equal "3", config_template_ids[0]
    assert_equal "4", config_template_ids[1]

    assert_equal "2", test_suite_ids[0]

    # ensure default configs are used for project that doesn't specify them
    test_suite_ids, config_template_ids = Bellows::Util.test_configs("openstack/nova")

    assert_equal "1", config_template_ids[0]
    assert_equal "2", config_template_ids[1]

    assert_equal "1", test_suite_ids[0]

  end

end
