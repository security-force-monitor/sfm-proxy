HEADERS_MAP = {
  site: {
    'ID' => :id,

    'Name' => :__name, # to set default name

    'Headquarters (Barracks, Base, Physical Asset)' => :name__value,

    'City or smallest administrative unit GeoName' => :geonames_name__value,
    'City or smallest administrative unit GeonameID' => :geonames_id__value__i,
    'Source: City or smallest administrative unit' => :geonames_name__sources__n,
    'Confidence: City or smallest administrative unit' => :geonames_name__confidence,

    'ADMIN1 (state, province, governorate, or other largest administrative unit) Geoname' => :admin_level_1_geonames_name__value,
    'ADMIN1 (state, province, governorate, or other largest administrative unit) GeonameID' => :admin_level_1_geonames_id__value__i,
    'Source: ADMIN1' => :admin_level_1_geonames_name__sources__n,
    'Confidence: ADMIN1' => :admin_level_1_geonames_name__confidence,
  },
  area: {
    'ID' => :id,

    'Area of Responsibility (Area of Operations, Jurisdiction) Geoname' => :name__value,
    'Area of Responsibility (Area of Operations, Jurisdiction) GeonameID' => :geonames_id__value__i,
  },
  organization: {
    'ID' => :id,

    'Parent organization' => :parents__0__id__value,
    'Source: Parent organization' => :parents__0__id__sources__n,
    'Confidence: Parent organization' => :parents__0__id__confidence,

    'Administrative, Command, or Informal parent relationship' => :parents__0__classification__value,
    'Source: Administrative, Command, or Informal parent relationship' => :parents__0__classification__sources__n,
    'Confidence: Administrative, Command, or Informal parent relationship' => :parents__0__classification__confidence,

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

    'Classification' => :classification__value__n,
    'Source: Classification' => :classification__sources__n,
    'Confidence: Classification' => :classification__confidence,

    'Headquarters (Barracks, Base, Physical Asset)' => :sites__0__id__value,
    'Source: Headquarters' => :sites__0__id__sources__n,
    'Confidence: Headquarters' => :sites__0__id__confidence,
    'City or smallest administrative unit GeoName' => nil, # Site
    'City or smallest administrative unit GeonameID' => nil, # Site
    'Source: City or smallest administrative unit' => nil, # Site
    'Confidence: City or smallest administrative unit' => nil, # Site
    'ADMIN1 (state, province, governorate, or other largest administrative unit) Geoname' => nil, # Site
    'ADMIN1 (state, province, governorate, or other largest administrative unit) GeonameID' => nil, # Site
    'Source: ADMIN1' => nil, # Site
    'Confidence: ADMIN1' => nil, # Site

    'Area of Responsibility (Area of Operations, Jurisdiction) Geoname' => :areas__0__id__value,
    'Area of Responsibility (Area of Operations, Jurisdiction) GeonameID' => nil, # Area
    'Source: Area of Responsibility' => :areas__0__id__sources__n,
    'Confidence: Area of Responsibility' => :areas__0__id__confidence,

    'Date of first citation for area of responsibility' => :areas__0__date_first_cited__value__d,
    'Source: Date of first citation for area of responsibility' => :areas__0__date_first_cited__sources__n,
    'Confidence: Date of first citation for area of responsibility' => :areas__0__date_first_cited__confidence,

    'Date of last citation for area of responsibility' => :areas__0__date_last_cited__value__d,
    'Source: Date of last citation for area of responsibility' => :areas__0__date_last_cited__sources__n,
    'Confidence: Date of last citation for area of responsibility' => :areas__0__date_last_cited__confidence,
    'Assume Area of Operations to Current Date? (Y/N)' => :areas__0__open_ended__value__b,

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
    'Is this the founding date? (Y/N)' => nil, # Not relevant, as this date was re-associated to the site.

    'Date of last citation' => :sites__0__date_last_cited__value__d,
    'Source: Date of last citation' => :sites__0__date_last_cited__sources__n,
    'Confidence: Date of last citation' => :sites__0__date_last_cited__confidence,
    'Is this the dissolution date? (Y/N)' => nil, # Not relevant, as this date was re-associated to the site.

    'Notes' => :notes__value,
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
    'Start Date' => :start_date__value__d,
    'End Date' => :end_date__value__d,
    'Location' => :location__value,
    'City or smallest administrative unit GeoName' => :geonames_name__value,
    'City or smallest administrative unit GeonameID' => :geonames_id__value__i,
    'ADMIN1 Geoname' => :admin_level_1_geonames_name__value,
    'ADMIN1 GeonameID' => :admin_level_1_geonames_id__value__i,
    'Violation type' => :classification__value__n,
    'Description' => :description__value,
    'Perpetrator name' => :perpetrator_name__value,
    'Perpetrator organization' => :perpetrator_organization_id__value, # event belongs_to organization
    'Perpetrator Classification' => :perpetrator_organization_classification__value__n,
    'Source' => :sources__value__n,
  }
}
