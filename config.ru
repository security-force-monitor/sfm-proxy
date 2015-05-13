require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'json'

require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/object/try'
require 'pupa'
require 'sinatra'
require 'sinatra/cross_origin'

configure do
  enable :cross_origin
end

helpers do
  def connection
    @connection ||= begin
      uri = URI.parse(ENV['MONGOLAB_URI'] || 'mongodb://localhost:27017/sfm')
      connection = Moped::Session.new(["#{uri.host}:#{uri.port}"], database: uri.path[1..-1])
      connection.login(uri.user, uri.password) if uri.user && uri.password
      connection
    end
  end

  def commanders_and_people(organization_id)
    commanders = []
    people = []

    members = connection[:people].find({'memberships.organization_id.value' => organization_id})

    members.each do |member|
      member['memberships'].each do |membership|
        if membership['organization_id']['value'] == organization_id
          item = {
            "id" => member['_id'],
            "name" => member['name'].try(:[], 'value'),
            "other_names" => member['other_names'].try(:[], 'value'),
            # @drupal Add events_count calculated field, equal to the events related to an organization during the membership of the person.
            "events_count" => 12, # @hardcoded
            "date_first_cited" => membership['date_first_cited'].try(:[], 'value'),
            "date_last_cited" => membership['date_last_cited'].try(:[], 'value'),
            "sources" => membership['organization_id']['sources'],
            "confidence" => membership['organization_id']['confidence'],
          }

          if membership['role'].try(:[], 'value') == 'Commander'
            commanders << item
          else
            people << item
          end
        end
      end
    end

    commanders = commanders.sort do |a,b|
      b['date_first_cited'].try(:[], 'value') <=> a['date_first_cited'].try(:[], 'value')
    end

    {
      commanders: commanders,
      people: people,
    }
  end

  def event_formatter(result)
    perpetrator_organization = if result['perpetrator_organization']
      {
        "id" => result['perpetrator_organization']['id'],
        "name" => result['perpetrator_organization']['name'].try(:[], 'value'),
        "other_names" => result['perpetrator_organization']['other_names'].try(:[], 'value'),
        "sources" => result['perpetrator_organization_id']['sources'],
      }
    else
      {
        "name" => result['perpetrator_organization_id'].try(:[], 'value'),
        "sources" => result['perpetrator_organization_id']['sources'],
      }
    end

    {
      "id" => result['_id'],
      "division_id" => result['division_id'],
      "date" => result['date'].try(:[], 'value'),
      "location" => result['location'].try(:[], 'value'),
      "admin_level_1" => result['admin_level_1'].try(:[], 'value'),
      "admin_level_2" => result['admin_level_2'].try(:[], 'value'),
      "classification" => result['classification'].try(:[], 'value'),
      "description" => result['description'].try(:[], 'value'),
      "perpretrator_name" => result['perpretrator_name'].try(:[], 'value'),
      "perpetrator_organization" => perpetrator_organization,
    }
  end
end

require_relative 'lib/events'
require_relative 'lib/countries'
require_relative 'lib/miscellaneous'
require_relative 'lib/organizations'
require_relative 'lib/people'
require_relative 'lib/search'

run Sinatra::Application
