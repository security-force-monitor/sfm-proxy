get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
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
