get %r{/geometries/([a-z]{2})\.(geojson|topojson)} do |id,extension|
  content_type 'application/json'

  filename = File.expand_path(File.join('..', 'data', extension, 'adm0', "#{id}.#{extension}"), __dir__)

  if File.exist?(filename)
    body = File.read(filename)
    if extension == 'geojson'
      etag_and_return(JSON.load(body)['features'])
    else
      etag_and_return(body, raw: true)
    end
  else
    404
  end
end

# @see https://github.com/britg/sinatra-cross_origin#responding-to-options
options '*' do
  response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'

  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

  200
end
