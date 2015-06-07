get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).zip} do |id|
  204
end
get %r{/people/([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}).txt} do |id|
  204
end

get '/people/:id/chart' do
  content_type 'application/json'

  if !params.key?('at')
    return [400, JSON.dump({'message' => "Missing 'at' parameter"})]
  elsif !params[:at].match(/\A\d{4}-\d{2}-\d{2}\z/)
    return [400, JSON.dump({'message' => "Invalid 'at' value"})]
  end

  etag_and_return({
    # @todo
  })
end

# @drupal Load node from Drupal.
get '/people/:id' do
  content_type 'application/json'

  result = connection[:people].find(_id: params[:id]).first

  if result
    etag_and_return({
      # @todo
    })
  else
    404
  end
end
