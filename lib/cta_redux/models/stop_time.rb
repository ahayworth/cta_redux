module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#stop_times_txt___Field_Definitions stop_times.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # This object can give you the scheduled times that a vehicle should stop along a {CTA::Route} (or really, a {CTA::Trip} if you're being specific).
  # It can also function as somewhat of a 'join table' between trips and stops.
  # @note Current columns: [:trip_id, :arrival_time, :departure_time, :stop_id, :stop_sequence, :stop_headsign, :pickup_type, :shape_dist_traveled]
  class StopTime < Sequel::Model
    # @!method trip
    #   @return [CTA::Trip] The {CTA::Trip} associated with this {CTA::StopTime}
    many_to_one :trip, :key => :trip_id
    # @!method stop
    #   @return [CTA::Stop] The {CTA::Stop} associated with this {CTA::StopTime}
    many_to_one :stop, :key => :stop_id

    # @!method trip_id
    #  @return [Integer]
    # @!method arrival_time
    #  @return [String]
    #  @note This is a string because ruby has no concept of storing a time without a date
    # @!method departure_time
    #  @return [String]
    #  @note This is a string because ruby has no concept of storing a time without a date
    # @!method stop_id
    #  @return [Integer]
    # @!method stop_sequence
    #  @return [Integer]
    # @!method stop_headsign
    #  @return [String]
    # @!method pickup_type
    #  @return [Integer]
    # @!method shape_dist_traveled
    #  @return [Integer]
    alias_method :sequence, :stop_sequence
    alias_method :headsign, :stop_headsign
    alias_method :distance, :shape_dist_traveled
    alias_method :distance_traveled, :shape_dist_traveled
  end
end
