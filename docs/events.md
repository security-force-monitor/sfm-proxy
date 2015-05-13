# SFM API: Events

## Map

`/countries/:id/map` returns all matching organizations and events to render on a map and timeline. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.
* `bbox`: comma-separated south-west and north-east coordinates.
* `classification__in`: comma-separated list.

```json
{
  "organizations": [
    {
      "type": "Feature",
      "id": "123e4567-e89b-12d3-a456-426655440000",
      "properties": {
        "name": "Brigade 2",
        "other_names": [
          "The Planeteers"
        ],
        "root_name": "Nigerian Army",
        "commander_present": {
          "name": "Michael Maris"
        },
        "events_count": 12
      },
      "geometry": GeoJSON
    },
    ...
  ],
  "events": [
    {
      "type": "Feature",
      "id": "de305d54-75b4-431b-adb2-eb6b9e546014",
      "properties": {
        "date": "2010-01-01",
        "admin_level_1": "Abia",
        "admin_level_2": "Aba North",
        "classification": [
          "Torture",
          "Disappearance"
        ],
        "perpretrator_name": "Terry Guerrier",
        "perpetrator_organization": {
          "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
          "name": "Brigade 1"
        }
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

## List

`/countries/:id/events` returns all events to render on a timeline.

```json
[
  {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "date": "2010-01-01",
  },
  ...
]
```

## Detail

`/events/:id` returns an event.

```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "division_id": "ocd-division/country:ng",
  "date": "2010-01-01",
  "location": "...",
  "admin_level_1": "Abia",
  "admin_level_2": "Aba North",
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
