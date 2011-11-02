# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bellows}
  s.version = "1.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Prince"]
  s.date = %q{2011-11-01}
  s.default_executable = %q{bellows}
  s.description = %q{CLI to drive SmokeStack test creation and maintenance based on Gerrit reviews.}
  s.email = %q{dan.prince@rackspace.com}
  s.executables = ["bellows"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "CHANGELOG",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "bellows.gemspec",
    "bin/bellows",
    "lib/bellows.rb",
    "lib/bellows/gerrit.rb",
    "lib/bellows/http.rb",
    "lib/bellows/smoke_stack.rb",
    "lib/bellows/tasks.rb",
    "lib/bellows/util.rb",
    "test/helper.rb",
    "test/test_util.rb"
  ]
  s.homepage = %q{http://github.com/dprince/bellows}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fire it up! SmokeStack automation w/ Gerrit.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<thor>, ["~> 0.14.6"])
      s.add_development_dependency(%q<json>, ["~> 1.4.6"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<thor>, ["~> 0.14.6"])
      s.add_dependency(%q<json>, ["~> 1.4.6"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<thor>, ["~> 0.14.6"])
    s.add_dependency(%q<json>, ["~> 1.4.6"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
  end
end

