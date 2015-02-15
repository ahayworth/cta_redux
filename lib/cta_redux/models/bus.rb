module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}, inherited from {CTA::Trip}
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Bus < CTA::Trip
    # @return [Live] the {Live} data associated with this {CTA::Bus}, if available.
    # @note a {CTA::Bus} will only contain live data when augmented with an {API::Response}
    attr_accessor :live

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
