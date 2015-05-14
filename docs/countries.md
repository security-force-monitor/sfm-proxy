# SFM API: Countries

## List

`/countries/` returns a list of countries as GeoJSON features.

```json
[
  {
    "type": "Feature",
    "id": "ng",
    "properties": {
      "name": "Nigeria",
    }
    "bbox": [
      {
        "lon": "WEST",
        "lat": "SOUTH"
      },
      {
        "lon": "EAST",
        "lat": "NORTH"
      }
    ],
    "geometry": ...
  },
  ...
]
```

## Detail

`/countries/:id` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. *Only works for `ng` for now.*

`/countries/:id.zip` returns all country data as a ZIP archive of CSV files. *Returns 204 No Content for now.*

`/countries/:id.txt` returns all country data as a text file. *Returns 204 No Content for now.*

```json
{
  "id": "ng",
  "name": "Nigeria",
  "title": "Federal Republic of Nigeria",
  "description": "...",
  "events_count": 1234
}
```
