module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#routes_txt___Field_Definitions routes.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :route_short_name, :route_long_name, :route_type, :route_url, :route_color, :route_text_color]
  class Route < Sequel::Model
    # @return [Live] the {Live} data associated with this {CTA::Route}, if available.
    # @note a {CTA::Route} will only contain live data when augmented with an {API::Response}
    attr_accessor :live
    set_primary_key :route_id

    # @!method trips
    #   A {CTA::Route} may be associated with multiple trips ("runs").
    #   @return [Array<CTA::Trip>] All trips associated with this route
    one_to_many :trips, :key => :route_id

    # Overrides the default "find by primary key" method in {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
    # Allows you to specify a human-friendly {CTA::Train} name. If you supply something that doesn't look like an "L" route, it's passed
    # to the default [] method on Sequel::Model.
    # @return [CTA::Route] The route requested
    # @example
    #   CTA::Route[:brown] #=> equivalent to calling CTA::Route["Brn"]
    #   CTA::Route["Brown"] #=> equivalent to calling CTA::Route["Brn"]
    #   CTA::Route["8"] #=> equivalent to calling CTA::Route["8"]
    def self.[](*args)
      potential_route = args.first.downcase.to_sym
      if CTA::Train::FRIENDLY_L_ROUTES.has_key?(potential_route)
        super(Array.wrap(CTA::Train::FRIENDLY_L_ROUTES[potential_route].capitalize))
      else
        super(args)
      end
    end

    # Returns a {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html Sequel::Dataset} that corresponds to stops associated
    # with this {CTA::Route}
    # @return [Sequel::Dataset]
    # @example
    #   CTA::Route["brown"].stops.first #=> #<CTA::Stop...
    #   CTA::Route["brown"].stops.all   #=> [#<CTA::Stop..., #<CTA::Stop...]
    def stops
      CTA::Stop.with_sql(<<-SQL)
        SELECT s.*
        FROM stops s
        WHERE s.stop_id IN (
          SELECT DISTINCT st.stop_id
          FROM stop_times st
            JOIN trips t ON st.trip_id = t.trip_id
          WHERE t.route_id = '#{self.route_id}'
        )
      SQL
    end

    # Returns predictions for this specific {CTA::Route}. Accepts all optiosn of either
    # {CTA::BusTracker.predictions!} or {CTA::TrainTracker.predictions!}, depending on the type of this {CTA::Route}
    # @return [CTA::BusTracker::PredictionsResponse, CTA::TrainTracker::ArrivalsResponse]
    def predictions!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.predictions!(options.merge({:route => self.route_id.downcase}))
      else
        CTA::BusTracker.predictions!(options.merge({:route => self.route_id}))
      end
    end

    # Returns the position and next station of all trains in service for this route.
    # @note Raises an exception when called on a {CTA::Bus} route, because the BusTracker API has nothing like the
    #  TrainTracker locations call
    # @param [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes for which to return positions
    # @return [CTA::TrainTracker::LocationsResponse]
    # @example
    #    locations!(:route => [:red, :blue])
    def locations!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.locations!(options.merge({:routes => self.route_id.downcase}))
      else
        raise "CTA BusTracker has no direct analog of the TrainTracker locations api. Try predictions instead."
      end
    end

    # Returns an overview of system status for this route
    # @return [CTA::CustomerAlerts::RouteStatusResponse]
    def status!
      CTA::CustomerAlerts.status!(:routes => self.route_id).routes.first
    end

    # Returns alerts for this route
    # @return [CTA::CustomerAlerts::AlertsResponse]
    def alerts!
      CTA::CustomerAlerts.alerts!(:route => self.route_id).alerts
    end

    class Live
      # @return [Array<CTA::Bus>, Array<CTA::Train>] The live vehicles associated with this route
      attr_reader :vehicles

      def initialize(vehicles)
        @vehicles = vehicles
      end
    end
  end
end
