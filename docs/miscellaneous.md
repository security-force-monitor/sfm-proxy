# SFM API: Miscellaneous

## Base layers

`/geometries/:id.geojson` returns the country with the corresponding lowercase ISO 3166-1 alpha-2 code. The code `xa` returns all countries as GeoJSON features.

Optionally pass the query parameter `tolerance` as a floating point between 0 and 1 to simplify the returned geometries. Numbers closer to 1 will return simpler geometries. Defaults to `0.001`.

## Geometries

`/countries/:id/geometries` returns geometries. Parameters:

* `classification`: a GeoNames [feature code](http://www.geonames.org/export/codes.html).
* `bbox`: comma-separated south-west and north-east coordinates.
* `tolerance`: Floating point between 0 and 1 that determines simplicity of returned geometries.

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


