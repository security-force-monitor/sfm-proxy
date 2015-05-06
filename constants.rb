HEADERS_MAP = {
  site: {
    'ID' => :id,

    'Name' => :__name, # to set default name

    'Headquarters (Barracks, Base, Physical Asset)' => :name__value,

    'Headquarters GPS Latitude' => :coordinates__value__1__f,
    'Headquarters GPS Longitude' => :coordinates__value__0__f,
    'Source: Headquarters GPS' => :coordinates__sources__n,
    'Confidence: Headquarters GPS' => :coordinates__confidence,

    'ADMIN 1 (City or smallest administrative unit)' => :admin_level_1__value,
    'Source: ADMIN 1' => :admin_level_1__sources__n,
    'Confidence: ADMIN 1' => :admin_level_1__confidence,

    'ADMIN 2 (state, province, governorate, or other largest administrative unit)' => :admin_level_2__value,
    'Source: ADMIN 2' => :admin_level_2__sources__n,
    'Confidence: ADMIN 2' => :admin_level_2__confidence,

    'Geoname' => :geonames_name__value,
    'GeonameID' => :geonames_id__value__i,
  },
  area: {
    'ID' => :id,

    'Area of Responsibility (Area of Operations, Jurisdiction)' => :name__value,
    'Area of Responsibility (Area of Operations, Jurisdiction) Geoname' => :geonames_name__value,
    'Area of Responsibility (Area of Operations, Jurisdiction) GeonameID' => :geonames_id__value__i,
  },
  organization: {
    'ID' => :id,

    'Parent organization' => :parents__0__id__value,
    'Source: Parent organization' => :parents__0__id__sources__n,
    'Confidence: Parent organization' => :parents__0__id__confidence,

    'Organization/Administrative, Command, or Informal parent relationship' => :parents__0__classification__value,
    'Source: Organization/Administrative, Command, or Informal parent relationship' => :parents__0__classification__sources__n,
    'Confidence: Organization/Administrative, Command, or Informal parent relationship' => :parents__0__classification__confidence,

    'Date of first citation for parent organization' => :parents__0__date_first_cited__value__d,
    'Source: Date of first citation for parent organization' => :parents__0__date_first_cited__sources__n,
    'Confidence: Date of first citation for parent organization' => :parents__0__date_first_cited__confidence,

    'Date of last citation for parent organization' => :parents__0__date_last_cited__value__d,
    'Source: Date of last citation for parent organization' => :parents__0__date_last_cited__sources__n,
    'Confidence: Date of last citation for parent organization' => :parents__0__date_last_cited__confidence,

    'Name' => :name__value,
    'Source: Name' => :name__sources__n,
    'Confidence: Name' => :name__confidence,

    'Aliases or alternative spellings (semi-colon separated)' => :other_names__value__n,
    'Source: Aliases or alternative spellings' => :other_names__sources__n,
    'Confidence: Aliases or alternative spellings' => :other_names__confidence,

    'Classification' => :classification__value,
    'Source: Classification' => :classification__sources__n,
    'Confidence: Classification' => :classification__confidence,

    'Headquarters (Barracks, Base, Physical Asset)' => :sites__0__id__value,
    'Source: Headquarters' => :sites__0__id__sources__n,
    'Confidence: Headquarters' => :sites__0__id__confidence,
    'Headquarters GPS Latitude' => nil, # Site
    'Headquarters GPS Longitude' => nil, # Site
    'Source: Headquarters GPS' => nil, # Site
    'Confidence: Headquarters GPS' => nil, # Site
    'ADMIN 1 (City or smallest administrative unit)' => nil, # Site
    'Source: ADMIN 1' => nil, # Site
    'Confidence: ADMIN 1' => nil, # Site
    'ADMIN 2 (state, province, governorate, or other largest administrative unit)' => nil, # Site
    'Source: ADMIN 2' => nil, # Site
    'Confidence: ADMIN 2' => nil, # Site
    'Geoname' => nil, # Site
    'GeonameID' => nil, # Site

    'Area of Responsibility (Area of Operations, Jurisdiction)' => :areas__0__id__value,
    'Source: Area of Responsibility' => :areas__0__id__sources__n,
    'Confidence: Area of Responsibility' => :areas__0__id__confidence,
    'Area of Responsibility (Area of Operations, Jurisdiction) Geoname' => nil, # Area
    'Area of Responsibility (Area of Operations, Jurisdiction) GeonameID' => nil, # Area

    'Date of first citation for area of responsibility' => :areas__0__date_first_cited__value__d,
    'Source: Date of first citation for area of responsibility' => :areas__0__date_first_cited__sources__n,
    'Confidence: Date of first citation for area of responsibility' => :areas__0__date_first_cited__confidence,

    'Date of last citation for area of responsibility' => :areas__0__date_last_cited__value__d,
    'Source: Date of last citation for area of responsibility' => :areas__0__date_last_cited__sources__n,
    'Confidence: Date of last citation for area of responsibility' => :areas__0__date_last_cited__confidence,

    'Other affiliation (like joint task force)' => :memberships__0__organization_id__value,
    'Source: Other affiliation (like joint task force)' => :memberships__0__organization_id__sources__n,
    'Confidence: Other affiliation (like joint task force)' => :memberships__0__organization_id__confidence,

    'Date of first citation for affiliation' => :memberships__0__date_first_cited__value__d,
    'Source: Date of first citation for affiliation' => :memberships__0__date_first_cited__sources__n,
    'Confidence: Date of first citation for affiliation' => :memberships__0__date_first_cited__confidence,

    'Date of last citation for affiliation' => :memberships__0__date_last_cited__value__d,
    'Source: Date of last citation for affiliation' => :memberships__0__date_last_cited__sources__n,
    'Confidence: Date of last citation for affiliation' => :memberships__0__date_last_cited__confidence,

    'International affiliation (like UN peacekeeping)' => :memberships__1__organization_id__value,
    'Source: International affiliation (like UN peacekeeping)' => :memberships__1__organization_id__sources__n,
    'Confidence: International affiliation (like UN peacekeeping)' => :memberships__1__organization_id__confidence,

    'Date of first citation for international affiliation' => :memberships__1__date_first_cited__value__d,
    'Source: Date of first citation for international affiliation' => :memberships__1__date_first_cited__sources__n,
    'Confidence: Date of first citation for international affiliation' => :memberships__1__date_first_cited__confidence,

    'Date of last citation for international affiliation' => :memberships__1__date_last_cited__value__d,
    'Source: Date of last citation for international affiliation' => :memberships__1__date_last_cited__sources__n,
    'Confidence: Date of last citation for international affiliation' => :memberships__1__date_last_cited__confidence,

    'Date of first citation' => :sites__0__date_first_cited__value__d,
    'Source: Date of first citation' => :sites__0__date_first_cited__sources__n,
    'Confidence: Date of first citation' => :sites__0__date_first_cited__confidence,
    'Is this the founding date? (Y/N)' => nil,

    'Date of last citation' => :sites__0__date_last_cited__value__d,
    'Source: Date of last citation' => :sites__0__date_last_cited__sources__n,
    'Confidence: Date of last citation' => :sites__0__date_last_cited__confidence,
    'Is this the dissolution date? (Y/N)' => nil,

    'Notes' => :notes__value,
    'Source: Notes' => :notes__source,
    'Corrections' => nil,
  },
  person: {
    'ID' => :id,

    'Name' => :name__value,
    'Source: Name' => :name__sources__n,
    'Confidence: Name' => :name__confidence,

    'Aliases or alternative spellings (semi-colon separated)' => :other_names__value__n,
    'Source: Aliases or alternative spellings' => :other_names__sources__n,
    'Confidence: Aliases or alternative spellings' => :other_names__confidence,

    'Organization' => :memberships__0__organization_id__value, # membership belongs_to organization
    'Source: Organization' => :memberships__0__organization_id__sources__n,
    'Confidence: Organization' => :memberships__0__organization_id__confidence,

    'Role' => :memberships__0__role__value,
    'Source: Role' => :memberships__0__role__sources__n,
    'Confidence: Role' => :memberships__0__role__confidence,

    'Title (official title)' => :memberships__0__title__value,
    'Source: Title' => :memberships__0__title__sources__n,
    'Confidence: Title' => :memberships__0__title__confidence,

    'Rank' => :memberships__0__rank__value,
    'Source: Rank' => :memberships__0__rank__sources__n,
    'Confidence: Rank' => :memberships__0__rank__confidence,

    'First citation' => :memberships__0__date_first_cited__value__d,
    'Source: First citation' => :memberships__0__date_first_cited__sources__n,
    'Confidence: First citation' => :memberships__0__date_first_cited__confidence,
    'Start date? (Y/N)' => :memberships__0__date_first_cited__actual__b,

    'Context for start date' => :memberships__0__start_date_description__value,
    'Source: Context for start date' => :memberships__0__start_date_description__sources__n,
    'Confidence: Context for start date' => :memberships__0__start_date_description__confidence,

    'Last citation' => :memberships__0__date_last_cited__value__d,
    'Source: Last citation' => :memberships__0__date_last_cited__sources__n,
    'Confidence: Last citation' => :memberships__0__date_last_cited__confidence,
    'End date? (Y/N)' => :memberships__0__date_last_cited__actual__b,

    'Context for end date' => :memberships__0__end_date_description__value,
    'Source: Context for end date' => :memberships__0__end_date_description__sources__n,
    'Confidence: Context for end date' => :memberships__0__end_date_description__confidence,

    "Location (if different from organization's location)" => :memberships__0__site_id__value, # membership belongs_to site
    'Source: Location' => :memberships__0__site_id__sources__n,
    'Confidence: Location' => :memberships__0__site_id__confidence,

    'Notes' => :notes__value,
    'Corrections' => nil,
  },
  event: {
    'ID' => :id,
    'Date' => :date__value__d,
    'Location' => :location_description__value,
    'ADMIN 1 (City or smallest administrative unit)' => :location_admin_level_1__value,
    'ADMIN 2 (state, province, governorate, or other largest subnational administrative unit' => :location_admin_level_2__value,
    'Geoname' => :location_geonames_name__value,
    'GeonameID' => :location_geonames_id__value__i,
    'Latitude' => :location_coordinates__value__1__f,
    'Longitude' => :location_coordinates__value__0__f,
    'Violation type' => :classification__value__n,
    'Description' => :description__value,
    'Perpetrator name' => :perpretrator_name__value,
    'Perpetrator organization' => :perpetrator_organization_id__value, # event belongs_to organization
    'Source: Violator organization' => :perpetrator_organization_id__sources__n,
  }
}
