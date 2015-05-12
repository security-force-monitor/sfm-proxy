get '/organizations/:id.zip' do
  204
end
get '/organizations/:id.txt' do
  204
end

get '/organizations/:id/map' do
  content_type 'application/json'

  JSON.dump({
    # @todo
  })
end

get '/organizations/:id/chart' do
  content_type 'application/json'

  JSON.dump({
    # @todo
  })
end

# @drupal Load node from Drupal.
get '/organizations/:id' do
  content_type 'application/json'

  result = connection[:organizations].find(_id: params[:id]).first

  # Some sites may not have any dates, making sites not comparable.
  site_ids = result['site_ids'].select{|site| site['date_first_cited'] || site['date_last_cited']}

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
  commanders = []
  people = []

  # @todo Fake it until you can make it.
  if events.count.zero?
    events = [connection[:events].find({'perpretrator_name.value' => {'$exists' => true}}).first]
  end

  members = connection[:people].find({
    'memberships.organization_id.value' => result['_id'],
  })

  members.each do |member|
    member['memberships'].each do |membership|
      if membership['organization_id']['value'] == result['_id']
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

  if result
    JSON.dump({
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
        {
          "id" => event['_id'],
          "date" => event['date'].try(:[], 'value'),
          "location_admin_level_1" => event['location_admin_level_1'].try(:[], 'value'),
          "location_admin_level_2" => event['location_admin_level_2'].try(:[], 'value'),
          "classification" => event['classification'].try(:[], 'value'),
          "perpretrator_name" => event['perpretrator_name'].try(:[], 'value'),
        }
      },
      "parents" => result['parent_ids'].try(:each_with_index).try(:map){|parent,index|
        item = if result['parents'][index]['name']
          {
            "id" => result['parents'][index]['id'],
            "name" => result['parents'][index]['name'].try(:[], 'value'),
            "other_names" => result['parents'][index]['other_names'].try(:[], 'value'),
            # @drupal Add events_count calculated field.
            "events_count" => connection[:events].find({'perpetrator_organization_id.value' => result['parents'][index]['id']}).count,
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
      "sites" => result['site_ids'].each_with_index.map{|site,index|
        item = if result['sites'][index]['name']
          {
            "id" => result['sites'][index]['id'],
            "name" => result['sites'][index]['name'].try(:[], 'value'),
            "admin_level_1" => result['sites'][index]['admin_level_1'].try(:[], 'value'),
            "admin_level_2" => result['sites'][index]['admin_level_2'].try(:[], 'value'),
          }
        else
          {
            "name" => site['id'].try(:[], 'value'),
          }
        end
        item.merge({
          "date_first_cited" => site['date_first_cited'].try(:[], 'value'),
          "date_last_cited" => site['date_last_cited'].try(:[], 'value'),
          "sources" => site['id']['sources'],
          "confidence" => site['id']['confidence'],
        })
      },
      # @drupal Use PostGIS to determine events within a 2km radius of all sites over all time.
      "events_nearby" => [ # @hardcoded
        {
          "id" => 'eba734d7-8078-4af5-ae8f-838c0d47fdc0',
          "date" => '2010-01-01',
          "location_admin_level_1" => 'Abia',
          "location_admin_level_2" => 'Abia North',
          "classification" => ['Torture', 'Disappearance'],
          "perpretrator_name" => 'Terry Guerrier',
        }
      ]
    })
  else
    404
  end
end
