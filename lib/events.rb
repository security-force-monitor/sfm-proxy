get '/countries/:id/events' do
  content_type 'application/json'

  results = connection[:events].find('division_id' => "ocd-division/country:#{params[:id]}")

  etag_and_return(results.map{|result|
    event_feature_formatter(result)
  })
end

get '/events/:id' do
  content_type 'application/json'

  result = connection[:events].find(_id: params[:id]).first

  if result
    etag_and_return(event_formatter(result).merge({
      'organizations_nearby' => [sample_organization],
    }))
  else
    404
  end
end

get '/countries/:id/map' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump('message' => "Missing 'at' parameter")]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump('message' => "Invalid 'at' value")]
  end

  organization_criteria = {
    'division_id' => "ocd-division/country:#{params[:id]}",
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
  }

  if params.key?('classification__in')
    organization_criteria['classification.value'] = {'$in' => params['classification__in'].split(',')}
  end

  organizations = connection[:organizations].find(organization_criteria)

  # @todo Add bbox logic for event coordinates.

  events = connection[:events].find({
    'division_id' => "ocd-division/country:#{params[:id]}",
    'start_date.value' => params[:at],
  })

  etag_and_return({
    'organizations' => organizations.map{|result|
      {
        'type' => 'Feature',
        'id' => result['_id'],
        'properties' => get_properties_safely(result, ['name', 'other_names', 'root_id', 'root_name']).merge({
          'commander_present' => commander_present(result['_id']),
          'events_count' => connection[:events].find('perpetrator_organization_id.value' => result['_id']).count,
        }),
        'geometry' => organization_geometry(result),
      }
    },
    'events' => events.map{|result|
      event_feature_formatter(result)
    },
  })
end
