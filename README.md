# Security Force Monitor: CSV Proxy

## API

* [Country list and detail](/docs/countries.md)
* [Event map and detail](/docs/events.md)
* [Organization map, chart and detail](/docs/organizations.md)
* [Person chart and detail](/docs/people.md)
* [Search organizations, peopl and events](/docs/search.md)
* [Base layers and sessions](/docs/miscellaneous.md)

## Tasks

Use [rbenv](https://github.com/sstephenson/rbenv) or [rvm](https://rvm.io/). Install dependencies:

    gem install bundler
    bundle

Drop the local `sfm` MongoDB database, and import the data from Google Sheets:

    mongo sfm --eval "db.dropDatabase()"
    bundle exec rake import_csv

To import faster, skip the validation of records against the JSON Schema:

    bundle exec rake import_csv novalidate=true

Import admin level 1 and 2 geometries:

    bundle exec rake import_geo admin_level=1 country_code=ng
    bundle exec rake import_geo admin_level=2 country_code=ng

Create the geospatial indices:

    mongo sfm --eval "db.events.createIndex({geo: '2dsphere'})"
    mongo sfm --eval "db.sites.createIndex({geo: '2dsphere'})"
    mongo sfm --eval "db.geometries.createIndex({geo: '2dsphere'})"

Start a local server:

    rackup

Test the endpoints of a local server:

    bundle exec rake

Create GeoJSON and TopoJSON from [Natural Earth](http://www.naturalearthdata.com/downloads/110m-cultural-vectors/) shapefiles:

    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' data/geojson/adm0/xa.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='EG'" data/geojson/adm0/eg.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='MX'" data/geojson/adm0/mx.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='NG'" data/geojson/adm0/ng.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp

    topojson -o data/topojson/adm0/xa.topojson data/geojson/adm0/xa.geojson
    topojson -o data/topojson/adm0/eg.topojson data/geojson/adm0/eg.geojson
    topojson -o data/topojson/adm0/mx.topojson data/geojson/adm0/mx.geojson
    topojson -o data/topojson/adm0/ng.topojson data/geojson/adm0/ng.geojson

**Note:** Creating GeoJSON and TopoJSON from [GADM](http://www.gadm.org/country) shapefiles produces large files:

    bundle exec rake topojson output=adm0/ng input=shapefiles/NGA_adm/NGA_adm0.shp

## Deployment

    heroku apps:create
    heroku addons:create mongolab
    git push heroku master
    heroku run rake import_csv novalidate=true
    heroku run rake import_geo admin_level=1 country_code=ng
    heroku run rake import_geo admin_level=2 country_code=ng

Log into the remote MongoDB database and create the geospatial indices.

Copyright (c) 2015 Open North Inc., released under the MIT license
