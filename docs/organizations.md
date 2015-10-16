# SFM API: Organizations

## Map

`/organizations/:id/map?` returns an organization's areas, sites and nearby events to render on a map and timeline. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.
* `bbox`: comma-separated south-west and north-east coordinates.

```json
{
  "area": {
    "type": "Feature",
    "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
    "properties": {},
    "geometry": GeoJSON
  },
  "sites": [
    {
      "type": "Feature",
      "id": "5947d0de-626d-495f-9c31-eb2ca5afdb6b",
      "properties": {
        "name": "Command Center",
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [90.0, 90.0]
      }
    },
    ...
  ],
  "events": [
    {
      "type": "Feature",
      "id": "1f3e4427-ae20-4cc6-abc4-a70b6ed3c7e0",
      "properties": {
        "start_date": "2010-01-01",
        "end_date": null,
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia",
        "classification": [
          "Torture",
          "Disappearance"
        ],
        "perpetrator_name": "Terry Guerrier",
        "perpetrator_organization": {
          "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
          "name": "Brigade 1",
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

## Chart

`/organizations/:id/chart?` returns the organization's parents and children to render in a chart. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
[
  {
    "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
    "name": "Brigade 1",
    "events_count": 12,
    "parent_id": "010bfd80-4eed-4843-807c-20bd34eaf7aa",
    "classification": "Brigade",
    "commander": {
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
    }
  }
]
```

## Detail

`/organizations/:id` returns an organization dossier.

Append `.zip` or `.txt` to the path to export as `text/csv` or `text/plain`. *Returns 204 No Content for now.*

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
  "root_id": {
    "value": "98185305-7ac0-4f7d-b354-efb052d1d3f1"
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
      "type": "Feature",
      "id": "1f3e4427-ae20-4cc6-abc4-a70b6ed3c7e0",
      "properties": {
        "start_date": "2010-01-01",
        "end_date": null,
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia",
        "classification": [
          "Torture",
          "Disappearance"
        ],
        "perpetrator_name": "Terry Guerrier",
        "perpetrator_organization": {
          "id": "42bb1cff-eed5-4458-a9b4-b00bad09f615",
          "name": "Brigade 1",
        }
      },
      "geometry": {
        "type": "Point",
        "coordinates": [90.0, 90.0]
      }
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
      "commander_present": ...,
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
      "commander_present": ...,
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
      "type": "Feature",
      "id": "6e8ec539-4d90-41f4-9169-564a40ba5790",
      "properties": {
        "name": "Aba North",
        "date_first_cited": "2005-01-01",
        "date_last_cited": "2015-01-01",
        "sources": [
          "..."
        ],
        "confidence": "High"
      },
      "geometry": GeoJSON
    },
    ...
  ],
  "sites": [
    {
      "type": "Feature",
      "id": "5947d0de-626d-495f-9c31-eb2ca5afdb6b",
      "properties": {
        "name": "Command Center",
        "location": "Aba North, Abia",
        "geonames_name": "Aba North",
        "admin_level_1_geonames_name": "Abia",
        "date_first_cited": "2008-01-01",
        "date_last_cited": "2012-01-01",
        "sources": [
          "..."
        ],
        "confidence": "Medium"
      },
      "geometry": GeoJSON
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
