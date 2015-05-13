desc 'Test the API'
task :default do
  BASE_URL = ENV['base_url'] || 'http://0.0.0.0:9292'

  def test(path, statuses = [200, 204])
    response = Faraday.get("#{BASE_URL}#{path}")
    if statuses.include?(response.status)
      JSON.load(response.body)
    else
      raise "#{response.status} #{BASE_URL}#{path}"
    end
  end

  [ '/countries',
    '/autocomplete/geonames_id',
    '/countries/ng/map?at=2010-01-01',
    '/countries/ng/map?at=2010-01-01&bbox=10,5,5,10',
    '/countries/ng/map?at=2010-01-01&bbox=10,5,5,10&classification__in=Brigade',
  ].each do |path|
    test(path)
  end

  [ '/countries/ng',
    '/countries/ng/search/organizations',
    '/countries/ng/search/people',
    '/countries/ng/search/events',
  ].each do |path|
    ['', '.txt', '.zip'].each do |suffix|
      test("#{path}#{suffix}")
    end
  end

  # @note Query string parameters are not tested.
  [ :events,
    :organizations,
    :people,
  ].each do |collection_name|
    count = JSON.load(Faraday.get("#{BASE_URL}/countries/ng/search/#{collection_name}").body)['count']
    pages = count / 20
    puts "%3d #{collection_name} results" % (pages + 1)
    pages.times do |n|
      test("/countries/ng/search/#{collection_name}?p=#{n + 2}")
    end
  end

  [ :events,
    :organizations,
    # :people, # @todo
  ].each do |collection_name|
    test("/#{collection_name}/nonexistent", [404])
    query = connection[collection_name].find
    puts "%3d #{collection_name}" % query.count
    query.each do |object|
      suffixes = ['']
      unless collection_name == :events
        suffixes += ['.txt', '.zip']
      end
      suffixes.each do |suffix|
        test("/#{collection_name}/#{object['_id']}#{suffix}")
      end
    end
  end

  [ '/countries/ng/map',
    '/countries/ng/map?at=invalid',
    '/countries/ng/map?at=2010-01-01&bbox=invalid',
  ].each do |path|
    test(path, [400])
  end

  # @todo
  # /countries/:id/map
  # /organizations/:id/map
  # /organizations/:id/chart
  # /people/:id/chart
  # /geometries/:id
end
