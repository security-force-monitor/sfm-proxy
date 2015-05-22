helpers do
  def search(collection_name, criteria_map, order_map, facets_map, result_formatter)
    collection = connection[collection_name]

    criteria = {
      'division_id' => "ocd-division/country:#{params[:id]}"
    }
    criteria_map.each do |key,(field,operator,options)|
      if params.key?(key.to_s)
        value = params[key]
        value = value.split(',') if options && options[:split]
        criteria[field] ||= {}
        criteria[field][operator] = value
      end
    end

    query = sort(collection.find(criteria), order_map)

    facets = {}
    facets_map.each do |facet,(field,options)|
      pipeline = [
        {
          '$match' => criteria,
        }
      ]
      if options && options[:unwind]
        pipeline << {
          '$unwind' => field,
        }
      end
      pipeline << {
        '$group' => {
          _id: field,
          count: {
            '$sum' => 1,
          },
        },
      }
      facets[facet] = collection.aggregate(pipeline).map do |group|
        [group['_id'], group['count']] # equivalent to json.nl=arrarr in Solr
      end
    end

    results = paginate(query).map do |result|
      result_formatter.call(result)
    end

    etag_and_return({
      "count" => query.count,
      "facets" => facets,
      "results" => results,
    })
  end

  def sort(query, valid)
    o = params.fetch('o', '_score')

    direction = if o[0] == '-'
      field = o[1..-1]
      direction = -1
    else
      field = o
      direction = 1
    end

    # Score has one direction.
    if field == '_score'
      direction = -1
    end

    # @drupal Use Search API with ElasticSearch to sort by _score.
    # valid << '_score'
    if valid.include?(field)
      query.sort(field => direction)
    else
      query
    end
  end

  def paginate(query)
    offset = [params.fetch('p', 1).to_i, 1].max - 1
    query.skip(offset * 20).limit(20)
  end
end

# @drupal ZIP file generated on-demand.
get %r{/countries/([a-z]{2})/search/organizations.zip} do |id|
  204
end
get %r{/countries/([a-z]{2})/search/people.zip} do |id|
  204
end
get %r{/countries/([a-z]{2})/search/events.zip} do |id|
  204
end

# @drupal Text file generated on-demand.
get %r{/countries/([a-z]{2})/search/organizations.txt} do |id|
  204
end
get %r{/countries/([a-z]{2})/search/people.txt} do |id|
  204
end
get %r{/countries/([a-z]{2})/search/events.txt} do |id|
  204
end

get '/autocomplete/geonames_id' do
  response = CSV.foreach(File.expand_path(File.join('..', 'data', 'geonames', 'NG.txt'), __dir__), col_sep: "\t").map do |row|
    {
      id: Integer(row[0]),
      name: row[1],
    }
  end

  etag_and_return(response)
end

# @drupal Perform search on Drupal.
get '/countries/:id/search/organizations' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    site = result['site_ids'].max do |a,b|
      ([a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max || '') <=>
      ([b['date_first_cited'].try(:[], 'value'), b['date_last_cited'].try(:[], 'value')].reject(&:nil?).max || '')
    end

    site_present = {
      "date_first_cited" => site['date_first_cited'].try(:[], 'value'),
      "date_last_cited" => site['date_last_cited'].try(:[], 'value'),
    }
    if site['name']
      site_present['admin_level_1'] = site['admin_level_1'].try(:[], 'value')
      site_present['admin_level_2'] = site['admin_level_2'].try(:[], 'value')
    end

    {
      "id" => result['_id'],
      "name" => result['name'].try(:[], 'value'),
      "other_names" => result['other_names'].try(:[], 'value'),
      # @drupal Add events_count calculated field.
      "events_count" => connection[:events].find({'perpetrator_organization_id.value' => result['_id']}).count,
      "classification" => result['classification'].try(:[], 'value'),
      "site_present" => site_present,
      "commander_present" => commander_present(result['_id']),
    }
  end

  search(:organizations, {
    # @drupal Use Search API with ElasticSearch to support matching the full document.
    q: ['name.value', '$regex'],
    # @drupal Submit string to Google Maps API to get coordinates, and submit to API to do radius search with PostGIS.
    geonames_id: ['geonames_id.value', '$eq'],
    classification__in: ['classification.value', '$in', split: true],
    date_first_cited__gte: ['sites.date_first_cited.value', '$gte'],
    date_first_cited__lte: ['sites.date_first_cited.value', '$lte'],
    date_last_cited__gte: ['sites.date_last_cited.value', '$gte'],
    date_last_cited__lte: ['sites.date_last_cited.value', '$lte'],
    # @drupal Add events_count calculated field.
    events_count__gte: ['events_count', '$gte'],
    events_count__lte: ['events_count', '$lte'],
  }, {
    'name' => 'name.value',
    'date_first_cited' => 'sites.date_first_cited.value', # XXX don't know if this sorts correctly
    'date_last_cited' => 'sites.date_last_cited.value', # XXX don't know if this sorts correctly
    'events_count' => 'events_count',
  }, {
    'classification' => ['$classification.value'],
  }, result_formatter)
end

# @drupal Perform search on Drupal.
get '/countries/:id/search/people' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    memberships = result['memberships'].max(2) do |a,b|
      ([a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max || '') <=>
      ([b['date_first_cited'].try(:[], 'value'), b['date_last_cited'].try(:[], 'value')].reject(&:nil?).max || '')
    end

    membership_present, membership_former = memberships.map do |membership|
      organization = if membership['organization']
        {
          "name" => membership['organization']['name'].try(:[], 'value'),
        }
      else
        {
          "name" => membership['organization_id'].try(:[], 'value'),
        }
      end

      {
        "organization" => organization,
        "role" => membership['role'].try(:[], 'value'),
        "title" => membership['role'].try(:[], 'value'),
        "rank" => membership['role'].try(:[], 'value'),
      }
    end

    if memberships[0]['organization']
      site = memberships[0]['organization']['site_ids'].max do |a,b|
        [a['date_first_cited'].try(:[], 'value'), a['date_last_cited'].try(:[], 'value')].reject(&:nil?).max <=>
        [b['date_first_cited'].try(:[], 'value'), b['date_last_cited'].try(:[], 'value')].reject(&:nil?).max
      end

      if site['name']
        membership_present['organization']['site_present'] = {
          "admin_level_1" => site['admin_level_1'].try(:[], 'value'),
          "admin_level_2" => site['admin_level_2'].try(:[], 'value'),
        }
      end
    end

    {
      "id" => result['_id'],
      "name" => result['name'].try(:[], 'value'),
      "other_names" => result['other_names'].try(:[], 'value'),
      # @drupal Add events_count calculated field, equal to the events related to an organization during the membership of the person.
      "events_count" => 12, # @hardcoded
      "membership_present" => membership_present,
      "membership_former" => membership_former,
    }
  end

  search(:people, {
    # @drupal Use Search API with ElasticSearch to support matching the full document.
    q: ['name.value', '$regex'],
    # @drupal Submit string to Google Maps API to get coordinates, and submit to API to do radius search with PostGIS.
    geonames_id: ['memberships.site.geonames_id.value', '$eq'],
    classification__in: ['memberships.organization.classification.value', '$in', split: true],
    rank__in: ['memberships.rank.value', '$in', split: true],
    role__in: ['memberships.role.value', '$in', split: true],
    date_first_cited__gte: ['memberships.date_first_cited.value', '$gte'],
    date_first_cited__lte: ['memberships.date_first_cited.value', '$lte'],
    date_last_cited__gte: ['memberships.date_last_cited.value', '$gte'],
    date_last_cited__lte: ['memberships.date_last_cited.value', '$lte'],
    # @drupal Add events_count calculated field, equal to the events related to an organization during the membership of the person.
    events_count__gte: ['events_count', '$gte'],
    events_count__lte: ['events_count', '$lte'],
  }, {
    'name' => 'name.value',
    'events_count' => 'events_count',
  }, {
    'rank' => ['$memberships.rank.value'],
    'role' => ['$memberships.role.value'],
  }, result_formatter)
end

# @drupal Perform search on Drupal.
get '/countries/:id/search/events' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    event_formatter(result).except('division_id', 'location', 'description').merge({
      # @drupal How expensive is it to do radius search for each result in PostGIS?
      "sites_nearby" => [ # @hardcoded
        {
          "name" => "Atlantis",
        },
      ],
    })
  end

  search(:events, {
    # @drupal Use Search API with ElasticSearch to support matching the full document.
    q: ['description.value', '$regex'],
    # @drupal Submit string to Google Maps API to get coordinates, and submit to API to do radius search with PostGIS.
    geonames_id: ['geonames_id.value', '$eq'],
    classification__in: ['classification.value', '$in', split: true],
    start_date__gte: ['start_date.value', '$gte'],
    start_date__lte: ['start_date.value', '$lte'],
  }, {
    'start_date' => 'start_date.value',
  }, {
    'classification' => ['$classification.value', unwind: true],
  }, result_formatter)
end
