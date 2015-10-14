# SFM API: People

## Detail

`/people/:id` returns a person dossier.

Append `.zip` or `.txt` to the path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

```json
{
  "id": "92a458f4-ecc1-441f-8ab7-e68b24cd5695",
  "division_id": "ocd-division/country:ng",
  "name": {
    "value": "Neil Cable",
    "sources": [
      "..."
    ],
    "confidence": "High"
  },
  "other_names": {
    "value": [
      "Black Ranger"
    ],
    "sources": [
      "..."
    ],
    "confidence": "Medium"
  },
  "memberships": [
    {
      "organization_id": {
        "value": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "organization": {
        "name": "Brigade 1"
      },
      "role": {
        "value": "Commander",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "title": {
        "value": "Army Secretary",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "rank": {
        "value": "Major General",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "date_first_cited": {
        "value": "2010-01-01",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "start_date_description": {
        "value": "promoted",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "date_last_cited": {
        "value": "2011-12-31",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "end_date_description": {
        "value": "promoted",
        "sources": [
          "..."
        ],
        "confidence": "High"
      }
    },
    ...
  ],
  "area_present": {
    "type": "Feature",
    "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
    "properties": {},
    "geometry": GeoJSON
  },
  "site_present": {
    "type": "Feature",
    "id": "5947d0de-626d-495f-9c31-eb2ca5afdb6b",
    "properties": {
      "name": "Command Center",
      "location": "Aba North, Abia",
      "geonames_name": "Aba North",
      "admin_level_1_geonames_name": "Abia",
      "sources": [
        "..."
      ],
      "confidence": "Medium"
    },
    "geometry": GeoJSON
  },
  "events": [
    {
      "type": "Feature",
      "id": "a1264d1d-ccd8-4dfb-86f0-ed6bbfb35cfa",
      "properties": {
        "start_date": "2012-01-01",
        "end_date": null,
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia",
        "classification": ["Killing"],
        "perpetrator_name": "Marvin Steele",
        "perpetrator_organization": {
          "id": "123e4567-e89b-12d3-a456-426655440000",
          "name": "Brigade 2",
        }
      },
      "geometry": {
        "type": "Point",
        "coordinates": [90.0, 90.0]
      }
    },
    ...
  ],
  "events_nearby": [
    {
      "type": "Feature",
      "id": "a1264d1d-ccd8-4dfb-86f0-ed6bbfb35cfa",
      "properties": {
        "start_date": "2012-01-01",
        "end_date": null,
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia",
        "classification": ["Killing"],
        "perpetrator_name": "Marvin Steele",
        "perpetrator_organization": {
          "id": "123e4567-e89b-12d3-a456-426655440000",
          "name": "Brigade 2",
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
