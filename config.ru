require 'rubygems'
require 'bundler/setup'

require 'json'

require 'active_support/core_ext/hash/slice'
require 'pupa'

helpers do
  def connection
    uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
    connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
    connection.login(uri.user, uri.password) if uri.user && uri.password
    connection
  end

  def event_formatter(event)
    perpetrator_organization = if event['perpetrator_organization']
      {
        "id" => event['perpetrator_organization']['id'],
        "name" => event['perpetrator_organization']['name']['value'],
        "other_names" => event['perpetrator_organization']['other_names']['value'],
      }
    else
      {
        "name" => event['perpetrator_organization_id']['value'],
      }
    end

    {
      "id" => event['_id'],
      "division_id" => event['division_id'],
      "date" => event['date']['value'],
      "location_description" => event['location_description']['value'],
      "location_admin_level_1" => event['location_admin_level_1']['value'],
      "location_admin_level_2" => event['location_admin_level_2']['value'],
      "classification" => event['classification']['value'],
      "description" => event['description']['value'],
      "perpretrator_name" => event['perpretrator_name']['value'],
      "perpetrator_organization" => perpetrator_organization,
    }
  end

  def search(collection_name, criteria_map, order_map, facets_map, result_formatter)
    collection = connection[collection_name]

    criteria = {}
    criteria_map.each do |key,(field,operator,options)|
      if params.key?(key)
        value = params[key]
        value = value.split(',') if options && options[:split]
        criteria[field] ||= {}
        criteria[field][operator] = value
      end
    end

    matches = sort(collection.find(criteria), order_map)

    facets = {}
    facets_map.each do |facet,(field,options)|
      pipeline = [{
        '$match' => criteria,
      }]
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
        [group['_id'], group['count']]
      end
    end

    results = paginate(matches).map do |result|
      formatter.call(result)
    end

    JSON.dump({
      "count": matches.count,
      "facets": facets,
      "results": results,
    })
  end

  def sort(query, valid)
    o = params.fetch(:o, '_score')

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
    offset = [params.fetch(:p, 1).to_i, 1].max - 1
    matches.skip(offset * 20).limit(20)
  end
end

# @drupal Load list of nodes from Drupal. TopoJSON files are created by drush command.
get '/countries' do
  content_type 'application/json'

  dir = File.expand_path('topojson', __dir__)

  JSON.dump({
    [
      {
        "id" => "eg",
        "name" => "Egypt",
        "geometry" => JSON.load(File.read(File.join(dir, 'eg.topojson'))),
      },
      {
        "id" => "mx",
        "name" => "Mexico",
        "geometry" => JSON.load(File.read(File.join(dir, 'mx.topojson'))),
      },
      {
        "id" => "ng",
        "name" => "Nigeria",
        "geometry" => JSON.load(File.read(File.join(dir, 'ng.topojson'))),
      },
    ],
  })
end

# @drupal Load node from Drupal.
get '/countries/:code' do
  content_type 'application/json'

  if params[:code] == 'ng'
    JSON.dump({
      "id" => "ng",
      "name" => "Nigeria",
      "title" => "Federal Republic of Nigeria",
      "description" => "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In purus massa, porta non tincidunt vitae, efficitur malesuada risus. Morbi vitae leo a sapien sodales aliquam. Suspendisse convallis aliquam metus nec efficitur. Integer massa mi, mattis sit amet turpis eget, aliquam volutpat lacus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Quisque eget consequat leo, sit amet semper felis. Proin vitae dapibus magna. Duis laoreet orci lacus, vitae malesuada felis consectetur a.\n\nCurabitur cursus leo sed turpis rhoncus consequat. Proin ornare egestas velit, at ornare arcu tristique ac. Ut pulvinar elit mauris, a tempus arcu pharetra nec. Vestibulum tristique interdum nulla eget pellentesque. Vivamus ac risus in quam fermentum fermentum. Ut et felis lorem. Sed eu porta purus. Donec aliquam dictum risus, id iaculis nunc mattis in. Praesent ac sapien ac sem euismod semper ac sed nibh. Quisque sit amet volutpat libero, in iaculis diam. Maecenas commodo nunc ut velit auctor pharetra. Donec et augue venenatis mi rutrum consectetur.\n\nMauris laoreet sed sapien eget aliquam. Cras tincidunt malesuada magna nec molestie. Phasellus in velit a metus luctus varius. In eleifend consequat dui, vel venenatis enim commodo vitae. Ut nec luctus felis, cursus euismod neque. Nullam eros justo, euismod sit amet accumsan quis, fermentum eget nibh. Vestibulum mattis mauris et ante elementum, quis placerat justo dapibus. Ut tincidunt erat at libero dignissim, ut lobortis sem fringilla. Cras luctus dapibus nisi vehicula pharetra. Nam in est sed tellus mollis tempor.\n\nEtiam at lectus elit. Donec tristique ex in diam dignissim elementum. Donec id nulla vitae augue porttitor efficitur. Aenean a sodales sem. Nullam egestas massa a maximus tristique. Phasellus non porttitor odio, vitae iaculis augue. Cras sit amet mi ultricies, elementum nisi sed, maximus felis. Ut dapibus massa ut elit ullamcorper gravida. Nullam vehicula leo lacus, id lacinia metus aliquet vel. Nullam laoreet elit accumsan ultrices finibus. Maecenas a malesuada nisi. Duis maximus enim lacinia sagittis pulvinar. Etiam malesuada ante eget volutpat condimentum.\n\nDonec sodales nunc sit amet libero interdum venenatis a sit amet tellus. Quisque a tristique nulla. Donec pellentesque euismod purus vel ullamcorper. Nulla turpis velit, scelerisque eget felis id, consequat maximus est. Cras maximus tristique quam quis consequat. Duis condimentum pellentesque ultrices. Nam malesuada lacinia eleifend. Quisque nec convallis ex. Nam ut enim suscipit, rhoncus nisi sed, volutpat dolor. Curabitur efficitur sodales purus ac semper. Aenean facilisis nibh non augue aliquet ornare. Integer at augue ut risus hendrerit scelerisque. In tincidunt a leo rhoncus vestibulum. Integer sodales arcu ligula, eu imperdiet arcu faucibus nec. Ut pellentesque sagittis placerat.",
      "events_count" => 1234, # @drupal Add events_count calculated field.
    })
  else
    204
  end
end

# @drupal Daily or hourly ron job to create and ZIP CSV files for download.
get '/countries/:code.zip' do
  204
end

# @drupal Daily or hourly ron job to create text files for download.
get '/countries/:code.txt' do
  204
end

# @drupal Load node from Drupal.
get '/events/:id' do
  content_type 'application/json'

  event = connection[:events].find(_id: params[:id]).first

  if event
    JSON.dump(event_formatter.merge({
      "organizations_nearby" => [ # @todo
        {
          "id" => "123e4567-e89b-12d3-a456-426655440000",
          "name" => "Brigade 2",
          "other_names" => [
            "The Planeteers",
          ],
          "root_name" => "Nigerian Army",
          "person_name" => "Michael Maris",
          "events_count" => 12, # @drupal Add events_count calculated field.
        },
      ],
    }))
  else
    404
  end
end

# @drupal Load node from Drupal.
get '/organizations/:id' do
  content_type 'application/json'

  organization = connection[:organizations].find(_id: params[:id]).first

  if organization
    JSON.dump({
      # @todo
    })
  else
    404
  end
end

# @drupal Load node from Drupal.
get '/people/:id' do
  content_type 'application/json'

  person = connection[:people].find(_id: params[:id]).first

  if person
    JSON.dump({
      # @todo
    })
  else
    404
  end
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

get '/people/:id/chart' do
  content_type 'application/json'

  JSON.dump({
    # @todo
  })
end

get '/map' do
  content_type 'application/json'

  JSON.dump({
    # @todo
  })
end

# @drupal Perform search on Drupal.
get '/search/organizations' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    {
      "id": result['_id'],
      "name": result['name']['value'],
      "other_names": result['other_names']['value'],
      "date_first_cited": result['date_first_cited']['value'],
      "date_last_cited": result['date_last_cited']['value'],
      "events_count": 12, # @drupal Add events_count calculated field.
      # @todo admin_level_1, admin_level_2, commander
    }
  end

  search(:organizations, {
    q: ['name.value', '$regex'], # @drupal Use Search API with ElasticSearch to support matching the full document.
    geonames_id: ['geonames_id.value', '$eq'],
    classification__in: ['classification.value', '$in', split: true],
    date_first_cited__gte: ['date_first_cited.value', '$gte'],
    date_first_cited__lte: ['date_first_cited.value', '$lte'],
    date_last_cited__gte: ['date_last_cited.value', '$gte'],
    date_last_cited__lte: ['date_last_cited.value', '$lte'],
    # @drupal Add events_count calculated field.
    events_count__gte: ['events_count', '$gte'],
    events_count__lte: ['events_count', '$lte'],    
  }, {
    'name' => 'name.value',
    'date_first_cited' => 'date_first_cited.value',
    'date_last_cited' => 'date_last_cited.value',
    'events_count' => 'events_count',
  }, {
  }, result_formatter)
end

# @drupal Perform search on Drupal.
get '/search/people' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    {
      "id": result['_id'],
      "name": result['name']['value'],
      "other_names": result['other_names']['value'],
      # @todo
    }
  end

  search(:people, {
    q: ['name.value', '$regex'], # @drupal Use Search API with ElasticSearch to support matching the full document.
    geonames_id: ['memberships.site.geonames_id.value', '$eq'],
    classification__in: ['memberships.organization.classification.value', '$in', split: true]
    rank__in: ['memberships.rank.value', '$in', split: true]
    role__in: ['memberships.role.value', '$in', split: true]
    date_first_cited__gte: ['memberships.date_first_cited.value', '$gte'],
    date_first_cited__lte: ['memberships.date_first_cited.value', '$lte'],
    date_last_cited__gte: ['memberships.date_last_cited.value', '$gte'],
    date_last_cited__lte: ['memberships.date_last_cited.value', '$lte'],
    # @drupal Add events_count calculated field.
    events_count__gte: ['memberships.organization.events_count', '$gte'],
    events_count__lte: ['memberships.organization.events_count', '$lte'],
  }, {
    'name' => 'name.value',
    'events_count' => 'memberships.organization.events_count',
  }, {
    'rank' => ['$memberships.rank.value'],
    'role' => ['$memberships.role.value'],
  }, result_formatter)
end

# @drupal Perform search on Drupal.
get '/search/events' do
  content_type 'application/json'

  search(:events, {
    q: ['description.value', '$regex'], # @drupal Use Search API with ElasticSearch to support matching the full document.
    geonames_id: ['geonames_id.value', '$eq'],
    classification__in: ['classification.value', '$in', split: true]
    date__gte: ['date.value', '$gte'],
    date__lte: ['date.value', '$lte'],
  }, {
    'date' => 'date.value',
  }, {
    'classification' => ['$classification.value', unwind: true],
  }, method(:event_formatter))
end

# @drupal ZIP files generated on-demand.
get '/search/organizations.zip' do
  204
end
get '/search/people.zip' do
  204
end
get '/search/events.zip' do
  204
end

# @drupal Text files generated on-demand.
get '/search/organizations.txt' do
  204
end
get '/search/people.txt' do
  204
end
get '/search/events.txt' do
  204
end

get '/autocomplete/geonames_id' do
  # @todo
end
