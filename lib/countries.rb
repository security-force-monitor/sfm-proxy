# @drupal Daily or hourly ron job to create and ZIP CSV files for download.
get '/countries/:id.zip' do
  204
end

# @drupal Daily or hourly ron job to create text files for download.
get '/countries/:id.txt' do
  204
end

# @drupal Load list of nodes from Drupal. TopoJSON files are created by drush command.
get '/countries' do
  content_type 'application/json'

  dir = File.expand_path(File.join('..', 'data', 'topojson', 'adm0'), __dir__)

  # @todo Replace with GAUL and/or make geometries optional.
  JSON.dump([ # @hardcoded
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
    JSON.dump({ # @hardcoded
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
