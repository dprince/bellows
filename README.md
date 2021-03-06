Bellows
=======

Description
-----------

Fire it up! SmokeStack automation w/ Gerrit.

CLI to drive SmokeStack test creation and maintenance based on Gerrit reviews.

Installation
------------

	gem install bellows

	#create the bellows config in your $HOME dir:
    cat > ~/.bellows.conf <<"EOF_CAT"
	smokestack_url: http://localhost:3000
	smokestack_username: admin
	smokestack_password: cloud

        projects:
        - openstack/nova
        - stackforge/puppet-nova

	config_template_ids:
	- 1
	- 2

	test_suite_ids:
	- 1

	comment_configs:
	    - name: job_puppet_libvirt
	      config_template_id: 1
	      auto_approved: No
	      description: "Fedora 17 Libvirt Neutron w/ OpenvSwitch"

	    - name: job_puppet_xen
	      config_template_id: 2
	      auto_approved: No
	      description: "Fedora 17 Nova w/ XenServer"
	EOF_CAT


Examples
--------

Available bellows tasks:

	Tasks:
	  bellows comment PROJECT  # Add gerrit comments for reviews w/ results.
	  bellows fire PROJECT     # Run jobs for reviews without results.
	  bellows help [TASK]      # Describe available tasks or one specific task
	  bellows purge PROJECT    # Purge merged reviews from SmokeStack
	  bellows stream           # Stream Gerrit events and sync data to SmokeStack.
	  bellows sync PROJECT     # Create tests & update refspecs for active reviews.

Run bellows sync to create smokestack test configurations and update refspecs for active reviews:

	bellows sync openstack/nova

Purge 'merged' reviews from SmokeStack:

	bellows purge openstack/nova

Sync test suite choices for active reviews in SmokeStack (based on the selections in your .bellows.conf file):

	bellows sync openstack/nova --all

Fire tests for reviews without results (3 at a time):

	bellows fire openstack/nova --limit=3

License
-------
Copyright (c) 2011-2013 Dan Prince. Copyright 2012 Red Hat Inc. See LICENSE.txt for further details.
