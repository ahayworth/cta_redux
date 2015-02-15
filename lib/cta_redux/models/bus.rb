module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}, inherited from {CTA::Trip}
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Bus < CTA::Trip
    # Returns predictions for this {CTA::Bus}. Accepts all options for {CTA::BusTracker.predictions!}, and will merge in
    # it's own vehicle_id or route_id if present.
    # @params [Hash] options
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

    # Used internally by cta_redux to augment a Sequel::Model with API data.
    def live!(position, predictions = [])
      class << self

        # @!attribute [r] lat
        # @return [Float] The latitude of the bus. Only defined when augmented with an API response.
        attr_reader :lat
        # @!attribute [r] lon
        # @return [Float] The longitude of the bus. Only defined when augmented with an API response.
        attr_reader :lon
        # @!attribute [r] vehicle_id
        # @return [Integer] The vehicle_id of the bus. Only defined when augmented with an API response.
        attr_reader :vehicle_id
        # @!attribute [r] heading
        # @return [Integer] The heading of the bus. Only defined when augmented with an API response.
        attr_reader :heading
        # @!attribute [r] pattern_id
        # @return [Integer] The pattern the bus is following. Only defined when augmented with an API response.
        attr_reader :pattern_id
        # @!attribute [r] pattern_distance
        # @return [Integer] The distnace into the pattern the bus is following. Only defined when augmented with an API response.
        attr_reader :pattern_distance
        # @!attribute [r] route
        # @return [CTA::Route] The {CTA::Route} the bus is operation. Only defined when augmented with an API response.
        attr_reader :route
        # @!attribute [r] delayed
        # @return [true,false] True if the bus is considered to be delayed. Only defined when augmented with an API response.
        attr_reader :delayed
        # @!attribute [r] speed
        # @return [Integer] Last reported speed of the bus, in mph. Only defined when augmented with an API response.
        attr_reader :speed
        # @!attribute [r] speed
        # @return [Array<Prediction>] Predictions for this bus. Only defined when augmented with an API response.
        attr_reader :predictions
      end

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

    class Prediction
      attr_reader :type, :stop, :distance, :route, :direction, :destination,
                  :prediction_generated_at, :arrival_time, :delayed, :minutes, :seconds

      def initialize(data)
        @type = data["typ"]
        @stop = CTA::Stop.where(:stop_id => data["stpid"]).first || CTA::Stop.new_from_api_response(data)
        @distance = data["dstp"].to_i
        @route = CTA::Route.where(:route_id => data["rt"]).first
        @direction = CTA::BusTracker::Direction.new(data["rtdir"])
        @destination = data["des"]
        @prediction_generated_at = DateTime.parse(data["tmstmp"])
        @arrival_time = DateTime.parse(data["prdtm"])
        @seconds = @arrival_time.to_time - @prediction_generated_at.to_time
        @minutes = (@seconds / 60).ceil
        @delayed = (data["dly"] == "true")
      end
    end
  end
end
