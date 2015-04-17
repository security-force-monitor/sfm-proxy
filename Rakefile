desc 'Imports the data from CSV'
task :import do
  require 'rubygems'
  require 'bundler/setup'

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
  require 'pupa'

  require_relative 'constants'

  LOGGER = Pupa::Logger.new('sfm-proxy')

  CONFIDENCE_ORDER = [
      'Low',
      'Medium',
      'High',
  ]

  class DependencyGraph < Hash # @todo
    include TSort

    alias tsort_each_node each_key

    def tsort_each_child(node, &block)
      fetch(node).each(&block)
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
      when 'd'
        if value[%r{\A(\d{1,2})/(\d{1,2})/(\d{4})\z}]
          "%d-%0.2d-%0.2d" % [$3, $1, $2]
        else # /\A\d{4}(?:-\d{2})?\z/ is valid
          value # JSON Schema will warn about invalid dates
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
  gids = [0, 1686464613]

  objects = {}
  names = {}
  ids = {}
  body = {}

  { sites: gids,
    areas: gids,
    organizations: gids,
    people: [510712342, 394650791],
    events: [939834263],
    # @todo add posts
  }.each do |type,gids|
    gids.each do |gid|
      objects[type] = {}
      names[gid] ||= {}
      ids[gid] ||= {}

      # Memoize the response body.
      body[gid] ||= Faraday.get(source_url % gid).body

      converter = ->(header) do
        # The mappings for sites and areas are incomplete, so don't raise errors for missing keys.
        if [:sites, :areas].include?(type)
          HEADERS_MAP[type][header]
        else
          HEADERS_MAP[type].fetch(header)
        end
      end

      CSV.parse(body[gid], headers: true, header_converters: converter).each_with_index do |row,index|
        next if row[:id] == 'SKIP'

        row_number = index + 2

        object = {}

        # Map a flat CSV to a nested Hash.
        # @seealso https://github.com/OpenDataServices/flatten-tool
        row.each do |key,value|
          if key # ignore unmapped headers
            # A site may not have a name.
            if type == :sites && key == :name__value && value.nil?
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

            assign(object, key.to_s.split('__').map{|key| Integer(key) rescue key}, value)
          end
        end

        # Remove any blank values.
        object = reduce(object)

        # Remove any helper values.
        object.delete('')

        # Skip blank rows.
        if !object.empty?
          # Non-events must have names.
          if type == :events || object.key?('name')
            # @note If new rows for an existing record are not added with IDs, the
            #   new rows will not be merged into the record.
            key = if object['id']
              object['id']
            elsif type == :events
              row_number
            else
              object['name'].fetch('value')
            end

            # Parenthesized numbers just disambiguate records with the same name.
            unless type == :events
              object['name']['value'].sub(/\s*\(\d+\)\z/, '')
            end

            # If it's a row for a new object, add it to the list of objects.
            if !objects[type].key?(key)
              object['gid'] = gid
              object['row'] = row_number
              unless object['id']
                object['id'] = ids[gid][row_number] ||= SecureRandom.uuid
              end
              objects[type][key] = object
            # If it's a row for an existing object, merge it into the existing object.
            elsif objects[type][key] != object
              begin
                differences = objects[type][key].diff_and_merge(object).except('gid', 'row')
                if !differences.empty?
                  LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize.singularize} #{key.inspect} is inconsistent\n#{differences.pretty_inspect}")
                end
              rescue NoMethodError
                LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize.singularize} #{key.inspect} can't calculate difference with:\n#{object.pretty_inspect}")
              end
            end
          else
            LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize.singularize}#name is blank\n#{object.pretty_inspect}")
          end
        end
      end
    end

    schema = JSON.load(File.read(File.expand_path(File.join('schemas', "#{type.to_s.singularize}.json"), __dir__)))

    objects[type].each do |name,object|
      begin
        JSON::Validator.validate!(schema, set_to_array(object))
      rescue JSON::Schema::ValidationError => e
        LOGGER.warn("gid #{object['gid']} row #{object['row']}: #{e.message}")
      end
    end
  end

  # @note Not setting IDs for now based on above `@note`.
  # ids.each do |gid,ids|
  #   ids.each do |row_number,id|
  #     LOGGER.info("gid %10d row %3d: #{id}" % [gid, row_number])
  #   end
  # end
end
