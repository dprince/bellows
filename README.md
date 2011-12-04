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

	config_template_ids:
	- 1
	- 2

	test_suite_ids:
	- 1
	EOF_CAT


Examples
--------

Available bellows tasks:

	Tasks:
	  bellows fire PROJECT   # Run jobs for reviews without results.
	  bellows help [TASK]     # Describe available tasks or one specific task
	  bellows purge PROJECT   # Purge merged reviews from SmokeStack
	  bellows sync PROJECT    # Create tests & update refspecs for active reviews.

Run bellows sync to create smokestack test configurations and update refspecs for active reviews:

	bellows sync nova

Purge 'merged' reviews from SmokeStack:

	bellows purge nova

Sync test suite choices for active reviews in SmokeStack (based on the selections in your .bellows.conf file):

	bellows sync nova --all

Fire tests for reviews without results (3 at a time):

	bellows fire nova --limit=3

All commands support creating and maintaining test configs for nova, glance, and keystone.

License
-------
Copyright (c) 2011 Dan Prince. See LICENSE.txt for further details.
