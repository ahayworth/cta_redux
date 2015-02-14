require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class BusTracker

    class VehiclesResponse < CTA::API::Response
      attr_reader :vehicles

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @vehicles = Array.wrap(parsed_body["bustime_response"]["vehicle"]).map do |v|
          bus = CTA::Bus.find_active_run(v["rt"], v["tmstmp"], (v["dly"] == "true")).first
          bus.live!(v)

          bus
        end
      end
    end

    class TimeResponse < CTA::API::Response
      attr_reader :timestamp

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @timestamp = DateTime.parse(parsed_body["bustime_response"]["tm"])
      end
    end

    class RoutesResponse < CTA::API::Response
      attr_reader :routes

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @routes = Array.wrap(parsed_body["bustime_response"]["route"]).map do |r|
          puts r.inspect
          rt = CTA::Route.where(:route_id => r["rt"]).first
          rt.route_color = r["rtclr"]

          r
        end
      end
    end

    class DirectionsResponse < CTA::API::Response
      attr_reader :directions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @directions = Array.wrap(parsed_body["bustime_response"]["dir"]).map { |d| Direction.new(d) }
      end
    end

    class StopsResponse < CTA::API::Response
      attr_reader :stops

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @stops = Array.wrap(parsed_body["bustime_response"]["stop"]).map do |s|
          CTA::Stop.where(:stop_id => s["stpid"]).first || CTA::Stop.new_from_api_response(s)
        end
      end
    end

    class PatternsResponse < CTA::API::Response
      attr_reader :patterns

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @patterns = Array.wrap(parsed_body["bustime_response"]["ptr"]).map { |p| Pattern.new(p) }
      end
    end

    class PredictionsResponse < CTA::API::Response
      attr_reader :vehicles
      attr_reader :predictions

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @vehicles = Array.wrap(parsed_body["bustime_response"]["prd"]).map do |p|
          bus = CTA::Bus.find_active_run(p["rt"], p["tmstmp"], (p["dly"] == "true")).first
          bus.live!(p, p)

          bus
        end
        @predictions = @vehicles.map(&:predictions).flatten
      end
    end

    class ServiceBulletinsResponse < CTA::API::Response
      attr_reader :bulletins

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @bulletins = Array.wrap(parsed_body["bustime_response"]["sb"]).map { |sb| ServiceBulletin.new(sb) }
      end
    end

    class ServiceBulletin
      attr_reader :name, :subject, :details, :brief, :priority, :affected_services

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
      attr_reader :route
      attr_reader :direction
      attr_reader :stop
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

    class Pattern
      attr_reader :id
      attr_reader :pattern_id
      attr_reader :length
      attr_reader :direction
      attr_reader :points

      def initialize(p)
        @id = @pattern_id = p["pid"].to_i
        @length = p["ln"].to_f
        @direction = Direction.new(p["rtdir"])

        @points = Array.wrap(p["pt"]).map { |pnt| Point.new(pnt) }
      end
    end

    class Point
      attr_reader :sequence, :lat, :lon, :latitude, :longitude, :type, :stop, :distance

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
      attr_reader :direction

      def initialize(d)
        @direction = d
      end
    end
  end
end
