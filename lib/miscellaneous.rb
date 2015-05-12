get '/geometries/:id' do
  # @todo
end

# @see https://github.com/britg/sinatra-cross_origin#responding-to-options
options '*' do
  response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'

  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'

  200
end
