NUMERIC = /-?\d+(?:\.\d+)?/

# @drupal Load nodes from Drupal.
get '/countries/:id/events' do
  content_type 'application/json'

  results = connection[:events].find({'division_id' => "ocd-division/country:#{params[:id]}"})

  response = results.map do |result|
    {
      "id" => result['_id'],
      "start_date" => result['start_date'].try(:[], 'value'),
      "end_date" => result['end_date'].try(:[], 'value'),
    }
  end

  etag_and_return(response)
end

# @drupal Load node from Drupal.
get '/events/:id' do
  content_type 'application/json'

  result = connection[:events].find(_id: params[:id]).first

  if result
    etag_and_return(event_formatter(result).merge({
      # @drupal Use PostGIS to determine areas and sites within a 2km radius of event.
      "organizations_nearby" => [ # @hardcoded
        {
          "id" => "123e4567-e89b-12d3-a456-426655440000",
          "name" => "Brigade 2",
          "other_names" => [
            "The Planeteers",
          ],
          # @drupal Add root_id denormalized field.
          "root_name" => "Nigerian Army",
          "person_name" => "Michael Maris",
          # @drupal Add events_count calculated field.
          "events_count" => 12,
        },
      ],
    }))
  else
    404
  end
end

get '/countries/:id/map' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump({'message' => "Missing 'at' parameter"})]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump({'message' => "Invalid 'at' value"})]
  end

  if params.key?('bbox')
    if !params[:bbox].match(/\A#{NUMERIC},#{NUMERIC},#{NUMERIC},#{NUMERIC}\z/)
      return [400, JSON.dump({'message' => "Invalid 'bbox' value"})]
    end
    coordinates = params[:bbox].split(',').map{|coordinate| Float(coordinate)}
  else
    coordinates = [14.5771, 4.2405, 2.6917, 13.8659] # @hardcoded Nigeria west-south, east-north
  end

  criteria = {
    'division_id' => "ocd-division/country:#{params[:id]}",
  }

  # @drupal Switch to PostGIS query. Just match on ADM1 for now.
  geonames_id_to_geo = {}

  connection[:geometries].find({
    classification: 'ADM1',
    geo: {
      '$geoIntersects' => {
        '$geometry' => {
          type: 'Polygon',
          coordinates: [[
            [coordinates[0], coordinates[1]],
            [coordinates[2], coordinates[1]],
            [coordinates[2], coordinates[3]],
            [coordinates[0], coordinates[3]],
            [coordinates[0], coordinates[1]],
          ]]
        }
      },
    },
  }).select(_id: 1, geo: 1).each do |geometry|
    geonames_id_to_geo[geometry['_id']] = geometry['geo']
  end

  area_id_to_geoname_id = {}

  connection[:areas].find(criteria.merge({
    'geonames_id.value' => {'$in' => geonames_id_to_geo.keys},
  })).select('_id' => 1, 'geonames_id.value' => 1).each do |area|
    area_id_to_geoname_id[area['_id']] = area['geonames_id']['value']
  end

  organization_criteria = criteria.merge({
    'area_ids' => {
      '$elemMatch' => {
        '$and' => [
          {
            'id.value' => {'$in' => area_id_to_geoname_id.keys},
          },
          {
            '$or' => [
              {'date_first_cited.value' => nil},
              {'date_first_cited.value' => {'$lte' => params[:at]}},
            ],
          },
          {
            '$or' => [
              {'date_last_cited.value' => nil},
              {'date_last_cited.value' => {'$gte' => params[:at]}},
            ],
          },
        ],
      },
    },
  })

  if params.key?('classification__in')
    organization_criteria['classification.value'] = {'$in' => params['classification__in'].split(',')}
  end

  organizations = connection[:organizations].find(organization_criteria)

  # @note No events have coordinates. Add date and bbox logic and remove this dummy code later.
  longitude_range = Integer(coordinates[2] * 10_000)...Integer(coordinates[0] * 10_000)
  latitude_range = Integer(coordinates[1] * 10_000)...Integer(coordinates[3] * 10_000)
  events = connection[:events].find(criteria).limit(10)

  etag_and_return({
    "organizations" => organizations.map{|result|
      geometry = if result['area_ids']
        area_id = result['area_ids'].find do |area_id|
          area_id_to_geoname_id.key?(area_id['id'].try(:[], 'value')) &&
          (area_id['date_first_cited'].try(:[], 'value').nil? || area_id['date_first_cited']['value'] <= params[:at]) &&
          (area_id['date_last_cited'].try(:[], 'value').nil? || area_id['date_last_cited']['value'] >= params[:at])
        end['id']['value']

        geonames_id_to_geo.fetch(area_id_to_geoname_id.fetch(area_id))
      end

      {
        "type" => "Feature",
        "id" => result['_id'],
        "properties" => {
          "name" => result['name'].try(:[], 'value'),
          "other_names" => result['other_names'].try(:[], 'value'),
          "root_name" => result['root_name'].try(:[], 'value'),
          "commander_present" => commander_present(result['_id']),
          "events_count" => connection[:events].find({'perpetrator_organization_id.value' => result['_id']}).count,
        },
        "geometry" => geometry,
      }
    },
    "events" => events.map{|result|
      {
        "type" => "Feature",
        "id" => result['_id'],
        "properties" => event_formatter(result).except('id', 'division_id', 'location', 'description'),
        "geometry" => result['geo'] || {
          "type" => "Point",
          "coordinates" => [rand(longitude_range) / 10_000.0, rand(latitude_range) / 10_000.0],
        },
      }
    },
  })
end
