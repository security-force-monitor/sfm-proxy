require 'rubygems'
require 'bundler/setup'

require 'json'

require 'faraday'
require 'pupa'

LOGGER = Pupa::Logger.new('sfm-proxy')

def connection
  @connection ||= begin
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
    connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
    connection.login(uri.user, uri.password) if uri.user && uri.password
    connection
  end
end

Dir['tasks/*.rake'].each { |r| import r }
