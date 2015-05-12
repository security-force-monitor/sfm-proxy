get '/people/:id.zip' do
  204
end
get '/people/:id.txt' do
  204
end

get '/people/:id/chart' do
  content_type 'application/json'

  JSON.dump({
    # @todo
  })
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
