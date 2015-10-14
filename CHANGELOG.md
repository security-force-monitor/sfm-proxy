# Changelog

## 0.0.2

* Area:
  * `geonames_name` removed (redundant with `name`).
  * `location` added (API only).
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
  * `location` added (API only).

## 0.0.1

Initial release.
