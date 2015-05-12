# @drupal Load node from Drupal.
get '/events/:id' do
  content_type 'application/json'

  result = connection[:events].find(_id: params[:id]).first

  if result
    JSON.dump(event_formatter(result).merge({
      # @drupal Use PostGIS to determine areas and sites within a 2km radius of event.
      "organizations_nearby" => [ # @hardcoded
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

get '/countries/:id/map' do
  content_type 'application/json'

  # @todo option without organizations for country detail?

  JSON.dump({
    # @todo
  })
end
