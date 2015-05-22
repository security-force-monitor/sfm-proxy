require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'digest/md5'
require 'json'

require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/object/try'
require 'pupa'
require 'sinatra'
require 'sinatra/cross_origin'

configure do
  enable :cross_origin
end

helpers do
  def etag_and_return(response, options = {})
    etag(Digest::MD5.hexdigest(response.inspect))
    if options[:raw]
      response
    else
      JSON.dump(response)
    end
  end

  def connection
    @connection ||= begin
      uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
      connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
      connection.login(uri.user, uri.password) if uri.user && uri.password
      connection
    end
  end

  def commander_present(organization_id)
    commander = connection[:people].find({
      'memberships' => {
        '$elemMatch' => {
          'organization_id.value' => organization_id,
          'role.value' => 'Commander',
        },
      },
    }).sort({
      'memberships.date_first_cited.value' => -1, # XXX don't know if this sorts correctly
    }).first

    if commander
      {
        "name" => commander['name'].try(:[], 'value'),
      }
    else
      nil
    end
  end

  def event_formatter(result)
    perpetrator_organization = if result['perpetrator_organization']
      {
        "id" => result['perpetrator_organization']['id'],
        "name" => result['perpetrator_organization']['name'].try(:[], 'value'),
        "other_names" => result['perpetrator_organization']['other_names'].try(:[], 'value'),
        "sources" => result['perpetrator_organization_id']['sources'],
      }
    else
      {
        "name" => result['perpetrator_organization_id'].try(:[], 'value'),
        "sources" => result['perpetrator_organization_id']['sources'],
      }
    end

    {
      "id" => result['_id'],
      "division_id" => result['division_id'],
      "start_date" => result['start_date'].try(:[], 'value'),
      "end_date" => result['end_date'].try(:[], 'value'),
      "location" => result['location'].try(:[], 'value'),
      "admin_level_1" => result['admin_level_1'].try(:[], 'value'),
      "admin_level_2" => result['admin_level_2'].try(:[], 'value'),
      "classification" => result['classification'].try(:[], 'value'),
      "description" => result['description'].try(:[], 'value'),
      "perpetrator_name" => result['perpetrator_name'].try(:[], 'value'),
      "perpetrator_organization" => perpetrator_organization,
    }
  end
end

require_relative 'lib/events'
require_relative 'lib/countries'
require_relative 'lib/miscellaneous'
require_relative 'lib/organizations'
require_relative 'lib/people'
require_relative 'lib/search'

use Rack::Deflater
run Sinatra::Application
