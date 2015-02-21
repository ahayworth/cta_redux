module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}, inherited from {CTA::Trip}
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Bus < CTA::Trip
    # @return [Live] the {Live} data associated with this {CTA::Bus}, if available.
    # @note a {CTA::Bus} will only contain live data when augmented with an {API::Response}
    attr_accessor :live

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

    # Find a {CTA::Trip} that should be happening, given a timestamp and a route or run.
    # The CTA does not return GTFS trip_id information in either the BusTracker or TrainTracker API, so
    # it is actually somewhat difficult to associate an API response to a {CTA::Trip}. However, we
    # know what *should* be happening at any given time. This method attempts a fuzzy find - internally,
    # we often first try to find the exact Trip that should be happening according to the schedule, and
    # then failing that we assume that the CTA is running late and look for trips that should have
    # ended within the past 90 minutes. This almost always finds something.
    # That said, however, it means we may sometimes find a {CTA::Trip} that's incorrect. In practical usage
    # however, that doesn't matter too much - most Trips for a run service the same stops.
    # However, to be safe, your program may wish to compare certain other bits of the API responses to ensure
    # we found something valid. For example, almost all Brown line trains service the same stops, so
    # finding the wrong Trip doesn't matter too much. However, a handful of Brown line runs throughout the dat
    # actually change to Orange line trains at Midway - so, you may wish to verify that the destination of the
    # Trip matches the reported destination of the API.
    # Suggestions on how to approach this problem are most welcome (as are patches for better behavior).
    # @param [String] run The run or route to search for
    # @param [DateTime, String] timestamp The timestamp to search against.
    # @param [true,false] fuzz Whether or not to do an exact schedule search or a fuzzy search.
    def self.find_active_run(run, timestamp, fuzz = false, direction = nil)
      d = timestamp.is_a?(DateTime) ? timestamp : DateTime.parse(timestamp)
      wday = d.strftime("%A").downcase
      end_ts = (fuzz ? (d.to_time + (60 * 60 * 6) - (90 * 60)) : d).strftime("%H:%M:%S")
      Trip.with_sql(<<-SQL)
        SELECT t.*
        FROM trips t
          JOIN stop_times st ON t.trip_id = st.trip_id
          JOIN calendar   c  ON t.service_id = c.service_id
        WHERE t.route_id = '#{run}'
        #{direction ? "  AND t.direction = '#{direction.gsub("bound", "")}'" : '' }
          AND c.start_date <= '#{d.to_s}'
          AND c.end_date   >= '#{d.to_s}'
          AND c.#{wday}
        GROUP BY t.trip_id, st.departure_time
        HAVING  MAX(st.departure_time) >= '#{end_ts}'
      SQL
    end

    # Returns predictions for this {CTA::Bus}. Accepts all options for {CTA::BusTracker.predictions!}, and will merge in
    # it's own vehicle_id or route_id if present.
    # @param [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :vehicles Vehicles to predict. Not available with :routes
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes to predict. Not available with :vehicles
    # @option options [Array<String>, Array<Integer>, String, Integer] :stops Stops along a route to predict. Required with :routes
    # @option options [String, Integer] :limit Maximum number of predictions to return.
    # @return [CTA::BusTracker::PredictionsResponse]
    # @example
    #   predictions!(:stops => 15895)
    #   predictions!(:limit => 1)
    def predictions!(options = {})
      opts = (self.vehicle_id ? { :vehicles => self.vehicle_id } : { :routes => self.route_id })
      CTA::BusTracker.predictions!(options.merge(opts))
    end

    class Live
      # @return [Float] The latitude of the {CTA::Bus}.
      attr_reader :lat
      # @return [Float] The longitude of the {CTA::Bus}.
      attr_reader :lon
      # @return [Integer] The vehicle_id of the {CTA::Bus}.
      attr_reader :vehicle_id
      # @return [Integer] The heading of the {CTA::Bus}.
      attr_reader :heading
      # @return [Integer] The pattern the {CTA::Bus} is following.
      attr_reader :pattern_id
      # @return [Integer] The distance into the pattern the {CTA::Bus} is following.
      attr_reader :pattern_distance
      # @return [CTA::Route] The {CTA::Route} the {CTA::Bus} is operating.
      attr_reader :route
      # @return [true,false] True if the {CTA::Bus} is considered to be delayed.
      attr_reader :delayed
      # @return [Integer] Last reported speed of the {CTA::Bus}, in mph.
      attr_reader :speed
      # @return [Array<Prediction>] Predictions for this {CTA::Bus}.
      attr_reader :predictions

      def initialize(position, predictions = [])
        @lat = position["lat"].to_f
        @lon = position["lon"].to_f
        @heading = position["hdg"].to_i
        @vehicle_id = position["vid"].to_i
        @pattern_id = position["pid"].to_i
        @pattern_distance = position["pdist"].to_i
        @route = CTA::Route.where(:route_id => position["rt"]).first
        @delayed = (position["dly"] == "true")
        @speed = position["spd"].to_i

        @predictions = Array.wrap(predictions).map { |p| Prediction.new(p) }
      end
    end

    class Prediction
      # @return [String] The type of prediction, either *A*rrival or *D*eparture
      attr_reader :type
      # @return [CTA::Stop] The {CTA::Stop} for this prediction
      attr_reader :stop
      # @return [Integer] The distance remaining until the bus arrives
      attr_reader :distance
      # @return [CTA::Route] The {CTA::Route} associated with this prediction
      attr_reader :route
      # @return [Direction] The {Direction} associated with this prediction
      attr_reader :direction
      # @return [String] The headsign of the bus (final destination, *not* expressed as {CTA::Stop})
      attr_reader :headsign
      # @return [DateTime] The time this {Prediction} was generated on the BusTime servers
      attr_reader :prediction_generated_at
      # @return [DateTime] The time this bus is predicted to arrive or depart
      attr_reader :arrival_time
      # @return [true, false] True if this bus is considered to be delayed
      attr_reader :delayed
      # @return [Integer] The number of minutes until this bus arrives or departs
      attr_reader :minutes
      # @return [Integer] The number of seconds until this bus arrives or departs
      attr_reader :seconds

      def initialize(data)
        @type = data["typ"]
        @stop = CTA::Stop.where(:stop_id => data["stpid"]).first || CTA::Stop.new_from_api_response(data)
        @distance = data["dstp"].to_i
        @route = CTA::Route.where(:route_id => data["rt"]).first
        @direction = CTA::BusTracker::Direction.new(data["rtdir"])
        @headsign = data["des"]
        @prediction_generated_at = DateTime.parse(data["tmstmp"])
        @arrival_time = DateTime.parse(data["prdtm"])
        @seconds = @arrival_time.to_time - @prediction_generated_at.to_time
        @minutes = (@seconds / 60).ceil
        @delayed = (data["dly"] == "true")
      end
    end
  end
end
