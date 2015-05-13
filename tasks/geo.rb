require 'fileutils'
require 'tempfile'

def run(command)
  LOGGER.info(command)
  system(command)
end

desc 'Converts Shapefile to GeoJSON'
task :geojson do
  if ENV['input'] && ENV['output']
    dir = File.expand_path(File.join('data', 'geojson'), __dir__)
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

    dir = File.expand_path(File.join('data', 'topojson'), __dir__)
    FileUtils.mkdir_p(File.join(dir, File.dirname(ENV['output'])))

    begin
      if run(%(ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 "#{path}" "#{ENV['input']}"))
        run(%(topojson -o "#{File.join(dir, "#{ENV['output']}.topojson")}" "#{path}"))
      end
    ensure
      File.unlink(path)
    end
  else
    LOGGER.error('usage: rake topojson input=path/to/shapefile.shp output=adm0/ng')
  end
end
