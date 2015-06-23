require 'fileutils'
require 'tempfile'

def run(command)
  LOGGER.info(command)
  system(command)
end

def normalize(string)
  string.gsub(/\p{Punct}/, ' ').squeeze(' ').downcase
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

desc 'Create admin level 1 crosswalks between GAUL and GeoNames'
task :crosswalk_adm1 do
  if ENV['country_code']
    id_to_code_map = {}
    name_to_id_map = {}

    CSV.foreach(File.expand_path(File.join('..', 'data', 'geonames', "#{ENV['country_code'].upcase}.txt"), __dir__), col_sep: "\t").each do |row|
      if row[7] == 'ADM1'
        geonames_id = Integer(row[0])
        names = row[3].split(',') + [row[1]]
        Set.new(names.map{|name| normalize(name)}).each do |name|
          if name_to_id_map.key?(name)
            LOGGER.warn("collision #{name} #{name_to_id_map[name]} #{row[0]}")
          else
            name_to_id_map[name] = geonames_id
          end
        end
        id_to_code_map[geonames_id] = row[10]
      end
    end

    # Not a Geonames alternate name.
    name_to_id_map['abuja'] ||= 2352776

    gaul_id_to_geonames_id = {}
    gaul_id_to_geonames_code = {}

    JSON.load(File.read(File.expand_path(File.join('..', 'data', 'geojson', "adm1", "#{ENV['country_code']}.geojson"), __dir__)))['features'].each do |feature|
      name = normalize(feature['properties']['ADM1_NAME'])
      gaul_id = feature['properties']['ADM1_CODE']
      if name_to_id_map.key?(name)
        geonames_id = name_to_id_map.fetch(name)
        gaul_id_to_geonames_id[gaul_id] = geonames_id
        gaul_id_to_geonames_code[gaul_id] = id_to_code_map.fetch(geonames_id)
      else
        LOGGER.warn("#{gaul_id} not found #{name}")
      end
    end

    puts gaul_id_to_geonames_id.pretty_inspect
    puts gaul_id_to_geonames_code.pretty_inspect

    difference = id_to_code_map.keys - gaul_id_to_geonames_id.values
    unless difference.empty?
      LOGGER.warn("unmapped #{difference.join(', ')}")
    end
  else
    LOGGER.error('usage: rake crosswalk_adm1 country_code=ng')
  end
end

desc 'Create admin level 2 crosswalks between GAUL and GeoNames'
task :crosswalk_adm2 do
  if ENV['country_code']
    id_to_code_map = {}
    name_to_id_map = {}

    CSV.foreach(File.expand_path(File.join('..', 'data', 'geonames', "#{ENV['country_code'].upcase}.txt"), __dir__), col_sep: "\t").each do |row|
      if row[7] == 'ADM2'
        geonames_id = Integer(row[0])
        code_adm1 = row[10]
        name_to_id_map[code_adm1] ||= {}
        names = (row[3] || '').split(',') + [row[1]]
        Set.new(names.map{|name| normalize(name)}).each do |name|
          if name_to_id_map[code_adm1].key?(name)
            LOGGER.warn("collision #{name} #{name_to_id_map[code_adm1][name]} #{row[0]}")
          else
            name_to_id_map[code_adm1][name] = geonames_id
          end
        end
        id_to_code_map[geonames_id] = row[11]
      end
    end

    gaul_id_to_geonames_id = {}
    gaul_id_to_geonames_code = {}

    JSON.load(File.read(File.expand_path(File.join('..', 'data', 'geojson', "adm2", "#{ENV['country_code']}.geojson"), __dir__)))['features'].each do |feature|
      name = normalize(feature['properties']['ADM2_NAME'])
      code_adm1 = GAUL_ID_TO_GEONAMES_CODE.fetch(feature['properties']['ADM1_CODE'])
      gaul_id = feature['properties']['ADM2_CODE']
      if name_to_id_map[code_adm1].key?(name)
        geonames_id = name_to_id_map[code_adm1].fetch(name)
        gaul_id_to_geonames_id[gaul_id] = geonames_id
        gaul_id_to_geonames_code[gaul_id] = id_to_code_map.fetch(geonames_id)
      else
        LOGGER.warn("#{gaul_id} not found #{name} in #{code_adm1}")
      end
    end

    puts gaul_id_to_geonames_id.pretty_inspect
    puts gaul_id_to_geonames_code.pretty_inspect

    difference = id_to_code_map.keys - gaul_id_to_geonames_id.values
    unless difference.empty?
      LOGGER.warn("unmapped #{difference.join(', ')}")
    end
  else
    LOGGER.error('usage: rake crosswalk_adm2 country_code=ng')
  end
end

desc 'Imports admin levels 1 and 2'
task :import_geo do
  if ENV['admin_level'] && ENV['country_code']
    properties = {}
    CSV.foreach(File.expand_path(File.join('..', 'data', 'geonames', "#{ENV['country_code'].upcase}.txt"), __dir__), col_sep: "\t").each do |row|
      properties[Integer(row[0])] = {name: row[1], coordinates: [Float(row[5]), Float(row[4])]}
    end

    JSON.load(File.read(File.expand_path(File.join('..', 'data', 'geojson', "adm#{ENV['admin_level']}", "#{ENV['country_code']}.geojson"), __dir__)))['features'].each do |feature|
      name = normalize(feature['properties']['ADM1_NAME'])
      gaul_id = feature['properties']["ADM#{ENV['admin_level']}_CODE"]

      if GAUL_ID_TO_GEONAMES_ID.key?(gaul_id)
        geonames_id = GAUL_ID_TO_GEONAMES_ID[gaul_id]
        connection[:geometries].find(_id: geonames_id).upsert({
          division_id: "ocd-division/country:#{ENV['country_code']}",
          name: properties.fetch(geonames_id).fetch(:name),
          classification: "ADM#{ENV['admin_level']}",
          geo: feature.fetch('geometry'),
          coordinates: properties.fetch(geonames_id).fetch(:coordinates),
        })
      else
        LOGGER.warn("#{gaul_id} not found #{name}")
      end
    end
  else
    LOGGER.error('usage: rake import_geo admin_level=1 country_code=ng')
  end
end
