module CTA
  class Bus < CTA::Trip
    def predictions!(options = {})
      opts = (self.vehicle_id ? { :vehicles => self.vehicle_id } : { :routes => self.route_id })
      puts opts
      CTA::BusTracker.predictions!(options.merge(opts))
    end

    def live!(position, predictions = [])
      class << self
        attr_reader :lat, :lon, :vehicle_id, :heading, :pattern_id, :pattern_distance, :route, :delayed, :speed, :predictions
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
