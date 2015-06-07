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

  criteria = {
    'division_id' => "ocd-division/country:#{params[:id]}",
  }

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
  longitude_range = Integer(bounding_box[2] * 10_000)...Integer(bounding_box[0] * 10_000)
  latitude_range = Integer(bounding_box[1] * 10_000)...Integer(bounding_box[3] * 10_000)
  events = connection[:events].find(criteria).limit(10)

  etag_and_return({
    "organizations" => organizations.map{|result|
      geometry = if result['area_ids']
        geonames_id_to_geo.fetch(area_id_to_geoname_id.fetch(result['area_ids'].find{|area_id|
          area_id_to_geoname_id.key?(area_id['id'].try(:[], 'value')) && contemporary?(area_id)
        }['id']['value']))
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
    "events" => events.map{|event|
      {
        "type" => "Feature",
        "id" => event['_id'],
        "properties" => event_formatter(event).except('id', 'division_id', 'location', 'description'),
        "geometry" => event['geo'].try(:[], 'coordinates').try(:[], 'value') || {
          "type" => "Point",
          "coordinates" => [rand(longitude_range) / 10_000.0, rand(latitude_range) / 10_000.0],
        },
      }
    },
  })
end
