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

Mongo::Logger.logger.level = Logger::WARN

NUMERIC = /-?\d+(?:\.\d+)?/

configure do
  enable :cross_origin
end

# @see https://github.com/britg/sinatra-cross_origin#responding-to-options
options '*' do
  response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'

  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

  200
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
      connection = Mongo::Client.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
      connection = connection.with(user: uri.user, password: uri.password) if uri.user && uri.password
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
        halt 400, JSON.dump('message' => "Invalid 'bbox' value")
      end
      params[:bbox].split(',').map{|coordinate| Float(coordinate)}
    else
      sample_bounding_box # @backend Switch to the country's bounding box.
    end
  end

  def geonames_id_to_geo
    @geonames_id_to_geo ||= {}.tap do |hash|
      # @backend @todo Switch to PostGIS query. Just match on ADM1 for now.
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
      }).projection({
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
      }).projection({
        '_id' => 1,
        'geonames_id.value' => 1,
      }).each do |area|
        hash[area['_id']] = area['geonames_id']['value']
      end
    end
  end

  def site_id_to_geoname_id
    @site_id_to_geoname_id ||= {}.tap do |hash|
      connection[:sites].find({
        'division_id' => "ocd-division/country:#{params[:id]}",
        'geonames_id.value' => {'$in' => geonames_id_to_geo.keys},
      }).projection({
        '_id' => 1,
        'geonames_id.value' => 1,
      }).each do |site|
        hash[site['_id']] = site['geonames_id']['value']
      end
    end
  end

  def organization_geometry(result)
    if result['area_ids']
      area_id = result['area_ids'].find{|area_id|
        area_id_to_geoname_id.key?(area_id['id'].try(:[], 'value')) && contemporary?(area_id)
      }
      if area_id
        geonames_id_to_geo.fetch(area_id_to_geoname_id.fetch(area_id['id']['value']))
      else
        sample_area # @production Fake it until more geometries are in the database.
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
      get_properties_safely(commander, ['name'])
    else
      nil
    end
  end

  def get_source_and_target(value)
    if Array === value
      value
    else
      [value, value]
    end
  end

  def get_properties_safely(result, complex_property_names, simple_property_names = [])
    {}.tap do |hash|
      simple_property_names.each do |property_name|
        source, target = get_source_and_target(property_name)
        hash[target] = result[source]
      end
      complex_property_names.each do |property_name|
        source, target = get_source_and_target(property_name)
        hash[target] = result[source].try(:[], 'value')
      end
    end
  end

  def get_relations(result, relation, properties, id_property_name = 'id')
    relation_ids = "#{relation}_ids"
    relations = "#{relation}s"

    result[relation_ids].try(:each_with_index).try(:map) do |relation_id,index|
      item = if result[relations][index]['name']
        {
          'id' => result[relations][index]['id'],
          'name' => result[relations][index]['name'].try(:[], 'value'),
        }.merge(properties.call(result, index))
      else
        {
          'name' => relation_id[id_property_name].try(:[], 'value'),
        }
      end
      item.merge({
        'date_first_cited' => relation_id['date_first_cited'].try(:[], 'value'),
        'date_last_cited' => relation_id['date_last_cited'].try(:[], 'value'),
        'sources' => relation_id[id_property_name]['sources'],
        'confidence' => relation_id[id_property_name]['confidence'],
      })
    end
  end

  def location_formatter(result)
    result['location'].try(:[], 'value') || get_properties_safely(result, ['geonames_name', 'admin_level_1_geonames_name']).values.compact.join(', ')
  end

  def event_formatter(result)
    perpetrator_organization = if result['perpetrator_organization']
      get_properties_safely(result['perpetrator_organization'], ['name', 'other_names'], ['id'])
    else
      get_properties_safely(result, [['perpetrator_organization_id', 'name']])
    end

    get_properties_safely(result, [
      'start_date',
      'end_date',
      'geonames_name',
      'admin_level_1_geonames_name',
      'classification',
      'description',
      'perpetrator_name',
      'sources',
    ], [
      ['_id', 'id'],
      'division_id',
    ]).merge({
      'location' => location_formatter(result),
      'perpetrator_organization' => perpetrator_organization,
    })
  end

  def event_feature_formatter(result)
    {
      'type' => 'Feature',
      'id' => result['_id'],
      'properties' => event_formatter(result).except('id', 'division_id', 'geo', 'description'), # @todo geo
      'geometry' => result['geo'].try(:[], 'coordinates').try(:[], 'value') || sample_point, # @todo geo
    }
  end

  def feature_formatter(result, geometry, properties = nil)
    properties ||= result.except('_id', 'id')

    {
      'type' => 'Feature',
      'id' => result.fetch('_id', result.fetch('id')),
      'properties' => properties,
      'geometry' => geometry,
    }
  end
end

require_relative 'lib/helpers/sample'
require_relative 'lib/events'
require_relative 'lib/countries'
require_relative 'lib/miscellaneous'
require_relative 'lib/organizations'
require_relative 'lib/people'
require_relative 'lib/search'

use Rack::Deflater
run Sinatra::Application
