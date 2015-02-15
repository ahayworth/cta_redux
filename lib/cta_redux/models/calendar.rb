module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#calendar_txt___Field_Definitions calendar.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:service_id, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :start_date, :end_date]
  class Calendar < Sequel::Model(:calendar)
    set_primary_key :service_id

    # @!method trips
    #   A {CTA::Calendar} defines a time period during which multiple {CTA::Trip}s may or may not be active.
    #   @return [Array<CTA::Trip>] All trips associated with this service
    one_to_many :trips, :key => :service_id
  end
end
