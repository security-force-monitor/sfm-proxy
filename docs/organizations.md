# SFM API: Organizations

## Map

`/organizations/:id/map?` returns an organization's areas, sites and nearby events to render on a map and timeline. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
```

## Chart

`/organizations/:id/chart?` returns the organization's parents and children to render in a chart. Parameters:

* `at`: **Required.** ISO 8601 format `YYYY-MM-DD`.

```json
@todo
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