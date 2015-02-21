module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Trip < Sequel::Model
    L_ROUTES = ["Brn", "G", "Pink", "P", "Org", "Red", "Blue", "Y"]
    BUS_ROUTES = CTA::Trip.exclude(:route_id => L_ROUTES).select_map(:route_id).uniq
    plugin :single_table_inheritance,
           :route_id,
           :model_map => proc { |v|
             if L_ROUTES.include?(v)
               'CTA::Train'
             else
               'CTA::Bus'
             end
           },
           :key_map => proc { |klass|
             if klass.name == 'CTA::Train'
               L_ROUTES
             else
               BUS_ROUTES
             end
           }

    set_primary_key :trip_id

    # @!method calendar
    #   @return [CTA::Calendar] The {CTA::Calendar} entry for this {CTA::Trip}. Can be used to determine
    #     if a given {CTA::Trip} is valid for a given date/time
    many_to_one :calendar, :key => :service_id

    # @!method stop_times
    #   @return [Array<CTA::StopTime>] The {CTA::StopTimes} that are serviced on this {CTA::Trip}
    one_to_many :stop_times, :key => :trip_id

    # @!method route
    #   @return [CTA::Route] The {CTA::Route} associated with this {CTA::Trip}
    many_to_one :route, :key => :route_id

    # @!method stops
    #   @return [Array<CTA::Stop>] All {CTA::Stop}s serviced on this {CTA::Trip}
    many_to_many :stops, :left_key => :trip_id, :right_key => :stop_id, :join_table => :stop_times

    # @!method shapes
    #   @return [Array<CTA::Shape>] All {CTA::Shape}s related to this {CTA::Trip}
    many_to_many :shapes, :left_key => :trip_id, :right_key => :shape_id, :join_table => :trips

    # @!method route_id
    #  @return [String]
    # @!method service_id
    #  @return [Integer]
    # @!method trip_id
    #  @return [Integer]
    # @!method direction_id
    #  @return [Integer]
    # @!method block_id
    #  @return [Integer]
    # @!method shape_id
    #  @return [Integer]
    # @!method direction
    #  @return [String]
    # @!method wheelchair_accessible
    #  @return [true,false]
    # @!method schd_trip_id
    #  @return [String]
    alias_method :id, :route_id
    alias_method :scheduled_trip_id, :schd_trip_id
    alias_method :run, :schd_trip_id
  end
end
