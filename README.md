# Security Force Monitor: CSV Proxy

    bundle
    bundle exec rake import
    bundle exec rake import novalidate=true
    bundle exec rake topojson input=shapefiles/NGA_adm/NGA_adm0.shp output=adm0/ng

Download shapefiles from [GADM](http://www.gadm.org/country).

## API

### Countries

`/countries/` returns a list of countries:

```json
[
  {
    "id": "ng",
    "name": "Nigeria",
    "geometry": {
      TopoJSON
    }
  },
  ...
]
```

`/countries/:code` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. *Only works for `ng` for now.*

```json
{
  "id": "ng",
  "name": "Nigeria",
  "title": "Federal Republic of Nigeria",
  "description": "...",
  "events_count": 1234
}
```

`/countries/:code.zip` returns all country data as a ZIP archive of CSV files. *Returns 204 No Content for now.*

`/countries/:code.txt` returns all country data as a text file. *Returns 204 No Content for now.*

### Events

`/events/:id` returns an event:

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "division_id": "ng",
  "date": "2010-01-01",
  "location_description": "...",
  "location_admin_level_1": "Abia",
  "location_admin_level_2": "Aba North",
  "classification": [
    "Torture",
    "Disappearance"
  ],
  "description": "...",
  "perpretrator_name": "Terry Guerrier",
  "perpetrator_organization": {
    "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
    "name": "Brigade 1",
    "other_names": [
      "Power Rangers"
    ]
  },
  "organizations_nearby": [
    {
      "id": "123e4567-e89b-12d3-a456-426655440000",
      "name": "Brigade 2",
      "other_names": [
        "The Planeteers"
      ],
      "root_name": "Nigerian Army",
      "person_name": "Michael Maris",
      "events_count": 12
    },
    ...
  ]
}
```

### Organzations

`/organizations/:id` returns an organization dossier:

```json
{
@todo
}
```

### People

`/people/:id` returns a person dossier:

```json
{
@todo
}
```

### Map and timeline

`/map` returns all matching organizations and events to render on a map and timeline. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.
* `bbox`: comma-separated bottom-left and top-right coordinates.
* `classification__in`: comma-separated list.

If an event occurs on a different date than the `at` parameter's value, its only properties will be `id` and `date`.

```json
{
  "organizations": [
    {
      "id": "123e4567-e89b-12d3-a456-426655440000",
      "name": "Brigade 2",
      "other_names": [
        "The Planeteers"
      ],
      "root_name": "Nigerian Army",
      "person_name": "Michael Maris",
      "events_count": 12,
      "geometry": {
        TopoJSON
      }
    },
    ...
  ],
  "events": [
    {
      "id": "de305d54-75b4-431b-adb2-eb6b9e546014",
      "date": "2010-01-01",
      "location_admin_level_1": "Abia",
      "location_admin_level_2": "Aba North",
      "classification": [
        "Torture",
        "Disappearance"
      ],
      "perpretrator_name": "Terry Guerrier",
      "perpetrator_organization": {
        "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
        "name": "Brigade 1"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [90.0, 90.0]
      }
    },
    ...
  ]
}
```

### Organization chart

`/organizations/:id/chart?` returns @todo to render in a chart:

```json
@todo
```

@todo

### Command chart

`/people/:id/chart?` returns @todo to render in a chart:

```json
@todo
```

@todo

### Search

*The API doesn't yet sort by relevance.*

Common parameters:

* `q`: query string.
* `o`: results order, e.g. `events_count` for ascending and `-events_count` for descending.
* `p`: 1-based page number.

Append `.zip` or `.txt` to the search path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

#### Organizations

`/search/organizations?` returns organization search results. Parameters:

* `geonames_id`: GeoNames ID.
* `classification__in`: comma-separated list.
* `date_first_cited__gte`: minimum date first cited.
* `date_first_cited__lte`: maximum date first cited.
* `date_last_cited__gte`: minimum date last cited.
* `date_last_cited__lte`: maximum date last cited.
* `events_count__gte`: minimum events count. *Not yet supported.*
* `events_count__lte`: maximum events count. *Not yet supported.*

Sort orders:

* `name`
* `date_first_cited`
* `date_last_cited`
* `events_count` *Not yet supported*

```json
{
  "count": 1234,
  "facets": [
    @todo
  ],
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426655440000",
      "name": "Brigade 2",
      "other_names": [
        "The Planeteers"
      ],
      "date_first_cited": "2000-01-01",
      "date_last_cited": "2015-01-01",
      "events_count": 12,
      @todo
    },
    ...
  ]
}
```

#### People

`/search/people?` returns person search results. Parameters:

* `geonames_id`: GeoNames ID.
* `classification__in`: comma-separated list.
* `rank__in`: comma-separated list.
* `role__in`: comma-separated list.
* `date_first_cited__gte`: minimum date first cited.
* `date_first_cited__lte`: maximum date first cited.
* `date_last_cited__gte`: minimum date last cited.
* `date_last_cited__lte`: maximum date last cited.
* `events_count__gte`: minimum events count. *Not yet supported.*
* `events_count__lte`: maximum events count. *Not yet supported.*

Sort orders:

* `name`
* `events_count` *Not yet supported*

```json
{
  "count": 1234,
  "facets": [
    "rank": [
      ["Major", 10],
      ["Captain", 1],
      ["Lieutenant", 100]
    ],
    "role": [
      ["Commander", 10],
      ["Acting Commander", 1],
      ["Chief of Staff", 100]
    ]
  ],
  "results": [
    {
      @todo
    }
  ]
}
```

#### Events

`/search/events?` returns event search results. Parameters:

* `geonames_id`: GeoNames ID.
* `classification__in`: comma-separated list.
* `date__gte`: minimum date.
* `date__lte`: maximum date.

Sort orders:

* `date`

Each item in the `results` array is in the same format as the `/events/:id` response, but without the `nearby_organizations` field.

```json
{
  "count": 1234,
  "facets": [
    "classification": [
      ["Disappearance", 10],
      ["Torture", 1],
      ["Killing", 100]
    ]
  ],
  "results": [
    ...
  ]
}
```

### Geometries

`/geometries/:code` returns the TopoJSON for the country with the corresponding lowercase ISO 3166-1 alpha-2 code. The code `xa` returns the TopoJSON for the world.

### Sessions

Copyright (c) 2015 Open North Inc., released under the MIT license
