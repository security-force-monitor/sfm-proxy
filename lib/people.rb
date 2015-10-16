get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
  204
end

get '/people/:id' do
  content_type 'application/json'

  result = connection[:people].find(_id: params[:id]).first

  if result
    memberships = result['memberships'].map do |membership|
      item = membership.except('organization', 'site_id', 'site')

      item['organization'] = if membership['organization']
        {
          'name' => membership['organization']['name']['value'],
        }
      else
        {
          'name' => membership['organization_id']['value'],
        }
      end

      item
    end

    memberships.sort! do |a,b|
      if b['date_first_cited'].try(:[], 'value') && a['date_first_cited'].try(:[], 'value')
        b['date_first_cited'].try(:[], 'value') <=> a['date_first_cited'].try(:[], 'value')
      elsif b['date_first_cited'].try(:[], 'value')
        1
      elsif a['date_first_cited'].try(:[], 'value')
        -1
      else
        0
      end
    end

    site = if memberships[0]['site_id']
      {
        'name' => memberships[0]['site_id']['value']
      }
    elsif memberships[0]['organization']
      site_id, index = memberships[0]['organization']['site_ids'].to_enum.with_index.max_by do |a,index|
        [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max || ''
      end

      site = memberships[0]['organization']['sites'][index]

      site_present = {
        'type' => 'Feature',
        'id' => site_id['id']['value'],
        'properties' => {
          'sources' => site_id['id']['sources'],
          'confidence' => site_id['id']['confidence'],
        },
        'geometry' => site['point'] || sample_point,
      }

      if site['name']
        site_present['properties'].merge!(get_properties_safely(site, ['name', 'geonames_name', 'admin_level_1_geonames_name']).merge({
          'location' => location_formatter(site),
        }))
      end
    end

    etag_and_return({
      'id' => result['_id'],
      'division_id' => result['division_id'],
      'name' => result['name'],
      'other_names' => result['other_names'],
      'memberships' => memberships,
      'area_present' => feature_formatter(memberships[0]['organization'], organization_geometry(memberships[0]['organization']), {}),
      'site_present' => site,
      'events' => [feature_formatter(sample_event, sample_point)],
      'events_nearby' => [feature_formatter(sample_event, sample_point)],
    })
  else
    404
  end
end
