# Security Force Monitor: CSV Proxy

    bundle
    bundle exec rake import
    bundle exec rake import novalidate=true
    bundle exec rake topojson input=shapefiles/NGA_adm/NGA_adm0.shp output=adm0/ng

Download shapefiles from [GADM](http://www.gadm.org/country).

## API

* [Country list and detail](/opennorth/sfm-proxy/blob/master/docs/countries.md)
* [Event map and detail](/opennorth/sfm-proxy/blob/master/docs/events.md)
* [Organization map, chart and detail](/opennorth/sfm-proxy/blob/master/docs/organizations.md)
* [Person chart and detail](/opennorth/sfm-proxy/blob/master/docs/people.md)
* [Search](/opennorth/sfm-proxy/blob/master/docs/search.md)
* [Base layers and sessions](/opennorth/sfm-proxy/blob/master/docs/miscellaneous.md)

Copyright (c) 2015 Open North Inc., released under the MIT license
