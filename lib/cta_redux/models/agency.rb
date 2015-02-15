module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#agency_txt___Field_Definitions agency.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:agency_name, :agency_url, :agency_timezone, :agency_lang, :agency_phone, :agency_fare_url]
  class Agency < Sequel::Model(:agency)
    # @!method agency_name
    #  @return [String]
    # @!method agency_url
    #  @return [String]
    # @!method agency_timezone
    #  @return [String]
    # @!method agency_lang
    #  @return [String]
    # @!method agency_phone
    #  @return [String]
    # @!method agency_fare_url
    #  @return [String]
    alias_method :name, :agency_name
    alias_method :url, :agency_url
    alias_method :timezone, :agency_timezone
    alias_method :language, :agency_lang
    alias_method :phone, :agency_phone
    alias_method :fare_url, :agency_fare_url
  end
end
