require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'pp'
require 'securerandom'
require 'set'

require 'active_support/core_ext/hash/except'
require 'active_support/inflector'
require 'faraday'
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
    object.compact.map{|v| reduce(v)}.reject(&:empty?)
  when Hash
    object.reduce({}){|h,(k,v)| h[k] = reduce(v); h}.reject{|_,v| v.respond_to?(:empty?) && v.empty?}
  when Set
    Set.new(object.map{|v| reduce(v)}.reject(&:empty?))
  else
    object
  end
end

# @todo move this CSV import into a Rake task
source_url = 'https://docs.google.com/spreadsheets/d/16cRBkrnXE5iGm8JXD7LSqbeFOg_anhVp2YAzYTRYDgU/export?gid=%d&format=csv'
gids = [0, 1686464613]

objects = {}
names = {}
ids = {}
body = {}

{ sites: gids,
  areas: gids,
  organizations: gids,
  # @todo uncomment
  # people: [510712342, 394650791],
  # events: [939834263],
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
            value = names[gid][row_number] ||= "#{row[:__name]}'s base in #{admin_levels.join(', ')}"
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
        # Objects must have names.
        if object.key?('name')
          # @note If new rows for an existing record are not added with IDs, the
          #   new rows will not be merged into the record.
          key = if object['id']
            object['id']
          else
            object['name'].fetch('value')
          end

          # Parenthesized numbers just disambiguate records with the same name.
          object['name']['value'].sub(/\s*\(\d+\)\z/, '')

          # If it's a row for a new object, add it to the list of objects.
          if !objects[type].key?(key)
            object['row'] = row_number
            unless object['id']
              object['id'] = ids[gid][row_number] ||= SecureRandom.uuid
            end
            objects[type][key] = object
          # If it's a row for an existing object, merge it into the existing object.
          elsif objects[type][key] != object
            differences = objects[type][key].diff_and_merge(object).except('row')
            if !differences.empty?
              LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize.singularize} #{key.inspect} is inconsistent\n#{differences.pretty_inspect}")
            end
          end
        else
          LOGGER.warn("gid #{gid} row #{row_number}: #{type.to_s.capitalize.singularize}#name is blank\n#{object.pretty_inspect}")
        end
      end
    end
  end
end
