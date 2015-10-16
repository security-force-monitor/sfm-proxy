# In the final production version, nothing should call methods from this file.
helpers do
  def sample_countries
    [
      ['eg', 'Egypt'],
      ['mx', 'Mexico'],
      ['ng', 'Nigeria'],
    ]
  end

  def sample_country
    {
      'id' => 'ng',
      'name' => 'Nigeria',
      'title' => 'Federal Republic of Nigeria',
      'events_count' => connection[:events].find('division_id' => 'ocd-division/country:ng').count,
      'description' => <<-EOL
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
    }
  end

  def sample_bounding_box
    [14.5771, 4.2405, 2.6917, 13.8659] # Nigeria west-south, east-north
  end

  def sample_point
    {
      'type' => 'Point',
      'coordinates' => [rand(longitude_range) / 10_000.0, rand(latitude_range) / 10_000.0],
    }
  end

  def sample_area
    connection[:geometries].find.first['geo']
  end

  def sample_organization
    {
      'id' => '68e90978-fa3f-42f3-9d56-4218c4f3f785', # @todo Need to replace on each import.
      'name' => 'Brigade 2',
      'other_names' => [
        'The Planeteers',
      ],
      'root_id' => nil,
      'root_name' => 'Nigerian Army',
      'person_name' => 'Michael Maris',
      'events_count' => 12,
    }
  end

  def sample_event
    {
      'id' => '656e71bc-ef2d-4483-8099-a8d701490670', # @todo Need to replace on each import.
      'start_date' => '2010-01-01',
      'end_date' => nil,
      'location' => 'Aba North, Abia',
      'geonames_name' => 'Aba North',
      'admin_level_1_geonames_name' => 'Abia',
      'classification' => ['Torture', 'Disappearance'],
      'perpetrator_name' => 'Terry Guerrier',
      'perpetrator_organization' => sample_organization.slice('id', 'name'),
    }
  end

private

  def longitude_range
    @longitude_range ||= Integer(bounding_box[2] * 10_000)...Integer(bounding_box[0] * 10_000)
  end

  def latitude_range
    @latitude_range ||= Integer(bounding_box[1] * 10_000)...Integer(bounding_box[3] * 10_000)
  end
end
