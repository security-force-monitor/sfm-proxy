get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
  204
end

# @backend Load node from Drupal.
get '/people/:id' do
  content_type 'application/json'

  result = connection[:people].find(_id: params[:id]).first

  if result
    memberships = result['memberships'].map do |membership|
      item = membership.except('organization', 'site_id', 'site')

      item['organization'] = if membership['organization']
        {
          "name" => membership['organization']['name']['value'],
        }
      else
        {
          "name" => membership['organization_id']['value'],
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
        "name" => memberships[0]['site_id']['value']
      }
    elsif memberships[0]['organization']
      { # @backend @hardcoded
        "type" => "Feature",
        "id" => "5947d0de-626d-495f-9c31-eb2ca5afdb6b",
        "name" => "Command Center",
        "location" => "Abia North, Abia",
        "geonames_name" => "Abia North",
        "admin_level_1_geonames_name" => "Abia",
        "sources" => [
          "..."
        ],
        "confidence" => "Medium",
      }
    end

    etag_and_return({
      "id" => result['_id'],
      "division_id" => result['division_id'],
      "name" => result['name'],
      "other_names" => result['other_names'],
      "memberships" => memberships,
      "area_present" => {
        "type" => "Feature",
        "id" => memberships[0]['organization']['id'],
        "properties" => {},
        "geometry" => organization_geometry(memberships[0]['organization']),
      },
      "site_present" => site,
      # @backend @hardcoded Add events related to an organization during the membership of the person.
      "events" => [sample_event],
      # @backend @hardcoded Add events near an organization during the membership of the person.
      "events_nearby" => [sample_event],
    })
  else
    404
  end
end
