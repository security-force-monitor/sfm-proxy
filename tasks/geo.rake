require 'fileutils'
require 'tempfile'

GEONAMES_ALTERNATE_NAMES = {
  # ADM1
  nil => {
    'abuja' => 2352776,
  },
  # ADM2
  '16' => {
    'egbado yewa north' => 8636323,
    'egbado yewa south' => 8636324,
  },
  '24' => {
    'danmusa' => 8633647,
  },
  '26' => {
    'ogbadigbo' => 7729907,
  },
  '29' => {
    'tundun wada' => 8633726,
  },
  '35' => {
    'girie' => 8659810,
  },
  '42' => {
    'aiyedaade' => 8636369,
    'atakumosa east' => 7730030,
    'atakumosa west' => 7730042,
  },
  '54' => {
    'gboyin' => 8636741,
  },
  '56' => {
    'nassarawa egon' => 8635059,
    'nassarawa' => 8633818,
  },
}

def run(command)
  LOGGER.info(command)
  system(command)
end

desc 'Converts Shapefile to GeoJSON'
task :geojson do
  if ENV['input'] && ENV['output']
    dir = File.expand_path(File.join('..', 'data', 'geojson'), __dir__)
    FileUtils.mkdir_p(File.join(dir, File.dirname(ENV['output'])))

    run(%(ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 "#{File.join(dir, "#{ENV['output']}.geojson")}" "#{ENV['input']}"))
  else
    LOGGER.error('usage: rake geojson input=path/to/shapefile.shp output=adm0/ng')
  end
end

desc 'Converts Shapefile to TopoJSON'
task :topojson do
  if ENV['input'] && ENV['output']
    file = Tempfile.new('geojson')
    begin
      path = file.path
    ensure
      file.close
      # The GeoJSON driver does not override existing files.
      file.unlink
    end

    dir = File.expand_path(File.join('..', 'data', 'topojson'), __dir__)
    FileUtils.mkdir_p(File.join(dir, File.dirname(ENV['output'])))

    begin
      if run(%(ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 "#{path}" "#{ENV['input']}"))
        run(%(topojson -o "#{File.join(dir, "#{ENV['output']}.topojson")}" "#{path}"))
      end
    ensure
      File.unlink(path)
    end
  else
    LOGGER.error('usage: rake topojson output=adm0/ng input=path/to/shapefile.shp')
  end
end

desc 'Imports geometries'
task :import_geo do
  def normalize(string)
    string.gsub(/\p{Punct}/, ' ').squeeze(' ').downcase
  end

  if ENV['country_code']
    without_polygons = Set.new # track ADM1 and ADM2 GeoNames features without polygons
    name_to_id_map = {} # `name` to `geonameid`
    id_to_code_map = {} # `geonameid` to `admin1 code`

    path = File.join('..', 'data', 'geonames', "#{ENV['country_code'].upcase}.txt")
    CSV.foreach(File.expand_path(path, __dir__), col_sep: "\t").each do |row|
      geonames_id = Integer(row[0]) # `geonameid`
      name = row[1] # `name`
      feature_code = row[7] # `feature code`

      # Create points for GeoNames features.
      connection[:geometries].update_one({_id: geonames_id}, {
        division_id: "ocd-division/country:#{ENV['country_code']}",
        name: name,
        classification: feature_code,
        point: {
          type: 'Point',
          coordinates: [Float(row[5]), Float(row[4])], # `longitude` and `latitude`
        }
      }, upsert: true) # can run task multiple times

      # Build mappings for ADM1 and ADM2 GeoNames features, to map to GAUL.
      if ['ADM1', 'ADM2'].include?(feature_code)
        without_polygons << geonames_id
        code = row[10] # `admin1 code`

        if feature_code == 'ADM1'
          # We may see an `admin1 code` before we see its `geonameid`, so we can't
          # build a `code_to_id_map` without doing two passes. This map is needed
          # to import polygons for ADM2 GeoNames features from GAUL.
          id_to_code_map[geonames_id] = code
        end

        # Scope ADM2 names by `admin1 code` to avoid collisions.
        scope = feature_code == 'ADM1' ? nil : code
        name_to_id_map[scope] ||= {}

        # GAUL may use any of GeoNames `name` or `alternatenames`.
        names = (row[3] || '').split(',') + [name] # `alternatenames`
        Set.new(names.map{|name| normalize(name)}).each do |name|
          if name_to_id_map[scope].key?(name)
            LOGGER.warn("GeoNames #{geonames_id} #{name} collides with #{name_to_id_map[scope][name]} in GeoNames ADM1 #{scope}")
          else
            name_to_id_map[scope][name] = geonames_id
          end
        end
      end
    end

    # GAUL also uses names that aren't in GeoNames.
    GEONAMES_ALTERNATE_NAMES.each do |scope,hash|
      hash.each do |name,id|
        name_to_id_map[scope] ||= {}
        name_to_id_map[scope][name] ||= id
      end
    end

    # Needed to set the scope for ADM2 GeoNames features.
    gaul_id_to_geonames_code = {}

    # Import polygons for ADM1 and ADM2 GeoNames features from GAUL.
    [1, 2].each do |admin_level|
      path = File.join('..', 'data', 'geojson', "adm#{admin_level}", "#{ENV['country_code']}.geojson")
      JSON.load(File.read(File.expand_path(path, __dir__)))['features'].each do |feature|
        gaul_id = feature['properties']["ADM#{admin_level}_CODE"]
        name = normalize(feature['properties']["ADM#{admin_level}_NAME"])

        scope = admin_level == 1 ? nil : gaul_id_to_geonames_code.fetch(feature['properties']['ADM1_CODE'])
        geonames_id = name_to_id_map[scope][name]

        if geonames_id
          without_polygons.delete(geonames_id)
          gaul_id_to_geonames_code[gaul_id] = id_to_code_map[geonames_id]
          connection[:geometries].update_one({_id: geonames_id}, '$set' => {geo: feature.fetch('geometry')})
        else
          LOGGER.warn("GAUL #{gaul_id} #{name} not found in GeoNames ADM1 #{scope}")
        end
      end
    end

    unless without_polygons.empty?
      LOGGER.warn("GeoNames ADM1 or ADM2 features without polygons:\n#{without_polygons.to_a.join("\n")}")
    end
  else
    LOGGER.error('usage: rake import_geo country_code=ng')
  end
end

desc 'Add geometries to areas, events, and sites'
task :link_geometries do
  geonames_id_to_geometry = {}
  connection[:geometries].find.projection({
    '_id' => 1,
    'point' => 1,
    'geo' => 1,
  }).each do |geometry|
    geonames_id_to_geometry[geometry['_id']] = geometry
  end

  connection[:areas].find.projection({
    '_id' => 1,
    'geonames_id.value' => 1,
  }).each do |document|
    if document['geonames_id']
      geonames_id = document['geonames_id']['value']
      geometry = geonames_id_to_geometry[geonames_id]
      connection[:areas].update_one({_id: document['_id']}, '$set' => {
        point: geometry['point'],
        geo: geometry['geo'],
      })
    end
  end

  [:events, :sites].each do |collection_name|
    connection[collection_name].find.projection({
      '_id' => 1,
      'geonames_id.value' => 1,
      'admin_level_1_geonames_id.value' => 1,
    }).each do |document|
      # Use the ADM1 GeoNames ID if there is no lower-level GeoNames ID.
      if document['geonames_id'] && geonames_id_to_geometry[document['geonames_id']['value']]
        geonames_id = document['geonames_id']['value']
      elsif document['admin_level_1_geonames_id']
        if document['geonames_id']
          LOGGER.warn("#{document['geonames_id']['value']} not found, trying ADM1")
        end
        if geonames_id_to_geometry[document['admin_level_1_geonames_id']['value']]
          geonames_id = document['admin_level_1_geonames_id']['value']
        else
          LOGGER.warn("#{document['admin_level_1_geonames_id']['value']} not found, giving up")
        end
      end

      if geonames_id
        geometry = geonames_id_to_geometry[geonames_id]
        connection[collection_name].update_one({_id: document['_id']}, '$set' => {
          point: geometry['point'],
        })
      end
    end
  end
end
