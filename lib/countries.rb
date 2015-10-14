# @backend Daily or hourly cron job to create and ZIP CSV files for download.
get %r{/countries/([a-z]{2}).zip} do |id|
  204
end

# @backend Daily or hourly cron job to create text files for download.
get %r{/countries/([a-z]{2}).txt} do |id|
  204
end

get '/countries' do
  content_type 'application/json'

  dir = File.expand_path(File.join('..', 'data', 'geojson', 'adm0'), __dir__)

  response = sample_countries.map do |code,name| # @backend Load country codes and names.
    geometry = JSON.load(File.read(File.join(dir, "#{code}.geojson")))['features'][0]['geometry']

    east, west = geometry['coordinates'][0].map(&:first).minmax
    south, north = geometry['coordinates'][0].map(&:last).minmax

    {
      'type' => 'Feature',
      'id' => code,
      'properties' => {
        'name' => name,
      },
      'bbox' => [
        {
          lon: west,
          lat: south,
        },
        {
          lon: east,
          lat: north,
        },
      ],
      'geometry' => geometry,
    }
  end

  etag_and_return(response)
end

get '/countries/:id' do
  content_type 'application/json'

  etag_and_return(sample_country) # @backend Load country.
end
