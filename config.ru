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

  def bounding_box_criterion
    {
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
    }
  end

  # Returns the GeoNames IDs within the bounding box. Since we don't have real
  # relations (and instead have pairs like `area_ids` and `areas`), we need to
  # query the geometries instead of the areas.
  def geonames_id_to_geo
    @geonames_id_to_geo ||= {}.tap do |hash|
      connection[:geometries].find(geo: bounding_box_criterion).projection({
        '_id' => 1,
        'geo' => 1,
      }).each do |document|
        hash[document['_id']] = document['geo']
      end
    end
  end

  # Returns the areas within the given country and bounding box.
  def area_id_to_geoname_id
    @area_id_to_geoname_id ||= {}.tap do |hash|
      connection[:areas].find({
        'division_id' => "ocd-division/country:#{params[:id]}",
        'geonames_id.value' => {'$in' => geonames_id_to_geo.keys},
      }).projection({
        '_id' => 1,
        'geonames_id.value' => 1,
      }).each do |document|
        hash[document['_id']] = document['geonames_id']['value']
      end
    end
  end

  # Returns the organization's current area's geometry.
  def organization_geometry(result)
    if result['area_ids']
      area_id = result['area_ids'].find do |area_id|
        area_id_to_geoname_id.key?(area_id['id'].try(:[], 'value')) && contemporary?(area_id)
      end
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

  def get_relations(result, relation_name, properties, id_property_name = 'id')
    relation_ids = "#{relation_name}_ids"
    relations = "#{relation_name}s"

    result[relation_ids].try(:each_with_index).try(:map) do |relation_id,index|
      relation = result[relations][index]
      item = if relation['name']
        {
          'id' => relation['id'],
          'name' => relation['name'].try(:[], 'value'),
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
    result['location'].try(:[], 'value') || get_properties_safely(result, [
      'geonames_name',
      'admin_level_1_geonames_name',
    ]).values.compact.join(', ')
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
    feature_formatter(result, result['point'] || sample_point, event_formatter(result).except('division_id', 'description'))
  end

  def feature_formatter(result, geometry, properties = nil)
    properties ||= result

    {
      'type' => 'Feature',
      'id' => result['_id'] || result.fetch('id'),
      'properties' => properties.except('_id', 'id', 'geo', 'point'),
      'geometry' => geometry,
    }
  end

private

  def get_source_and_target(value)
    if Array === value
      value
    else
      [value, value]
    end
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
