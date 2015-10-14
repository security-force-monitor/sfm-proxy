helpers do
  def walk_up(result, height = 0)
    parents = []

    result['parent_ids'].try(:each_with_index) do |parent_id,index|
      if contemporary?(parent_id)
        parents << walk_up(result['parents'][index], height + 1)
      end
    end

    if parents.empty?
      [result['id']['value'] || result['id'], height]
    else
      parents.max_by(&:last)
    end
  end

  def walk_down(id)
    response = []

    children = connection[:organizations].find({
      'parent_ids' => {
        '$elemMatch' => {
          '$and' => [
            {
              'id.value' => id,
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

    children.each do |child|
      index = child['parent_ids'].index{|parent_id| parent_id['id']['value'] == id}

      response << {
        'id' => child['_id'],
        'name' => child['name'].try(:[], 'value'),
        'events_count' => connection[:events].find('perpetrator_organization_id.value' => child['_id']).count,
        'parent_id' => id,
        'classification' => child['parent_ids'][index]['classification'].try(:[], 'value'),
        'commander' => commanders_and_people(child['_id'])[:commanders][0],
      }

      response += walk_down(child['_id'])
    end

    response
  end

  def commanders_and_people(organization_id)
    commanders = []
    people = []

    members = connection[:people].find('memberships.organization_id.value' => organization_id)

    members.each do |member|
      member['memberships'].each do |membership|
        if membership['organization_id']['value'] == organization_id
          item = {
            'id' => member['_id'],
            'name' => member['name'].try(:[], 'value'),
            'other_names' => member['other_names'].try(:[], 'value'),
            # @backend `events_count` is equal to the events related to an organization during the membership of the person.
            'events_count' => 12,
            'date_first_cited' => membership['date_first_cited'].try(:[], 'value'),
            'date_last_cited' => membership['date_last_cited'].try(:[], 'value'),
            'sources' => membership['organization_id']['sources'],
            'confidence' => membership['organization_id']['confidence'],
          }

          if membership['role'].try(:[], 'value') == 'Commander'
            commanders << item
          else
            people << item
          end
        end
      end
    end

    commanders = commanders.sort do |a,b|
      b['date_first_cited'].try(:[], 'value') <=> a['date_first_cited'].try(:[], 'value')
    end

    {
      commanders: commanders,
      people: people,
    }
  end
end

get '/organizations/:id/map' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump('message' => "Missing 'at' parameter")]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump('message' => "Invalid 'at' value")]
  end

  result = connection[:organizations].find(_id: params[:id]).first

  if result
    # @todo Add bbox logic for event coordinates.
    events = connection[:events].find({
      'start_date.value' => params[:at],
      'perpetrator_organization_id.value' => result['_id'],
    })

    # @production Fake it until more events are in the database.
    if events.count.zero?
      events = [connection[:events].find.first]
    end

    etag_and_return({
      'area' => feature_formatter(result, organization_geometry(result), {}),
      'sites' => result['site_ids'].each_with_index.select{|site_id,index|
        result['sites'][index]['name'] && contemporary?(site_id)
      }.map{|site_id,index|
        {
          'type' => 'Feature',
          'id' => result['sites'][index]['id'],
          'properties' => {
            'name' => result['sites'][index]['name'].try(:[], 'value'),
            'location' => location_formatter(result['sites'][index]),
            'geonames_name' => result['sites'][index]['geonames_name'].try(:[], 'value'),
            'admin_level_1_geonames_name' => result['sites'][index]['admin_level_1_geonames_name'].try(:[], 'value'),
          },
          'geometry' => result['sites'][index]['geo'].try(:[], 'coordinates').try(:[], 'value'), # @todo geo
        }
      },
      'events' => events.map{|event|
        event_feature_formatter(event)
      },
      'events_nearby' => [feature_formatter(sample_event, sample_point)],
    })
  else
    404
  end
end

get '/organizations/:id/chart' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump('message' => "Missing 'at' parameter")]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump('message' => "Invalid 'at' value")]
  end

  result = connection[:organizations].find(_id: params[:id]).first

  if result
    parent_id, _ = walk_up(result)

    root = connection[:organizations].find(_id: parent_id).first

    response = walk_down(parent_id)

    name = if root
      root['name'].try(:[], 'value')
    else
      parent_id
    end

    response.unshift({
      'id' => parent_id,
      'name' => name,
      'events_count' => connection[:events].find('perpetrator_organization_id.value' => parent_id).count,
      'parent_id' => nil,
      'classification' => nil,
      'commander' => commanders_and_people(parent_id)[:commanders][0],
    })

    etag_and_return(response)
  else
    404
  end
end

get %r{/organizations/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/organizations/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
  204
end

get '/organizations/:id' do
  content_type 'application/json'

  result = connection[:organizations].find(_id: params[:id]).first

  if result
    # Some sites may not have any dates, making sites not comparable.
    site_ids = result['site_ids'].select{|site_id| site_id['date_first_cited'] || site_id['date_last_cited']}

    site_first = site_ids.min_by do |a|
      [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).min
    end
    site_last = site_ids.max_by do |a|
      [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max
    end

    events = connection[:events].find('perpetrator_organization_id.value' => result['_id'])
    children = connection[:organizations].find('parent_ids.id.value' => result['_id'])
    commanders_and_people = commanders_and_people(result['_id'])
    commanders = commanders_and_people[:commanders]
    people = commanders_and_people[:people]

    # @production Fake it until more events are in the database.
    if events.count.zero?
      events = [connection[:events].find.first]
    end

    etag_and_return({
      'id' => result['_id'],
      'division_id' => result['division_id'],
      'name' => result['name'],
      'other_names' => result['other_names'],
      'events_count' => events.count,
      'classification' => result['classification'],
      'root_id' => result['root_id'],
      'root_name' => result['root_name'],
      'date_first_cited' => site_first && [site_first['date_first_cited'], site_first['date_last_cited']].find{|field| field.try(:[], 'value')},
      'date_last_cited' => site_last && [site_last['date_last_cited'], site_last['date_first_cited']].find{|field| field.try(:[], 'value')},
      'commander_present' => commanders[0],
      'commanders_former' => commanders.drop(1),
      'events' => events.map{|event|
        event_formatter(event).except('division_id', 'description', 'perpetrator_organization')
      },
      'parents' => get_relations(result, 'parent', lambda{|result,index|
        {
          'other_names' => result['parents'][index]['other_names'].try(:[], 'value'),
          'events_count' => connection[:events].find('perpetrator_organization_id.value' => result['parents'][index]['id']).count,
          'commander_present' => commanders_and_people(result['parents'][index]['id'])[:commanders][0],
        }
      }),
      'children' => children.map{|child|
        index = child['parent_ids'].index{|parent_id| parent_id['id']['value'] == result['_id']}

        {
          'id' => child['_id'],
          'name' => child['name'].try(:[], 'value'),
          'other_names' => child['other_names'].try(:[], 'value'),
          'events_count' => connection[:events].find('perpetrator_organization_id.value' => child['_id']).count,
          'commander_present' => commanders_and_people(child['_id'])[:commanders][0],
          'date_first_cited' => child['parent_ids'][index]['date_first_cited'].try(:[], 'value'),
          'date_last_cited' => child['parent_ids'][index]['date_last_cited'].try(:[], 'value'),
          'sources' => child['parent_ids'][index]['id']['sources'],
          'confidence' => child['parent_ids'][index]['id']['confidence'],
        }
      },
      'people' => people,
      'memberships' => get_relations(result, 'membership', lambda{|result,index|
        {
          'other_names' => result['memberships'][index]['other_names'].try(:[], 'value'),
        }
      }, 'organization_id'),
      'areas' => get_relations(result, 'area', lambda{|result,index|
        {
          # Nothing to add.
        }
      }),
      'sites' => get_relations(result, 'site', lambda{|result,index|
        {
          'location' => location_formatter(result['sites'][index]),
          'geonames_name' => result['sites'][index]['geonames_name'].try(:[], 'value'),
          'admin_level_1_geonames_name' => result['sites'][index]['admin_level_1_geonames_name'].try(:[], 'value'),
        }
      }),
      'events_nearby' => [sample_event],
    })
  else
    404
  end
end
