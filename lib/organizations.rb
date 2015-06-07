helpers do
  def commanders_and_people(organization_id)
    commanders = []
    people = []

    members = connection[:people].find({'memberships.organization_id.value' => organization_id})

    members.each do |member|
      member['memberships'].each do |membership|
        if membership['organization_id']['value'] == organization_id
          item = {
            "id" => member['_id'],
            "name" => member['name'].try(:[], 'value'),
            "other_names" => member['other_names'].try(:[], 'value'),
            # @drupal Add events_count calculated field, equal to the events related to an organization during the membership of the person.
            "events_count" => 12, # @hardcoded
            "date_first_cited" => membership['date_first_cited'].try(:[], 'value'),
            "date_last_cited" => membership['date_last_cited'].try(:[], 'value'),
            "sources" => membership['organization_id']['sources'],
            "confidence" => membership['organization_id']['confidence'],
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

get %r{/organizations/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/organizations/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
  204
end

get '/organizations/:id/map' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump({'message' => "Missing 'at' parameter"})]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump({'message' => "Invalid 'at' value"})]
  end

  result = connection[:organizations].find(_id: params[:id]).first

  if result
    geometry = if result['area_ids']
      area_id = result['area_ids'].find{|area_id|
        area_id_to_geoname_id.key?(area_id['id'].try(:[], 'value')) && contemporary?(area_id)
      }
      if area_id
        geonames_id_to_geo.fetch(area_id_to_geoname_id.fetch(area_id['id']['value']))
      end
    end

    # @note No events have coordinates. Add bbox logic later.
    events = connection[:events].find({
      'start_date.value' => params[:at],
      'perpetrator_organization_id.value' => result['_id'],
    })

    # @todo Fake it until you make it.
    if events.count.zero?
      events = [connection[:events].find.first]
    end

    etag_and_return({
      "area" => {
        "type" => "Feature",
        "id" => result['_id'],
        "properties" => {},
        "geometry" => geometry,
      },
      "sites" => result['site_ids'].each_with_index.select{|site_id,index|
        result['sites'][index]['name'] && contemporary?(site_id)
      }.map{|site_id,index|
        {
          "type" => "Feature",
          "id" => result['sites'][index]['id'],
          "properties" => {
            "name" => result['sites'][index]['name'].try(:[], 'value'),
            "admin_level_1" => result['sites'][index]['admin_level_1'].try(:[], 'value'),
            "admin_level_2" => result['sites'][index]['admin_level_2'].try(:[], 'value'),
          },
          "geometry" => result['sites'][index]['geo'].try(:[], 'coordinates').try(:[], 'value'),
        }
      },
      "events" => events.map{|event|
        event_feature_formatter(event)
      },
      # @drupal Use PostGIS to determine events within a 2km radius of all sites over all time.
      "events_nearby" => [ # @hardcoded
        {
          "type" => "Feature",
          "id" => 'eba734d7-8078-4af5-ae8f-838c0d47fdc0',
          "properties" => {
            "start_date" => '2010-01-01',
            "end_date" => nil,
            "admin_level_1" => 'Abia',
            "admin_level_2" => 'Abia North',
            "classification" => ['Torture', 'Disappearance'],
            "perpetrator_name" => 'Terry Guerrier',
            "perpetrator_organization": {
              "id" => '42bb1cff-eed5-4458-a9b4-b00bad09f615',
              "name" => 'Brigade 1',
            }
          },
          "geometry" => sample_point,
        }
      ]
    })
  else
    404
  end
end

get '/organizations/:id/chart' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump({'message' => "Missing 'at' parameter"})]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump({'message' => "Invalid 'at' value"})]
  end

  etag_and_return({
    # @todo
  })
end

# @drupal Load node from Drupal.
get '/organizations/:id' do
  content_type 'application/json'

  result = connection[:organizations].find(_id: params[:id]).first

  if result
    # Some sites may not have any dates, making sites not comparable.
    site_ids = result['site_ids'].select{|site_id| site_id['date_first_cited'] || site_id['date_last_cited']}

    site_first = site_ids.min do |a,b|
      [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).min <=>
      [b['date_first_cited'].try(:[], 'value'), b['date_last_cited'].try(:[], 'value')].reject(&:nil?).min
    end
    site_last = site_ids.max do |a,b|
      [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max <=>
      [b['date_first_cited'].try(:[], 'value'), b['date_last_cited'].try(:[], 'value')].reject(&:nil?).max
    end

    events = connection[:events].find({'perpetrator_organization_id.value' => result['_id']})
    children = connection[:organizations].find({'parent_ids.id.value' => result['_id']})
    commanders_and_people = commanders_and_people(result['_id'])
    commanders = commanders_and_people[:commanders]
    people = commanders_and_people[:people]

    # @todo Fake it until you make it.
    if events.count.zero?
      events = [connection[:events].find.first]
    end

    etag_and_return({
      "id" => result['_id'],
      "division_id" => result['division_id'],
      "name" => result['name'],
      "other_names" => result['other_names'],
      # @drupal Add events_count calculated field.
      "events_count" => events.count,
      "classification" => result['classification'],
      "root_name" => result['root_name'],
      "date_first_cited" => site_first && [site_first['date_first_cited'], site_first['date_last_cited']].find{|field| field.try(:[], 'value')},
      "date_last_cited" => site_last && [site_last['date_last_cited'], site_last['date_first_cited']].find{|field| field.try(:[], 'value')},
      "commander_present" => commanders[0],
      "commanders_former" => commanders.drop(1),
      "events" => events.map{|event|
        event_formatter(event).except('division_id', 'location', 'description', 'perpetrator_organization')
      },
      "parents" => result['parent_ids'].try(:each_with_index).try(:map){|parent,index|
        item = if result['parents'][index]['name']
          {
            "id" => result['parents'][index]['id'],
            "name" => result['parents'][index]['name'].try(:[], 'value'),
            "other_names" => result['parents'][index]['other_names'].try(:[], 'value'),
            # @drupal Add events_count calculated field.
            "events_count" => connection[:events].find({'perpetrator_organization_id.value' => result['parents'][index]['id']}).count,
            "commander_present" => commanders_and_people(result['parents'][index]['id'])[:commanders][0],
          }
        else
          {
            "name" => parent['id'].try(:[], 'value'),
          }
        end
        item.merge({
          "date_first_cited" => parent['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => parent['date_last_cited'].try(:[], 'value'),
          "sources" => parent['id']['sources'],
          "confidence" => parent['id']['confidence'],
        })
      },
      "children" => children.map{|child|
        index = child['parent_ids'].index{|parent| parent['id']['value'] == result['_id']}

        {
          "id" => child['_id'],
          "name" => child['name'].try(:[], 'value'),
          "other_names" => child['other_names'].try(:[], 'value'),
          # @drupal Add events_count calculated field.
          "events_count" => connection[:events].find({'perpetrator_organization_id.value' => child['_id']}).count,
          "commander_present" => commanders_and_people(child['_id'])[:commanders][0],
          "date_first_cited" => child['parent_ids'][index]['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => child['parent_ids'][index]['date_last_cited'].try(:[], 'value'),
          "sources" => child['parent_ids'][index]['id']['sources'],
          "confidence" => child['parent_ids'][index]['id']['confidence'],
        }
      },
      "people" => people,
      "memberships" => result['membership_ids'].try(:each_with_index).try(:map){|membership,index|
        item = if result['memberships'][index]['name']
          {
            "id" => result['memberships'][index]['id'],
            "name" => result['memberships'][index]['name'].try(:[], 'value'),
            "other_names" => result['memberships'][index]['other_names'].try(:[], 'value'),
          }
        else
          {
            "name" => membership['organization_id'].try(:[], 'value'),
          }
        end
        item.merge({
          "date_first_cited" => membership['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => membership['date_last_cited'].try(:[], 'value'),
          "sources" => membership['organization_id']['sources'],
          "confidence" => membership['organization_id']['confidence'],
        })
      },
      "areas" => result['area_ids'].try(:each_with_index).try(:map){|area,index|
        item = if result['areas'][index]['name']
          {
            "id" => result['areas'][index]['id'],
            "name" => result['areas'][index]['name'].try(:[], 'value'),
          }
        else
          {
            "name" => area['id'].try(:[], 'value'),
          }
        end
        item.merge({
          "date_first_cited" => area['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => area['date_last_cited'].try(:[], 'value'),
          "sources" => area['id']['sources'],
          "confidence" => area['id']['confidence'],
        })
      },
      "sites" => result['site_ids'].each_with_index.map{|site_id,index|
        item = if result['sites'][index]['name']
          {
            "id" => result['sites'][index]['id'],
            "name" => result['sites'][index]['name'].try(:[], 'value'),
            "admin_level_1" => result['sites'][index]['admin_level_1'].try(:[], 'value'),
            "admin_level_2" => result['sites'][index]['admin_level_2'].try(:[], 'value'),
          }
        else
          {
            "name" => site_id['id'].try(:[], 'value'),
          }
        end
        item.merge({
          "date_first_cited" => site_id['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => site_id['date_last_cited'].try(:[], 'value'),
          "sources" => site_id['id']['sources'],
          "confidence" => site_id['id']['confidence'],
        })
      },
      # @drupal Use PostGIS to determine events within a 2km radius of all sites over all time.
      "events_nearby" => [ # @hardcoded
        {
          "id" => 'eba734d7-8078-4af5-ae8f-838c0d47fdc0',
          "start_date" => '2010-01-01',
          "end_date" => nil,
          "admin_level_1" => 'Abia',
          "admin_level_2" => 'Abia North',
          "classification" => ['Torture', 'Disappearance'],
          "perpetrator_name" => 'Terry Guerrier',
          "perpetrator_organization": {
            "id" => '42bb1cff-eed5-4458-a9b4-b00bad09f615',
            "name" => 'Brigade 1',
          }
        }
      ]
    })
  else
    404
  end
end
