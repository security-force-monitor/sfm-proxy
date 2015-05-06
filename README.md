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
    "geometry": TopoJSON
  },
  ...
]
```

`/countries/:id` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. *Only works for `ng` for now.*

```json
{
  "id": "ng",
  "name": "Nigeria",
  "title": "Federal Republic of Nigeria",
  "description": "...",
  "events_count": 1234
}
```

`/countries/:id.zip` returns all country data as a ZIP archive of CSV files. *Returns 204 No Content for now.*

`/countries/:id.txt` returns all country data as a text file. *Returns 204 No Content for now.*

### Events

`/events/:id` returns an event:

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "division_id": "ocd-division/country:ng",
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

### Organizations

`/organizations/:id` returns an organization dossier.

```json
{
  "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
  "division_id": "ocd-division/country:ng",
  "name": {
    "value": "Brigade 1",
    "sources": [
      "..."
    ],
    "confidence": "High"
  },
  "other_names": {
    "value": [
      "Power Rangers"
    ],
    "sources": [
      "..."
    ],
    "confidence": "Medium"
  },
  "events_count": 12,
  "classification": {
    "value": "Brigade",
    "sources": [
      "..."
    ],
    "confidence": "High"
  },
  "root_name": {
    "value": "Military"
  },
  "date_first_cited": {
    "value": "2000-01-01",
    "sources": [
      "..."
    ],
    "confidence": "Low"
  },
  "date_last_cited": {
    "value": "2015-01-01",
    "sources": [
      "..."
    ],
    "confidence": "Low"
  },
  "commander_present": {
    "id": "92a458f4-ecc1-441f-8ab7-e68b24cd5695",
    "name": "Neil Cable",
    "other_names": [
      "Black Ranger"
    ],
    "events_count": 1,
    "date_first_cited": "2014-08-01",
    "date_last_cited": "2014-12-01",
    "sources": [
      "..."
    ],
    "confidence": "High"
  },
  "commanders_former": [
    {
      "id": "358eba6d-d37d-4f0f-b12b-b25fefb38e6f",
      "name": "Terry Guerrier",
      "other_names": [
        "Red Ranger"
      ],
      "events_count": 12,
      "date_first_cited": "2008-01-01",
      "date_last_cited": "2012-01-01",
      "sources": [
        "..."
      ],
      "confidence": "High"
    },
    ...
  ],
  "events": [
    {
      "id": "eba734d7-8078-4af5-ae8f-838c0d47fdc0",
      "date": "2010-01-01",
      "location_admin_level_1": "Abia",
      "location_admin_level_2": "Abia North",
      "classification": [
        "Torture",
        "Disappearance"
      ],
      "perpretrator_name": "Terry Guerrier"
    },
    ...
  ],
  "parents": [
    {
      "id": "010bfd80-4eed-4843-807c-20bd34eaf7aa",
      "name": "Division 1",
      "other_names": [
        "Power Rangers Megaforce"
      ],
      "events_count": 1,
      "date_first_cited": "2013-01-01",
      "date_last_cited": "2014-01-01",
      "sources": [
        "..."
      ],
      "confidence": "High"
    },
    ...
  ],
  "children": [
    {
      "id": "38d400b6-e3b4-4e38-9d33-ddb7d95460a2",
      "name": "Battalion 1",
      "other_names": [
        "Power Rangers Samurai"
      ],
      "events_count": 1,
      "date_first_cited": "2011-01-01",
      "date_last_cited": "2012-01-01",
      "sources": [
        "..."
      ],
      "confidence": "High"
    },
    ...
  ],
  "people": [
    {
      "id": "7bcdfa40-ca33-45c2-ba89-b57b8a7c1bc5",
      "name": "Curtis Estes",
      "other_names": [
        "Green Ranger"
      ],
      "events_count": 1,
      "date_first_cited": "2007-01-01",
      "date_last_cited": "2009-01-01",
      "sources": [
        "..."
      ],
      "confidence": "Low"
    },
    ...
  ],
  "memberships": [
    {
      "id": "fbe2ea0f-1325-4df1-bbfd-b96f761e0177",
      "name": "JTF Joint Task Force",
      "other_names": [
        "Samurai Pizza Cats"
      ],
      "date_first_cited": "2011-04-01",
      "date_last_cited": "2011-08-01",
      "sources": [
        "..."
      ],
      "confidence": "Low"
    },
    ...
  ],
  "areas": [
    {
      "id": "6e8ec539-4d90-41f4-9169-564a40ba5790",
      "name": "Abia North",
      "date_first_cited": "2005-01-01",
      "date_last_cited": "2015-01-01",
      "sources": [
        "..."
      ],
      "confidence": "High"
    },
    ...
  ],
  "sites": [
    {
      "id": "5947d0de-626d-495f-9c31-eb2ca5afdb6b",
      "name": "Command Center",
      "admin_level_1": "Abia",
      "admin_level_2": "Abia North",
      "date_first_cited": "2008-01-01",
      "date_last_cited": "2012-01-01",
      "sources": [
        "..."
      ],
      "confidence": "Medium"
    },
    ...
  ],
  "events_nearby": [
    {
      "id": "a1264d1d-ccd8-4dfb-86f0-ed6bbfb35cfa",
      "date": "2012-01-01",
      "location_admin_level_1": "Abia",
      "location_admin_level_2": "Abia North",
      "classification": ["Killing"],
      "perpretrator_name": "Marvin Steele"
    },
    ...
  ]
}
```

Append `.zip` or `.txt` to the path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

### People

`/people/:id` returns a person dossier.

```json
{
@todo
}
```

Append `.zip` or `.txt` to the path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

### Map and timeline

`/countries/:id/map` returns all matching organizations and events to render on a map and timeline. Parameters:

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
      "geometry": TopoJSON
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

### Organization map

`/organizations/:id/map?` returns an organization's areas, sites and nearby events to render on a map and timeline. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
```

### Organization chart

`/organizations/:id/chart?` returns the organization's parents and children to render in a chart. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
```

### Command chart

`/people/:id/chart?` returns the person's superior and inferior posts to render in a chart. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
```

### Search

Common parameters:

* `q`: query string.
* `o`: results order, e.g. `events_count` for ascending and `-events_count` for descending.
* `p`: 1-based page number.

Common sort orders:

* `_score` (default) *Not yet supported.*

Append `.zip` or `.txt` to the search path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

#### Organizations

`/countries/:id/search/organizations?` returns organization search results. Parameters:

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
  "facets": {
  },
  "results": [
    {
      "id": "123e4567-e89b-12d3-a456-426655440000",
      "division_id": "ocd-division/country:ng",
      "name": "Brigade 2",
      "other_names": [
        "The Planeteers"
      ],
      "events_count": 12,
      "classification": "Brigade",
      "site_present": {
        "date_first_cited": "2000-01-01",
        "date_last_cited": "2015-01-01",
        "admin_level_1": "Abia",
        "admin_level_2": "Abia North"
      },
      "commander_present": {
        "name": "Michael Maris"
      }
    },
    ...
  ]
}
```

#### People

`/countries/:id/search/people?` returns person search results. Parameters:

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
  "facets": {
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
  },
  "results": [
    {
      "id": "358eba6d-d37d-4f0f-b12b-b25fefb38e6f",
      "division_id": "ocd-division/country:ng",
      "name": "Terry Guerrier",
      "other_names": [
        "Red Ranger"
      ],
      "events_count": 12,
      "membership_present": {
        "organization": {
          "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
          "name": "Brigade 1"
        },
        "role": "Commander",
        "title": "Captain of the Watch",
        "rank": "Captain",
        "site_present": {
          "admin_level_1": "Abia",
          "admin_level_2": "Abia North"
        }
      },
      "membership_former": {
        "organization": {
          "id": "123e4567-e89b-12d3-a456-426655440000",
          "name": "Brigade 2"
        },
        "role": "Commander",
        "title": "Captain of the Guard",
        "rank": "Captain"
      }
    }
  ]
}
```

#### Events

`/countries/:id/search/events?` returns event search results. Parameters:

* `geonames_id`: GeoNames ID.
* `classification__in`: comma-separated list.
* `date__gte`: minimum date.
* `date__lte`: maximum date.

Sort orders:

* `date`

Each item in the `results` array is in the same format as the `/events/:id` response, but with a `sites_nearby` field instead of a `organizations_nearby` field.

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

The `sites_nearby` field looks like:

```json
{
  "sites_nearby": [
    {
      "name": "Atlantis"
    }
  ]
}
```

### Autocomplete

`/autocomplete/geonames_id` returns GeoNames and GeoNames IDs.

```json
[
  {
    "id": 2221333,
    "name": "River Tunga"
  },
  ...
]
```

### Base layers

`/geometries/:id` returns the TopoJSON for the country with the corresponding lowercase ISO 3166-1 alpha-2 code. The code `xa` returns the TopoJSON for the world.

```json
@todo
```

### Sessions

To log in and log out.

```json
@todo
```

Copyright (c) 2015 Open North Inc., released under the MIT license
