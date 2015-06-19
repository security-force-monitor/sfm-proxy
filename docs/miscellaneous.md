# SFM API: Miscellaneous

## Base layers

`/geometries/:id.geojson` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. The code `xa` returns all countries as GeoJSON features.

`/geometries/:id.topojson` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. The code `xa` returns all countries.

## Geometries

`/countries/:id/geometries` returns geometries. Parameters:

* `classification`: a GeoNames [feature code](http://www.geonames.org/export/codes.html).
* `bbox`: comma-separated south-west and north-east coordinates.

```json
[
  {
    "type": "Feature",
    "id": 2221333,
    "properties": {
      "name": "River Tunga",
      "classification": "STM"
    },
    "geometry": GeoJSON
  },
  ...
]
```

## Sessions

To log in and log out.

```json
@todo
```
