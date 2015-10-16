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

Import geometries:

    bundle exec rake import_geo country_code=ng

Link areas, events and sites to geometries:

    bundle exec rake link_geometries

Create the geospatial indices in the MongoDB shell:

    db.geometries.createIndex({point: '2dsphere'})
    db.areas.createIndex({point: '2dsphere'})
    db.events.createIndex({point: '2dsphere'})
    db.sites.createIndex({point: '2dsphere'})
    db.geometries.createIndex({geo: '2dsphere'})
    db.areas.createIndex({geo: '2dsphere'})

## Testing

Start a local server:

    rackup

Test the endpoints of a local server:

    bundle exec rake

## Maintenance

Create GeoJSON and TopoJSON from [Natural Earth](http://www.naturalearthdata.com/downloads/110m-cultural-vectors/) shapefiles:

    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' data/geojson/adm0/xa.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='EG'" data/geojson/adm0/eg.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='MX'" data/geojson/adm0/mx.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'iso_a2' -where "iso_a2='NG'" data/geojson/adm0/ng.geojson shapefiles/ne_110m_admin_0_countries/ne_110m_admin_0_countries.shp

    topojson -o data/topojson/adm0/xa.topojson data/geojson/adm0/xa.geojson
    topojson -o data/topojson/adm0/eg.topojson data/geojson/adm0/eg.geojson
    topojson -o data/topojson/adm0/mx.topojson data/geojson/adm0/mx.geojson
    topojson -o data/topojson/adm0/ng.topojson data/geojson/adm0/ng.geojson

If you have access to [GAUL](http://www.fao.org/geonetwork/srv/en/metadata.show?id=12691), extract a country, in this case Nigeria:

    ogr2ogr -f "ESRI Shapefile" -select 'ADM1_CODE,ADM1_NAME' -where "ADM0_CODE=182" shapefiles/gaul_ng_adm1 path/to/g2015_2014_1.shp
    ogr2ogr -f "ESRI Shapefile" -select 'ADM2_CODE,ADM2_NAME,ADM1_CODE,ADM1_NAME' -where "ADM0_CODE=182" shapefiles/gaul_ng_adm2 path/to/g2015_2014_2.shp

In QGIS, simplify the geometries by a factor of 0.01. Then, create GeoJSON:

    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'ADM1_CODE,ADM1_NAME' data/geojson/adm1/ng.geojson shapefiles/gaul_ng_adm1_0.01/gaul_ng_adm1_0.01.shp
    ogr2ogr -f "GeoJSON" -t_srs EPSG:4326 -select 'ADM2_CODE,ADM2_NAME,ADM1_CODE,ADM1_NAME' data/geojson/adm2/ng.geojson shapefiles/gaul_ng_adm2_0.01/gaul_ng_adm2_0.01.shp

**Note:** Creating GeoJSON and TopoJSON from [GADM](http://www.gadm.org/country) shapefiles produces large files:

    bundle exec rake topojson output=adm0/ng input=shapefiles/NGA_adm/NGA_adm0.shp

## Deployment

    heroku apps:create
    heroku addons:create mongolab
    git push heroku master
    heroku run rake import_csv novalidate=true
    heroku run rake import_geo country_code=ng
    bundle exec rake link_geometries

Log into the remote MongoDB database and create the geospatial indices as above.

Copyright (c) 2015 Open North Inc., released under the MIT license
