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

  def contemporary?(result)
    (result['date_first_cited'].try(:[], 'value').nil? || result['date_first_cited']['value'] <= params[:at]) &&
    (result['date_last_cited'].try(:[], 'value').nil? || result['date_last_cited']['value'] >= params[:at])
  end

  def bounding_box
    @bounding_box ||= if params.key?('bbox')
      if !params[:bbox].match(/\A#{NUMERIC},#{NUMERIC},#{NUMERIC},#{NUMERIC}\z/)
        return [400, JSON.dump({'message' => "Invalid 'bbox' value"})]
      end
      params[:bbox].split(',').map{|coordinate| Float(coordinate)}
    else
      [14.5771, 4.2405, 2.6917, 13.8659] # @hardcoded Nigeria west-south, east-north
    end
  end

  def geonames_id_to_geo
    @geonames_id_to_geo ||= {}.tap do |hash|
      # @drupal Switch to PostGIS query. Just match on ADM1 for now.
      connection[:geometries].find({
        classification: 'ADM1',
        geo: {
          '$geoIntersects' => {
            '$geometry' => {
              type: 'Polygon',
              coordinates: [[
                [bounding_box[0], bounding_box[1]],
                [bounding_box[2], bounding_box[1]],
                [bounding_box[2], bounding_box[3]],
                [bounding_box[0], bounding_box[3]],
                [bounding_box[0], bounding_box[1]],
              ]]
            }
          },
        },
      }).select({
        '_id' => 1,
        'geo' => 1,
      }).each do |geometry|
        hash[geometry['_id']] = geometry['geo']
      end
    end
  end

  def area_id_to_geoname_id
    @area_id_to_geoname_id ||= {}.tap do |hash|
      connection[:areas].find({
        'division_id' => "ocd-division/country:#{params[:id]}",
        'geonames_id.value' => {'$in' => geonames_id_to_geo.keys},
      }).select({
        '_id' => 1,
        'geonames_id.value' => 1,
      }).each do |area|
        hash[area['_id']] = area['geonames_id']['value']
      end
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
