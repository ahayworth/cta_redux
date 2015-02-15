module CTA
  class TrainTracker
    class ArrivalsResponse < CTA::API::Response
      # @return [Array<CTA::Route>] An array of {CTA::Route} objects that correspond to the predictions requested.
      attr_reader :routes
      # @return [Array<CTA::Train>] An array of {CTA::Train} objects that correspond to the predictions requested.
      # @note Convenience method, equivalent to calling +routes.map(&:vehicles).flatten+
      attr_reader :trains
      # @return [Array<CTA::Train::Prediction>] An array of {CTA::Train::Prediction} objects that correspond to the predictions requested.
      # @note Convenience method, equivalent to calling +routes.map(&:vehicles).flatten.map { |t| t.live.predictions }.flatten+
      attr_reader :predictions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)

        eta_map = Array.wrap(parsed_body["ctatt"]["eta"]).inject({}) do |h, eta|
          h[eta["rt"]] ||= []
          h[eta["rt"]] << eta

          h
        end

        @routes = eta_map.map do |rt, etas|
          trains = etas.map do |t|
            train = CTA::Train.find_active_run(t["rn"], self.timestamp, (t["isDly"] == "1")).first
            if !train
              train = CTA::Train.find_active_run(t["rn"], self.timestamp, true).first
            end
            position = t.select { |k,v| ["lat", "lon", "heading"].include?(k) }
            train.live = CTA::Train::Live.new(position, t)

            train
          end

          route = CTA::Route.where(:route_id => rt.capitalize).first
          route.live!(trains)

          route
        end

        @trains = @routes.map(&:vehicles).flatten
        @predictions = @trains.map { |t| t.live.predictions }.flatten
      end
    end

    class FollowResponse < CTA::API::Response
      # @return [CTA::Train] The {CTA::Train} that corresponds to the train for which you've requested follow predictions.
      attr_reader :train
      # @return [Array<CTA::Train::Prediction>] An array of {CTA::Train::Prediction} objects that correspond to the predictions requested.
      # @note Convenience method, equivalent to calling +train.map { |t| t.live.predictions }.flatten+
      attr_reader :predictions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)

        train_info = Array.wrap(parsed_body["ctatt"]["eta"]).first
        @train = CTA::Train.find_active_run(train_info["rn"], self.timestamp, (train_info["isDly"] == "1")).first
        if !@train
          @train = CTA::Train.find_active_run(train_info["rn"], self.timestamp, true).first
        end
        @train.live = CTA::Train::Live.new(parsed_body["ctatt"]["position"], parsed_body["ctatt"]["eta"])
        @predictions = @train.live.predictions
      end
    end

    class PositionsResponse < CTA::API::Response
      # @return [Array<CTA::Route>] An array of {CTA::Route} objects that correspond to the positions requested.
      attr_reader :routes
      # @return [Array<CTA::Train>] An array of {CTA::Train} objects that correspond to the positions requested.
      # @note Convenience method, equivalent to calling +routes.compact.map(&:vehicles).flatten+
      attr_reader :trains
      # @return [Array<CTA::Train::Prediction>] An array of {CTA::Train::Prediction} objects that correspond to the positions requested.
      # @note Convenience method, equivalent to calling +routes.compact.map(&:vehicles).flatten.map { |t| t.live.predictions }.flatten+
      attr_reader :predictions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @routes = Array.wrap(parsed_body["ctatt"]["route"]).map do |route|
          rt = Route.where(:route_id => route["name"].capitalize).first

          trains = Array.wrap(route["train"]).map do |train|
            t = CTA::Train.find_active_run(train["rn"], self.timestamp, (train["isDly"] == "1")).first
            if !t # Sometimes the CTA doesn't report things as delayed even when they ARE
              t = CTA::Train.find_active_run(train["rn"], self.timestamp, true).first
            end

            if !t
              puts "Couldn't find train #{train["rn"]} - this is likely a bug."
              next
            end

            position = train.select { |k,v| ["lat", "lon", "heading"].include?(k) }
            t.live = CTA::Train::Live.new(position, train)

            t
          end

          rt.live!(trains)
          rt
        end.compact

        @trains = @routes.compact.map(&:vehicles).flatten
        @predictions = @trains.compact.map { |t| t.live.predictions }.flatten
      end
    end
  end
end
