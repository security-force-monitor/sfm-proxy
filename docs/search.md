# SFM API: Search

Common parameters:

* `q`: query string.
* `o`: results order, e.g. `events_count` for ascending and `-events_count` for descending.
* `p`: 1-based page number.

Common sort orders:

* `_score` (default) *Not yet supported.*

Append `.zip` or `.txt` to the search path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

## Autocomplete

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
## Organizations

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

## People

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

## Events

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
  "facets": {
    "classification": [
      ["Disappearance", 10],
      ["Torture", 1],
      ["Killing", 100]
    ]
  },
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