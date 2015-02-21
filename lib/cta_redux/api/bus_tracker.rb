require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class BusTracker

    class VehiclesResponse < CTA::API::Response
      # @return [Array<CTA::Bus>] An array with a full {CTA::Bus} object for each vehicle returned in the API, augmented
      #  with live details
      attr_reader :vehicles

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @vehicles = Array.wrap(parsed_body["bustime_response"]["vehicle"]).map do |v|
          bus = CTA::Bus.find_active_run(v["rt"], v["tmstmp"], (v["dly"] == "true"), v["rtdir"]).first
          bus.live = CTA::Bus::Live.new(v)

          bus
        end
      end
    end

    class TimeResponse < CTA::API::Response
      # @return [DateTime] Current time according to the BusTime servers which power the BusTracker API
      attr_reader :timestamp

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @timestamp = DateTime.parse(parsed_body["bustime_response"]["tm"])
      end
    end

    class RoutesResponse < CTA::API::Response
      # @return [Array<CTA::Route>] An array with a full {CTA::Route} object for each route returned by the API,
      #  augmented with the color that the API thinks you should be using (which is not always found in the GTFS data).
      attr_reader :routes

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @routes = Array.wrap(parsed_body["bustime_response"]["route"]).map do |r|
          rt = CTA::Route.where(:route_id => r["rt"]).first
          rt.route_color = r["rtclr"]

          rt
        end
      end
    end

    class DirectionsResponse < CTA::API::Response
      # @return [Array<Direction>] An array of {Direction} that the requested route operates.
      attr_reader :directions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @directions = Array.wrap(parsed_body["bustime_response"]["dir"]).map { |d| Direction.new(d) }
      end
    end

    class StopsResponse < CTA::API::Response
      # @return [Array<CTA::Stop>] An array with full {CTA::Stop} objects that correspond to the stops returned from the API.
      # @note Some stops returned from BusTracker are not found in GTFS data, so cta_redux creates them on the fly. These
      #  stops are for seasonal routes. An email has been sent to the CTA asking why they're not included in the GTFS data (they should be).
      attr_reader :stops

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @stops = Array.wrap(parsed_body["bustime_response"]["stop"]).map do |s|
          CTA::Stop.where(:stop_id => s["stpid"]).first || CTA::Stop.new_from_api_response(s)
        end
      end
    end

    class PatternsResponse < CTA::API::Response
      # @return [Array<Pattern>] An array of {Pattern} objects for the requested query.
      attr_reader :patterns

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @patterns = Array.wrap(parsed_body["bustime_response"]["ptr"]).map { |p| Pattern.new(p) }
      end
    end

    class PredictionsResponse < CTA::API::Response
      # @return [Array<CTA::Bus>] An array of {CTA::Bus} objects that correspond to the predictions requested.
      attr_reader :vehicles
      # @return [Array<CTA::Bus::Prediction>] An array of {CTA::Bus::Prediction} objects that correspond to the predictions requested.
      #  This is equivalent to calling +vehicles.map { |b| b.live.predictions }.flatten+
      attr_reader :predictions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @vehicles = Array.wrap(parsed_body["bustime_response"]["prd"]).map do |p|
          bus = CTA::Bus.find_active_run(p["rt"], p["tmstmp"], (p["dly"] == "true"), p["rtdir"]).first
          bus.live = CTA::Bus::Live.new(p, p)

          bus
        end
        @predictions = @vehicles.map { |b| b.live.predictions }.flatten
      end
    end

    class ServiceBulletinsResponse < CTA::API::Response
      # @return [Array<ServiceBulletin>] An array of {ServiceBulletin} objects that correspond to the query requested.
      # @note Consider using the {CTA::CustomerAlerts} methods to search for alerts, as theoretically they should have the same
      #  data and it is not a rate-limited API.
      attr_reader :bulletins

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @bulletins = Array.wrap(parsed_body["bustime_response"]["sb"]).map { |sb| ServiceBulletin.new(sb) }
      end
    end

    class ServiceBulletin
      # @return [String] The name of the bulletin.
      attr_reader :name
      # @return [String] A short description of the bulletin.
      attr_reader :subject
      # @return [String] More details about the bulletin
      attr_reader :details
      # @return [String] Another short description of the bulletin
      # @note This seems to usually be unset by the CTA.
      attr_reader :brief
      # @return [Symbol] Priority of the alert. One of +[:low, :medium, :high]+
      attr_reader :priority
      # @return [Array<Service>] An array of {Service} objects that encapsulate information (if any) about which routes and stops are affected by this bulletin.
      attr_reader :affected_services

      def initialize(sb)
        @name = sb["nm"]
        @subject = sb["sbj"]
        @details = sb["dtl"]
        @brief = sb["brf"]
        @priority = sb["prty"].downcase.to_sym

        @affected_services = Array.wrap(sb["srvc"]).map { |svc| Service.new(svc) }
      end
    end

    class Service
      # @return [CTA::Route] A {CTA::Route}, if any, affected by a {ServiceBulletin}
      attr_reader :route
      # @return [Direction] A {Direction} object for the direction, if any, affected by a {ServiceBulletin}
      attr_reader :direction
      # @return [CTA::Stop] A specific {CTA::Stop} object for the stop affected by a {ServiceBulletin}
      attr_reader :stop

      # @return [String] The name of the {CTA::Stop} affected.
      # @note Usually this is equivalent to calling +stop.name+, but sometimes the CTA returns a {ServiceBulletin} with a stop name,
      #  but no stop id set - and the stop name may not exactly correspond to a {CTA::Stop} object in the GTFS feed.
      attr_reader :stop_name

      def initialize(s)
        @route = CTA::Route.where(:route_id => s["rt"]).first
        @direction = Direction.new(s["rtdir"]) if s["rtdir"]
        if s["stpid"]
          @stop = CTA::Stop.where(:stop_id => s["stpid"]).first || CTA::Stop.new_from_api_response(s)
          @stop_name = @stop.name
        else
          @stop_name = s["stpnm"] # ugh
        end
      end

      def predictions!
        options = { :route => self.route }
        options.merge!({ :stop => self.stop_id }) if self.stop_id
        CTA::BusTracker.predictions!(options)
      end
    end

    # @note {Pattern} objects enclose {Point} objects that describe a bus route. Conceptually it is similar to how a {CTA::Trip} contains
    #  many {CTA::StopTime} objects that describe the route a vehicle takes. However, it is specific to busses and contains better information
    #  for drawing turns and side-streets that the bus may take on its route. This bit of the API is mostly unnecessary unless you're drawing
    #  maps.
    class Pattern
      # @return [Integer] The ID of the pattern
      attr_reader :id
      # @return [Integer] The ID of the pattern
      attr_reader :pattern_id
      # @return [Integer] The total length of the pattern
      attr_reader :length
      # @return [Direction] A {Direction} object that describes to which direction of a route this pattern applies.
      # @note This logically means that any given bus route (so long as it's not a circulator or one-way express) will have
      #  two associated {Pattern} objects
      attr_reader :direction
      # @return [Array<Point>] An array of {Point} objects that describe stops and waypoints along the {Pattern}
      attr_reader :points

      def initialize(p)
        @id = @pattern_id = p["pid"].to_i
        @length = p["ln"].to_f
        @direction = Direction.new(p["rtdir"])

        @points = Array.wrap(p["pt"]).map { |pnt| Point.new(pnt) }
      end
    end

    class Point
      # @return [Integer] The order that this {Point} appears along a {Pattern}
      attr_reader :sequence
      # @return [Float] The latitude of this {Point}
      attr_reader :lat
      # @return [Float] The longitude of this {Point}
      attr_reader :lon
      # @return [Float] The latitude of this {Point}
      attr_reader :latitude
      # @return [Float] The longitude of this {Point}
      attr_reader :longitude
      # @return [Symbol] The type of this {Point}. One of +[:stop, :waypoint]+
      attr_reader :type
      # @return [CTA::Stop] The {CTA::Stop} associated with this point.
      attr_reader :stop
      # @return [Float] The physical distance into a {Pattern} that corresponds to this {Point}
      attr_reader :distance

      def initialize(p)
        @sequence = p["seq"].to_i
        @lat = @latitude = p["lat"].to_f
        @lon = @longitude = p["lon"].to_f
        @type = (p["typ"] == "S" ? :stop : :waypoint)
        @stop = CTA::Stop.where(:stop_id => p["stpid"]).first || CTA::Stop.new_from_api_response(p)
        @distance = p["pdist"].to_f if p["pdist"]
      end

      def <=>(other)
        self.sequence <=> other.sequence
      end
    end

    class Direction
      # @return [String] A direction for a service.
      # @note The raw BusTracker API expects directions in the exact format this object returns. This is mostly an implementation detail, but
      #  explains a bit about why this object even exists.
      attr_reader :direction

      def initialize(d)
        @direction = d
      end
    end
  end
end
