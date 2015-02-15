module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#shapes_txt___Field_Definitions routes.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence, :shape_dist_traveled]
  class Shape < Sequel::Model
    # @!method shape_id
    #  @return [Integer]
    # @!method shape_pt_lat
    #  @return [Float]
    # @!method shape_pt_lon
    #  @return [Float]
    # @!method shape_pt_sequence
    #  @return [Integer]
    # @!method shape_dist_traveled
    #  @return [Integer]
    alias_method :id, :shape_id
    alias_method :lat, :shape_pt_lat
    alias_method :lon, :shape_pt_lon
    alias_method :sequence, :shape_pt_sequence
    alias_method :distance, :shape_dist_traveled
    alias_method :distance_traveled, :shape_dist_traveled
  end
end
