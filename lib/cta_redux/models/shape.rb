module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#shapes_txt___Field_Definitions routes.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:shape_id, :shape_pt_lat, :shape_pt_lon, :shape_pt_sequence, :shape_dist_traveled]
  class Shape < Sequel::Model
  end
end
