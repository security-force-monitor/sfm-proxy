require 'rubygems'
require 'bundler/setup'

require 'pupa'

LOGGER = Pupa::Logger.new('sfm-proxy')

def run(command)
  LOGGER.info(command)
  system(command)
end

desc 'Converts Shapefile to GeoJSON'
task :geojson do
  require 'fileutils'
  require 'tempfile'

  if ENV['input'] && ENV['output']
    dir = File.expand_path('geo/geojson', __dir__)
    FileUtils.mkdir_p(File.join(dir, File.dirname(ENV['output'])))

    run(%(ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 "#{File.join(dir, "#{ENV['output']}.geojson")}" "#{ENV['input']}"))
  else
    LOGGER.error('usage: rake geojson input=path/to/shapefile.shp output=adm0/ng')
  end
end

desc 'Converts Shapefile to TopoJSON'
task :topojson do
  require 'fileutils'
  require 'tempfile'

  if ENV['input'] && ENV['output']
    file = Tempfile.new('geojson')
    begin
      path = file.path
    ensure
      file.close
      # The GeoJSON driver does not override existing files.
      file.unlink
    end

    dir = File.expand_path('geo/topojson', __dir__)
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

desc 'Imports the data from CSV'
task :import do
  require 'csv'
  require 'json'
  require 'pp'
  require 'securerandom'
  require 'set'

  require 'active_support/core_ext/hash/except'
  require 'active_support/core_ext/object/blank'
  require 'active_support/inflector'
  require 'faraday'
  require 'json-schema'

  require_relative 'constants'

  CONFIDENCE_ORDER = [
      'Low',
      'Medium',
      'High',
  ]

  uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
  CONNECTION = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
  CONNECTION.login(uri.user, uri.password) if uri.user && uri.password

  class DependencyGraph < Hash
    include TSort

    alias tsort_each_node each_key

    def tsort_each_child(node, &block)
      if key?(node)
        fetch(node).each(&block)
      else
        LOGGER.warn("can't resolve #{node}")
      end
    end
  end

  class Hash
    # @param other
    # @param [String] parent
    # @return [Hash] the differences between two hashes
    # @see http://stackoverflow.com/a/7178108
    def diff_and_merge(other, parent_key=nil)
      (keys | other.keys).reduce({}) do |hash,key|
        unless other[key].nil?
          if self[key].nil?
            # Use the other's value.
            self[key] = other[key]
          elsif key == 'sources'
            # Merge the other's sources.
            self[key] |= other[key]
          elsif key == 'confidence'
            # Use the lowest confidence.
            self[key] = [self[key], other[key]].min_by{|value| CONFIDENCE_ORDER.index(value)}
          elsif self[key] != other[key]
            if key == 'other_names' && other[key]['value'].include?('One Division')
              raise [self, other].inspect
            end
            hash[key] = if self[key].respond_to?(:diff_and_merge) && other[key].respond_to?(:diff_and_merge)
              self[key].diff_and_merge(other[key], key)
            else
              [self[key], other[key]]
            end
          end
        end
        hash.reject{|_,v| v.empty?}
      end
    end
  end

  class Array
    # @param other
    # @param [String] parent
    # @return [Array] the differences between two arrays
    def diff_and_merge(other, parent_key)
      if all?{|item| Hash === item} && other.all?{|item| Hash === item}
        if parent_key == 'memberships'
          # Memberships are assumed to be unique.
          concat(other)
          []
        else
          # Make a deep copy of the array.
          array = Marshal.load(Marshal.dump(other))

          # Other names are not objects.
          key = if parent_key == 'other_names'
            'name'
          else
            'id'
          end

          # Pull new items off the other array.
          other.to_enum.with_index.reverse_each do |b,index|
            if none?{|a| a[key].fetch('value') == b[key].fetch('value')}
              push(array.delete_at(index))
            end
          end

          # Find any differences with the old items.
          array.map do |b|
            find{|a| a[key].fetch('value') == b[key].fetch('value')}.diff_and_merge(b)
          end.reject(&:empty?)
        end
      else
        [self, other]
      end
    end
  end

  # @param [Array,Hash] object
  # @param [Array] keys
  # @param value
  # @return the object with the appropriate key set to the value
  def assign(object, keys, value)
    if value
      object[keys[0]] = case keys[1]
      when nil # no more keys
        value
      when 'b'
        case value
        when 'Y'
          true
        when 'N'
          false
        else
          value
        end
      when 'd'
        if value[%r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}]
          "%d-%0.2d-%0.2d" % [$3, $1, $2]
        else # /\A\d{4}(?:-\d{2})?\z/ is also valid
          value
        end
      when 'f'
        Float(value)
      when 'i'
        Integer(value)
      when 'n' # flag for multiple values in single cell
        Set.new(value.split(';').map(&:strip))
      else
        object[keys[0]] ||= Integer === keys[1] ? [] : {}
        assign(object[keys[0]], keys.drop(1), value)
      end
    end
    object
  end

  # @param object
  # @return the object with no blank values
  def reduce(object)
    case object
    when Array
      object.compact.map{|v| reduce(v)}.reject(&:blank?)
    when Hash
      object.reduce({}){|h,(k,v)| h[k] = reduce(v); h}.reject{|_,v| v.blank?}
    when Set
      Set.new(object.map{|v| reduce(v)}.reject(&:blank?))
    else
      object
    end
  end

  # @param object
  # @return the object with sets as arrays
  def set_to_array(object)
    case object
    when Array
      object.map{|v| set_to_array(v)}
    when Hash
      object.reduce({}){|h,(k,v)| h[k] = set_to_array(v); h}
    when Set
      object.to_a
    else
      object
    end
  end

  source_url = 'https://docs.google.com/spreadsheets/d/16cRBkrnXE5iGm8JXD7LSqbeFOg_anhVp2YAzYTRYDgU/export?gid=%d&format=csv'
  division_id = 'ocd-division/country:ng'
  gids = [0, 1686464613]

  objects = {}
  names = {}
  body = {}

  [ :sites,
    :areas,
    :organizations,
    :persons,
    :events,
  ].each do |collection_name|
    CONNECTION[collection_name].drop
  end

  { site: gids,
    area: gids,
    organization: gids,
    person: [510712342, 394650791],
    event: [939834263],
    # @todo add posts
  }.each do |type,gids|
    gids.each do |gid|
      objects[type] = {}
      names[gid] ||= {}

      # Memoize the response body.
      body[gid] ||= Faraday.get(source_url % gid).body

      converter = ->(header) do
        # The mappings for sites and areas are incomplete, so don't raise errors for missing keys.
        if [:site, :area].include?(type)
          HEADERS_MAP[type][header]
        else
          HEADERS_MAP[type].fetch(header)
        end
      end

      CSV.parse(body[gid], headers: true, header_converters: converter).each_with_index do |row,index|
        next if row[:id] == 'SKIP'

        row_number = index + 2

        object = {}

        # Map a flat CSV to a nested hash.
        row.each do |key,value|
          if key # ignore unmapped headers
            # A site may not have a name.
            if type == :site && key == :name__value && value.nil?
              admin_levels = []
              if row[:admin_level_2__value]
                admin_levels << row[:admin_level_2__value]
              end
              if row[:admin_level_1__value]
                admin_levels << row[:admin_level_1__value]
              end
              name = "#{row[:__name]}'s base"
              unless admin_levels.empty?
                name += " in #{admin_levels.join(', ')}"
              end
              value = names[gid][row_number] ||= name
            elsif key == :sites__0__id__value && value.nil?
              value = names[gid].fetch(row_number)
            end

            begin
              assign(object, key.to_s.split('__').map{|key| Integer(key) rescue key}, value)
            rescue ArgumentError => e
              LOGGER.error("gid #{gid} row #{row_number} ID: #{e.message}")
            end
          end
        end

        # Remove any blank values.
        object = reduce(object)

        # Remove any helper values.
        object.delete('')

        # Skip blank rows.
        if !object.empty?
          # Non-events must have names.
          if type == :event || object.key?('name')
            object['type'] = type.to_s
            object['division_id'] = division_id

            # @note If new rows for an existing record are not added with IDs, the
            #   new rows will not be merged into the record.
            key = if object['id']
              object['id']
            elsif type == :event
              row_number.to_s
            else
              object['name'].fetch('value')
            end

            # Parenthesized numbers just disambiguate records with the same name.
            unless type == :event
              object['name']['value'].sub(/\s*\(\d+\)\z/, '')
            end

            if type == :organization
              if gid == 0
                object['root_name'] = {'value' => 'Police'}
              elsif gid == 1686464613
                object['root_name'] = {'value' => 'Military'}
              end
            end

            # If it's a row for a new object, add it to the list of objects.
            if !objects[type].key?(key)
              object['gid'] = gid
              object['row'] = row_number
              unless object['id']
                object['id'] = SecureRandom.uuid
              end
              objects[type][key] = object
            # If it's a row for an existing object, merge it into the existing object.
            elsif objects[type][key] != object
              begin
                differences = objects[type][key].diff_and_merge(object).except('gid', 'row', 'notes')
                if !differences.empty?
                  LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize} #{key.inspect} is inconsistent\n#{differences.pretty_inspect}")
                end
              rescue NoMethodError
                LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize} #{key.inspect} can't calculate difference with:\n#{object.pretty_inspect}")
              end
            end
          else
            LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize}#name is blank\n#{object.pretty_inspect}")
          end
        end
      end
    end
  end

  # Convert sets to arrays.
  objects.each do |type,hash|
    hash.each do |key,object|
      hash[key] = set_to_array(object)
    end
  end

  unless ENV['novalidate']
    # Validate objects.
    objects.each do |type,hash|
      schema = JSON.load(File.read(File.expand_path(File.join('schemas', 'validation', "#{type.to_s}.json"), __dir__)))

      hash.each do |_,object|
        begin
          JSON::Validator.validate!(schema, object)
        rescue JSON::Schema::ValidationError => e
          LOGGER.warn("gid #{object['gid']} row #{object['row']}: #{e.message}")
        end
      end
    end
  end

  # Build the dependency graph.
  graph = DependencyGraph.new

  objects.each do |type,hash|
    hash.each do |key,object|
      id = "#{type}:#{key}"
      graph[id] = []

      case type
      when :organization
        { 'parents' => [:organization, 'id'],
          'sites' => [:site, 'id'],
          'areas' => [:area, 'id'],
          'memberships' => [:organization, 'organization_id'],
        }.each do |property,(prefix,subproperty)|
          if object.key?(property)
            object[property].each do |thing|
              if thing[subproperty] && thing[subproperty].key?('value')
                graph[id] << "#{prefix}:#{thing[subproperty]['value']}"
              end
            end
          end
        end
      when :person
        object['memberships'].each do |membership|
          if membership['organization_id'] && membership['organization_id'].key?('value')
            graph[id] << "organization:#{membership['organization_id']['value']}"
          end
          if membership['site_id'] && membership['site_id'].key?('value')
            graph[id] << "site:#{membership['site_id']['value']}"
          end
        end
      when :event
        if object['perpetrator_organization_id'] && object['perpetrator_organization_id'].key?('value')
          graph[id] << "organization:#{object['perpetrator_organization_id']['value']}"
        end
      end
    end
  end

  # Resolves an object's foreign keys from object IDs to database IDs, and
  # embeds foreign objects.
  #
  # @param [Hash] object
  # @param [Hash] map
  # @param [Array<Hash>] objects
  def resolve_foreign_keys(object, map, objects)
    case object['type'].to_sym
    when :organization
      { 'parents' => [:organization, 'id'],
        'sites' => [:site, 'id'],
        'areas' => [:area, 'id'],
        'memberships' => [:organization, 'organization_id'],
      }.each do |property,(prefix,subproperty)|
        if object.key?(property)
          object["#{property.singularize}_ids"] = []
          object[property].each_with_index do |thing,index|
            if thing[subproperty] && thing[subproperty].key?('value')
              value = thing[subproperty]['value']
              key = "#{prefix}:#{value}"
              if map.key?(key)
                thing[subproperty]['value'] = map[key] # use the database ID
                object[property][index] = objects[prefix].fetch(value) # substitute the full record
              end
              object["#{property.singularize}_ids"][index] = thing # keep the brief record
            end
          end
        end
      end
    when :person
      object['memberships'].each do |membership|
        if membership['organization_id'] && membership['organization_id'].key?('value')
          value = membership['organization_id']['value']
          key = "organization:#{value}"
          if map.key?(key)
            membership['organization_id']['value'] = map[key]
            membership['organization'] = objects[:organization].fetch(value)
          end
        end
        if membership['site_id'] && membership['site_id'].key?('value')
          value = membership['site_id']['value']
          key = "site:#{value}"
          if map.key?(key)
            membership['site_id']['value'] = map[key]
            membership['site'] = objects[:site].fetch(value)
          end
        end
      end
    when :event
      if object['perpetrator_organization_id'] && object['perpetrator_organization_id'].key?('value')
        value = object['perpetrator_organization_id']['value']
        key = "organization:#{value}"
        if map.key?(key)
          object['perpetrator_organization_id']['value'] = map[key]
          object['perpetrator_organization'] = objects[:organization].fetch(value)
        end
      end
    end
  end

  # Saves the object to the database, and returns its database ID.
  #
  # @param [Hash] object
  # @return [String] the database ID
  def import_object(object)
    collection_name = object['type'].pluralize
    collection = CONNECTION[collection_name]
    selector = {_id: object.fetch('id')}
    query = collection.find(selector)
    store = object.except('type') # @todo 'gid', 'row' in production

    case query.count
    when 0
      collection.insert(store.merge(selector))
      object['id']
    when 1
      query.update(store)
      query.first['_id'].to_s
    else
      raise Errors::TooManyMatches, "selector matches multiple documents during save in collection #{collection_name} for #{object['id']}"
    end
  end

  object_id_to_database_id = {}

  begin
    tsort = graph.tsort
  rescue TSort::Cyclic => e
    LOGGER.error(e.message)
    e.message.scan(/"(#{e.message[/\borganization:Joint Task Force, /]}.+?)"/).flatten.each do |id|
      graph.delete(id)
    end
    retry
  end

  # Save the objects to the database.
  tsort.each do |id|
    type, key = id.split(':', 2)
    if objects[type.to_sym].key?(key)
      object = objects[type.to_sym][key]
      resolve_foreign_keys(object, object_id_to_database_id, objects)
      database_id = import_object(object)
      object_id_to_database_id[id] = database_id
      object_id_to_database_id[database_id] = database_id
    end
  end

  # @note Not setting IDs for now based on above `@note`.
  # objects.each do |type,hash|
  #   hash.each do |key,object|
  #     LOGGER.info("gid #{object['gid']} row #{object['row']}: #{object['id']}")
  #   end
  # end
end
