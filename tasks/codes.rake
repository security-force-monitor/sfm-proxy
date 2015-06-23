namespace :codes do
  def endpoint
    ENV['endpoint'] || 'http://sfm-proxy.herokuapp.com'
  end

  desc 'Prints event classifications'
  task :event_classification do
    puts JSON.load(Faraday.get("#{endpoint}/countries/ng/search/events").body)['facets']['classification'].map(&:first).sort
  end

  desc 'Prints organization classifications'
  task :organization_classification do
    puts JSON.load(Faraday.get("#{endpoint}/countries/ng/search/organizations").body)['facets']['classification'].map(&:first).sort
  end

  desc 'Prints person ranks'
  task :rank do
    puts JSON.load(Faraday.get("#{endpoint}/countries/ng/search/people").body)['facets']['rank'].map(&:first).compact.sort
  end

  desc 'Prints person roles'
  task :role do
    puts JSON.load(Faraday.get("#{endpoint}/countries/ng/search/people").body)['facets']['role'].map(&:first).compact.sort
  end
end
