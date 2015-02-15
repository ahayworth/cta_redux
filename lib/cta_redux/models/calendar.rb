module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#calendar_txt___Field_Definitions calendar.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:service_id, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :start_date, :end_date]
  class Calendar < Sequel::Model(:calendar)
    set_primary_key :service_id

    # @!method service_id
    #   @return [String]
    # @!method monday
    #   @return [true,false]
    # @!method tuesday
    #   @return [true,false]
    # @!method wednesday
    #   @return [true,false]
    # @!method thursday
    #   @return [true,false]
    # @!method friday
    #   @return [true,false]
    # @!method saturday
    #   @return [true,false]
    # @!method sunday
    #   @return [true,false]
    # @!method start_date
    #   @return [Date]
    # @!method end_date
    #   @return [Date]

    # @!method trips
    #   A {CTA::Calendar} defines a time period during which multiple {CTA::Trip}s may or may not be active.
    #   @return [Array<CTA::Trip>] All trips associated with this service
    one_to_many :trips, :key => :service_id
  end
end
