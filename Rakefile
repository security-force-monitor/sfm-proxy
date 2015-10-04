require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'
require 'pp'

require 'faraday'
require 'pupa'

require_relative 'tasks/constants'

LOGGER = Pupa::Logger.new('sfm-proxy')

def connection
  @connection ||= begin
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
    connection = Mongo::Client.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
    connection = connection.with(user: uri.user, password: uri.password) if uri.user && uri.password
    connection
  end
end

Dir['tasks/*.rake'].each { |r| import r }
