require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'

require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/object/try'
require 'pupa'
require 'sinatra'

helpers do
  def connection
    @connection ||= begin
      uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
      connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
      connection.login(uri.user, uri.password) if uri.user && uri.password
      connection
    end
  end

  def event_formatter(result)
    perpetrator_organization = if result['perpetrator_organization']
      {
        "id" => result['perpetrator_organization']['id'],
        "name" => result['perpetrator_organization']['name'].try(:[], 'value'),
        "other_names" => result['perpetrator_organization']['other_names'].try(:[], 'value'),
      }
    else
      {
        "name" => result['perpetrator_organization_id'].try(:[], 'value'),
      }
    end

    {
      "id" => result['_id'],
      "division_id" => result['division_id'],
      "date" => result['date'].try(:[], 'value'),
      "location_description" => result['location_description'].try(:[], 'value'),
      "location_admin_level_1" => result['location_admin_level_1'].try(:[], 'value'),
      "location_admin_level_2" => result['location_admin_level_2'].try(:[], 'value'),
      "classification" => result['classification'].try(:[], 'value'),
      "description" => result['description'].try(:[], 'value'),
      "perpretrator_name" => result['perpretrator_name'].try(:[], 'value'),
      "perpetrator_organization" => perpetrator_organization,
    }
  end

  def search(collection_name, criteria_map, order_map, facets_map, result_formatter)
    collection = connection[collection_name]

    criteria = {
      'division_id' => "ocd-division/country:#{params[:id]}"
    }
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

    results = paginate(matches).map do |result|
      formatter.call(result)
    end

    JSON.dump({
      "count" => matches.count,
      "facets" => facets,
      "results" => results,
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

  dir = File.expand_path(File.join('geo', 'topojson', 'adm0'), __dir__)

  JSON.dump([
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
  ])
end

# @drupal Load node from Drupal.
get '/countries/:id' do
  content_type 'application/json'

  if params[:id] == 'ng'
    JSON.dump({
      "id" => "ng",
      "name" => "Nigeria",
      "title" => "Federal Republic of Nigeria",
      # @drupal Add events_count calculated field.
      "events_count" => connection[:events].find({'division_id' => 'ocd-division/country:ng'}).count,
      "description" => <<-EOL
Lorem ipsum dolor sit amet, consectetur adipiscing elit. In purus massa, porta non tincidunt vitae,
efficitur malesuada risus. Morbi vitae leo a sapien sodales aliquam. Suspendisse convallis aliquam
metus nec efficitur. Integer massa mi, mattis sit amet turpis eget, aliquam volutpat lacus. Lorem
ipsum dolor sit amet, consectetur adipiscing elit. Class aptent taciti sociosqu ad litora torquent
per conubia nostra, per inceptos himenaeos. Quisque eget consequat leo, sit amet semper felis. Proin
vitae dapibus magna. Duis laoreet orci lacus, vitae malesuada felis consectetur a.\n\nCurabitur
cursus leo sed turpis rhoncus consequat. Proin ornare egestas velit, at ornare arcu tristique ac. Ut
pulvinar elit mauris, a tempus arcu pharetra nec. Vestibulum tristique interdum nulla eget
pellentesque. Vivamus ac risus in quam fermentum fermentum. Ut et felis lorem. Sed eu porta purus.
Donec aliquam dictum risus, id iaculis nunc mattis in. Praesent ac sapien ac sem euismod semper ac
sed nibh. Quisque sit amet volutpat libero, in iaculis diam. Maecenas commodo nunc ut velit auctor
pharetra. Donec et augue venenatis mi rutrum consectetur.\n\nMauris laoreet sed sapien eget aliquam.
Cras tincidunt malesuada magna nec molestie. Phasellus in velit a metus luctus varius. In eleifend
consequat dui, vel venenatis enim commodo vitae. Ut nec luctus felis, cursus euismod neque. Nullam
eros justo, euismod sit amet accumsan quis, fermentum eget nibh. Vestibulum mattis mauris et ante
elementum, quis placerat justo dapibus. Ut tincidunt erat at libero dignissim, ut lobortis sem
fringilla. Cras luctus dapibus nisi vehicula pharetra. Nam in est sed tellus mollis tempor.\n\nEtiam
at lectus elit. Donec tristique ex in diam dignissim elementum. Donec id nulla vitae augue porttitor
efficitur. Aenean a sodales sem. Nullam egestas massa a maximus tristique. Phasellus non porttitor
odio, vitae iaculis augue. Cras sit amet mi ultricies, elementum nisi sed, maximus felis. Ut dapibus
massa ut elit ullamcorper gravida. Nullam vehicula leo lacus, id lacinia metus aliquet vel. Nullam
laoreet elit accumsan ultrices finibus. Maecenas a malesuada nisi. Duis maximus enim lacinia
sagittis pulvinar. Etiam malesuada ante eget volutpat condimentum.\n\nDonec sodales nunc sit amet
libero interdum venenatis a sit amet tellus. Quisque a tristique nulla. Donec pellentesque euismod
purus vel ullamcorper. Nulla turpis velit, scelerisque eget felis id, consequat maximus est. Cras
maximus tristique quam quis consequat. Duis condimentum pellentesque ultrices. Nam malesuada lacinia
eleifend. Quisque nec convallis ex. Nam ut enim suscipit, rhoncus nisi sed, volutpat dolor.
Curabitur efficitur sodales purus ac semper. Aenean facilisis nibh non augue aliquet ornare. Integer
at augue ut risus hendrerit scelerisque. In tincidunt a leo rhoncus vestibulum. Integer sodales arcu
ligula, eu imperdiet arcu faucibus nec. Ut pellentesque sagittis placerat.
EOL
    })
  else
    204
  end
end

# @drupal Daily or hourly ron job to create and ZIP CSV files for download.
get '/countries/:id.zip' do
  204
end

# @drupal Daily or hourly ron job to create text files for download.
get '/countries/:id.txt' do
  204
end

# @drupal Load node from Drupal.
get '/events/:id' do
  content_type 'application/json'

  result = connection[:events].find(_id: params[:id]).first

  if result
    JSON.dump(event_formatter(result).merge({
      # @drupal Use PostGIS to determine areas and sites within a 2km radius of event.
      "organizations_nearby" => [
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

# @drupal Load node from Drupal.
get '/organizations/:id' do
  content_type 'application/json'

  result = connection[:organizations].find(_id: params[:id]).first

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
          "events_count" => 12,
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
      "events_nearby" => [
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

# @drupal Load node from Drupal.
get '/people/:id' do
  content_type 'application/json'

  result = connection[:people].find(_id: params[:id]).first

  if result
    JSON.dump({
      # @todo
    })
  else
    404
  end
end

# @drupal Perform search on Drupal.
get '/countries/:id/search/organizations' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    site = result['sites'].max do |a,b|
      a['date_first_cited']['value'] <=> b['date_first_cited']['value']
    end

    site_present = {
      "date_first_cited" => site['date_first_cited'].try(:[], 'value'),
      "date_last_cited" => site['date_last_cited'].try(:[], 'value'),
    }
    if site['name']
      site_present['admin_level_1'] = site['admin_level_1'].try(:[], 'value')
      site_present['admin_level_2'] = site['admin_level_2'].try(:[], 'value')
    end

    commander = connection[:people].find({
      'memberships' => {
        '$elemMatch' => {
          'organization_id.value' => result['_id'],
          'role.value' => 'Commander',
        },
      },
    }).sort({
      'memberships.date_first_cited.value' => -1, # XXX don't know if this sorts correctly
    }).first

    commander_present = {
      "name" => commander['name'].try(:[], 'value'),
    }

    {
      "id" => result['_id'],
      "division_id" => result['_id'],
      "name" => result['name'].try(:[], 'value'),
      "other_names" => result['other_names'].try(:[], 'value'),
      # @drupal Add events_count calculated field.
      "events_count" => connection[:events].find({'perpetrator_organization_id.value' => result['_id']}).count,
      "classification" => result['classification'].try(:[], 'value'),
      "site_present" => site_present,
      "commander_present" => commander_present,
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
    # No facets.
  }, result_formatter)
end

# @drupal Perform search on Drupal.
get '/countries/:id/search/people' do
  content_type 'application/json'

  result_formatter = lambda do |result|
    memberships = result['memberships'].max(2) do |a,b|
      a['date_first_cited']['value'] <=> b['date_first_cited']['value']
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
      site = memberships[0]['organization']['sites'].max do |a,b|
        a['date_first_cited']['value'] <=> b['date_first_cited']['value']
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
      "division_id" => result['division_id'],
      "name" => result['name'].try(:[], 'value'),
      "other_names" => result['other_names'].try(:[], 'value'),
      # @drupal Add events_count calculated field, equal to the events related to an organization during the membership of the person.
      "events_count" => 12,
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
    event_formatter(result).merge({
      # @drupal How expensive is it to do radius search for each result in PostGIS?
      "sites_nearby" => [
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
    date__gte: ['date.value', '$gte'],
    date__lte: ['date.value', '$lte'],
  }, {
    'date' => 'date.value',
  }, {
    'classification' => ['$classification.value', unwind: true],
  }, result_formatter)
end

# @drupal ZIP file generated on-demand.
get '/countries/:id/search/organizations.zip' do
  204
end
get '/countries/:id/search/people.zip' do
  204
end
get '/countries/:id/search/events.zip' do
  204
end
get '/organizations/:id.zip' do
  204
end
get '/people/:id.zip' do
  204
end

# @drupal Text file generated on-demand.
get '/countries/:id/search/organizations.txt' do
  204
end
get '/countries/:id/search/people.txt' do
  204
end
get '/countries/:id/search/events.txt' do
  204
end
get '/organizations/:id.txt' do
  204
end
get '/people/:id.txt' do
  204
end

get '/countries/:id/map' do
  content_type 'application/json'

  # @todo option without organizations for country detail?

  JSON.dump({
    # @todo
  })
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

get '/autocomplete/geonames_id' do
  JSON.dump(CSV.foreach(File.expand_path('NG.txt', __dir__), col_sep: "\t").map do |row|
    {
      id: Integer(row[0]),
      name: row[1],
    }
  end)
end

get '/geometries/:id' do
  # @todo
end

run Sinatra::Application
