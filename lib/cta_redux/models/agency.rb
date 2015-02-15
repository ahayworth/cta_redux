module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#agency_txt___Field_Definitions agency.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:agency_name, :agency_url, :agency_timezone, :agency_lang, :agency_phone, :agency_fare_url]
  class Agency < Sequel::Model(:agency)
  end
end
