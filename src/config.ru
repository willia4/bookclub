#require 'rubygems'
require 'bundler'
Bundler.setup

require 'sinatra'
require 'sinatra/content_for2'
require 'rack/throttle'
require 'yaml'

# require 'sass/plugin/rack'
# use Sass::Plugin::Rack

# Sass::Plugin.options[:cache] = false
# Sass::Plugin.options[:always_update] = true

# load config into global variable
$config = {}

# start with secrets.yaml if it is present...
if File.file?('./secrets.yaml')
  $config = YAML::load(File.open("secrets.yaml"))
end

# ...but allow environment variables to override
#first, make sure that the shape of $config is correct
$config[:aws] = {} if !$config.has_key?(:aws)
$config[:aws][:s3] = {} if !$config[:aws].has_key?(:s3)
$config[:aws][:sdb] = {} if !$config[:aws].has_key?(:sdb)
$config[:css] = {} if !$config.has_key?(:css)
$config[:facebook] = {} if !$config.has_key?(:facebook)
$config[:goodreads] = {} if !$config.has_key?(:goodreads)
$config[:general] = {} if !$config.has_key?(:general)
$config[:smtp] = {} if !$config.has_key?(:smtp)
$config[:redis] = {} if !$config.has_key?(:redis)

$config[:aws][:sdb][:region] = ENV['BOOKCLUB_AWS_SDB_REGION'] if !ENV['BOOKCLUB_AWS_SDB_REGION'].nil?
$config[:aws][:sdb][:access_key] = ENV['BOOKCLUB_AWS_SDB_ACCESSKEY'] if !ENV['BOOKCLUB_AWS_SDB_ACCESSKEY'].nil?
$config[:aws][:sdb][:secret] = ENV['BOOKCLUB_AWS_SDB_SECRET'] if !ENV['BOOKCLUB_AWS_SDB_SECRET'].nil?
$config[:aws][:sdb][:domain_prefix] = ENV['BOOKCLUB_AWS_SDB_DOMAINPREFIX'] if !ENV['BOOKCLUB_AWS_SDB_DOMAINPREFIX'].nil?
$config[:aws][:s3][:region] = ENV['BOOKCLUB_AWS_S3_REGION'] if !ENV['BOOKCLUB_AWS_S3_REGION'].nil?
$config[:aws][:s3][:access_key] = ENV['BOOKCLUB_AWS_S3_ACCESSKEY'] if !ENV['BOOKCLUB_AWS_S3_ACCESSKEY'].nil?
$config[:aws][:s3][:secret] = ENV['BOOKCLUB_AWS_S3_SECRET'] if !ENV['BOOKCLUB_AWS_S3_SECRET'].nil?
$config[:aws][:s3][:bucket] = ENV['BOOKCLUB_AWS_S3_BUCKET'] if !ENV['BOOKCLUB_AWS_S3_BUCKET'].nil?

$config[:css][:css_path] = ENV['BOOKCLUB_CSS_CSSPATH'] if !ENV['BOOKCLUB_CSS_CSSPATH'].nil?
$config[:css][:scss_path] = ENV['BOOKCLUB_CSS_SCSSPATH'] if !ENV['BOOKCLUB_CSS_SCSSPATH'].nil?

$config[:facebook][:app_id] = ENV['BOOKCLUB_FACEBOOK_APPID'] if !ENV['BOOKCLUB_FACEBOOK_APPID'].nil?
$config[:facebook][:secret] = ENV['BOOKCLUB_FACEBOOK_SECRET'] if !ENV['BOOKCLUB_FACEBOOK_SECRET'].nil?

$config[:goodreads][:api_key] = ENV['BOOKCLUB_GOODREADS_APIKEY'] if !ENV['BOOKCLUB_GOODREADS_APIKEY'].nil?

$config[:general][:site_name] = ENV['BOOKCLUB_GENERAL_SITENAME'] if !ENV['BOOKCLUB_GENERAL_SITENAME'].nil?
$config[:general][:base_url] = ENV['BOOKCLUB_GENERAL_BASEURL'] if !ENV['BOOKCLUB_GENERAL_BASEURL'].nil?
$config[:general][:login_cookie] = ENV['BOOKCLUB_GENERAL_LOGINCOOKIE'] if !ENV['BOOKCLUB_GENERAL_LOGINCOOKIE'].nil?
$config[:general][:mode] = ENV['BOOKCLUB_GENERAL_MODE'] if !ENV['BOOKCLUB_GENERAL_MODE'].nil?

$config[:smtp][:server] = ENV['BOOKCLUB_SMTP_SERVER'] if !ENV['BOOKCLUB_SMTP_SERVER'].nil?
$config[:smtp][:port] = ENV['BOOKCLUB_SMTP_PORT'] if !ENV['BOOKCLUB_SMTP_PORT'].nil?
$config[:smtp][:username] = ENV['BOOKCLUB_SMTP_USERNAME'] if !ENV['BOOKCLUB_SMTP_USERNAME'].nil?
$config[:smtp][:password] = ENV['BOOKCLUB_SMTP_PASSWORD'] if !ENV['BOOKCLUB_SMTP_PASSWORD'].nil?
$config[:smtp][:from_address] = ENV['BOOKCLUB_SMTP_FROMADDRESS'] if !ENV['BOOKCLUB_SMTP_FROMADDRESS'].nil?

$config[:redis][:server] = ENV['BOOKCLUB_REDIS_SERVER'] if !ENV['BOOKCLUB_REDIS_SERVER'].nil?
$config[:redis][:port] = ENV['BOOKCLUB_REDIS_PORT'] if !ENV['BOOKCLUB_REDIS_PORT'].nil?
$config[:redis][:db] = ENV['BOOKCLUB_REDIS_DB'] if !ENV['BOOKCLUB_REDIS_DB'].nil?


if !$config[:general].has_key?(:mode)
	$config[:general][:mode] = "PROD"
end

#default to PROD if anything other than DEV is specified
if $config[:general][:mode] != "DEV"
	$config[:general][:mode] = "PROD"
end

#default redis to local host

$config[:redis][:server] = "127.0.0.1" if $config[:redis][:server].to_s == ""
$config[:redis][:port] = "6379" if $config[:redis][:port].to_s == ""
$config[:redis][:db] = "0" if $config[:redis][:db].to_s == ""

#validate config
raise "Missing region config" if $config[:aws][:sdb][:region].to_s == ""
raise "Missing access_key config" if $config[:aws][:sdb][:access_key].to_s == ""
raise "Missing secret config" if $config[:aws][:sdb][:secret].to_s == ""
raise "Missing domain_prefix config" if $config[:aws][:sdb][:domain_prefix].to_s == ""
raise "Missing region config" if $config[:aws][:s3][:region].to_s == ""
raise "Missing access_key config" if $config[:aws][:s3][:access_key].to_s == ""
raise "Missing secret config" if $config[:aws][:s3][:secret].to_s == ""
raise "Missing bucket config" if $config[:aws][:s3][:bucket].to_s == ""

raise "Missing css_path config" if $config[:css][:css_path].to_s == ""
raise "Missing scss_path config" if $config[:css][:scss_path].to_s == ""

raise "Missing app_id config" if $config[:facebook][:app_id].to_s == ""
raise "Missing secret config" if $config[:facebook][:secret].to_s == ""

raise "Missing api_key config" if $config[:goodreads][:api_key].to_s == ""

raise "Missing site_name config" if $config[:general][:site_name].to_s == ""
raise "Missing base_url config" if $config[:general][:base_url].to_s == ""
raise "Missing login_cookie config" if $config[:general][:login_cookie].to_s == ""
raise "Missing mode config" if $config[:general][:mode].to_s == ""

raise "Missing server config" if $config[:smtp][:server].to_s == ""
raise "Missing port config" if $config[:smtp][:port].to_s == ""
raise "Missing username config" if $config[:smtp][:username].to_s == ""
raise "Missing password config" if $config[:smtp][:password].to_s == ""
raise "Missing from_address config" if $config[:smtp][:from_address].to_s == ""

raise "Missing server config" if $config[:redis][:server].to_s == ""
raise "Missing port config" if $config[:redis][:port].to_s == ""
raise "Missing db config" if $config[:redis][:db].to_s == ""

use Rack::Throttle::Hourly, :max => 3000
helpers Sinatra::ContentFor2

require './routes/app.rb'

run Sinatra::Application
