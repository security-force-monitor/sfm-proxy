get '/geometries/:id' do
  content_type 'application/json'

  filename = File.expand_path(File.join('..', 'data', 'topojson', 'adm0', "#{params[:id]}.topojson"), __dir__)

  if File.exist?(filename)
    File.read(filename)
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
