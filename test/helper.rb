require 'rubygems'
require 'bundler'
require 'thor'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bellows'
require 'mocha'

def fixture_path
  File.expand_path("../fixtures", __FILE__)
end

def fixture(file)
  File.read(fixture_path + '/' + file)
end
