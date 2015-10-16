# Changelog

## 0.0.2

### API

* Added `location` field to Area and Site.
* `/people/:id` returns `area_present`, `site_present`, `events` and `events_nearby` as GeoJSON.
* `/organizations/:id` returns `areas`, `sites`, `events` and `events_nearby` as GeoJSON.
* `/countries/:id/autocomplete/geonames_id` returns GeoJSON.
* `/countries/:id/search/organizations` returns `site_present` as GeoJSON.
* `/countries/:id/search/people` returns `membership_present.organization.site_present` as GeoJSON.

### Models

* Area:
  * `geonames_name` removed (redundant with `name`).
* Event:
  * `admin_level_1` renamed `admin_level_1_geonames_name`.
  * `admin_level_1_geonames_id` added.
  * `admin_level_2` removed (redundant with `geonames_name`).
  * `sources` moved from `perpetrator_organization` to top-level.
* Organization:
  * `sources` removed from `notes`.
* Site:
  * `admin_level_1` renamed `admin_level_1_geonames_name`.
  * `admin_level_1_geonames_id` added.
  * `admin_level_2` removed (redundant with `geonames_name`).

## 0.0.1

Initial release.
