require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class BusTracker

    class VehiclesResponse < CTA::API::Response
      attr_reader :vehicles

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @vehicles = Array.wrap(parsed_body["bustime_response"]["vehicle"]).map do |v|
          bus = CTA::Bus.find_active_run(v["rt"], v["tmstmp"], (v["dly"] == "true")).first
          bus.live!(v)

          bus
        end
      end
    end

    class TimeResponse < CTA::API::Response
      attr_reader :timestamp

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @timestamp = DateTime.parse(parsed_body["bustime_response"]["tm"])
      end
    end

    class RoutesResponse < CTA::API::Response
      attr_reader :routes

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @routes = Array.wrap(parsed_body["bustime_response"]["route"]).map { |r| Route.new(r) }
      end
    end

    class DirectionsResponse < CTA::API::Response
      attr_reader :directions

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @directions = Array.wrap(parsed_body["bustime_response"]["dir"]).map { |d| Direction.new(d) }
      end
    end

    class StopsResponse < CTA::API::Response
      attr_reader :stops

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @stops = Array.wrap(parsed_body["bustime_response"]["stop"]).map { |s| Stop.new(s) }
      end
    end

    class PatternsResponse < CTA::API::Response
      attr_reader :patterns

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @patterns = Array.wrap(parsed_body["bustime_response"]["ptr"]).map { |p| Pattern.new(p) }
      end
    end

    class PredictionsResponse < CTA::API::Response
      attr_reader :predictions

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @predictions = Array.wrap(parsed_body["bustime_response"]["prd"]).map { |p| Prediction.new(p) }
      end
    end

    class ServiceBulletinsResponse < CTA::API::Response
      attr_reader :bulletins

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @bulletins = Array.wrap(parsed_body["bustime_response"]["sb"]).map { |sb| ServiceBulletin.new(sb) }
      end
    end

    class ServiceBulletin
      FIELDS = [:name, :subject, :details, :brief, :priority, :affected_services]
      FIELDS.each { |f| attr_reader f }

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
      attr_reader :stop_id
      attr_reader :stop_name

      def initialize(s)
        @route = s["rt"]
        @direction = Direction.new(s["rtdir"]) if s["rtdir"]
        @stop_id = s["stpid"].to_i if s["stpid"]
        @stop_name = s["stpnm"]
      end

      def predictions!
        options = { :route => self.route }
        options.merge!({ :stop => self.stop_id }) if self.stop_id
        CTA::BusTracker.predictions!(options)
      end
    end

    class Prediction
      include Comparable

      FIELDS = [:timestamp, :type, :stop_name, :stop_id, :vehicle_id, :distance, :route, :direction,
                :destination, :prediction_time, :is_delayed, :delayed, :tablockid, :tatripid, :prdctdn,
                :zone, :minutes, :seconds]

      FIELDS.each { |f| attr_reader f }

      def initialize(p)
        @timestamp = DateTime.parse(p["tmstmp"])
        @type = (p["typ"] == "D" ? :departure : :arrival)
        @stop_name = p["stpnm"]
        @stop_id = p["stpid"].to_i
        @vehicle_id = p["vid"].to_i
        @distance = p["dstp"].to_i
        @route = p["rt"]
        @direction = Direction.new(p["rtdir"])
        @destination = p["des"]
        @prediction_time = DateTime.parse(p["prdtm"])
        @seconds = @prediction_time.to_time - @timestamp.to_time
        @minutes = (@seconds / 60).ceil
        @is_delayed = @delayed = (p["dly"] == "true")
        @tablockid = p["tablockid"].to_i
        @tatripid = p["tatripid"].to_i
        @prdctdn = p["prdctdn"].to_i
        @zone = p["zone"]
      end

      def delay?
        @delayed
      end

      def <=>(other)
        self.prediction_time <=> other.prediction_time
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
      include Comparable

      FIELDS = [:sequence, :lat, :lon, :latitude, :longitude, :type, :stop_id, :stop_name, :distance]
      FIELDS.each { |f| attr_reader f }

      def initialize(p)
        @sequence = p["seq"].to_i
        @lat = @latitude = p["lat"].to_f
        @lon = @longitude = p["lon"].to_f
        @type = (p["typ"] == "S" ? :stop : :waypoint)
        @stop_id = p["stpid"].to_i if p["stpid"]
        @stop_name = p["stpnm"]
        @distance = p["pdist"].to_f if p["pdist"]
      end

      def <=>(other)
        self.sequence <=> other.sequence
      end
    end

    class Stop
      FIELDS = [:stop_id, :id, :stop_name, :name, :lat, :lon, :latitude, :longitude]
      FIELDS.each { |f| attr_reader f }

      def initialize(stop)
        @stop_id = @id = stop["stpid"].to_i
        @stop_name = @name = stop["stpnm"]
        @lat = @latitude = stop["lat"].to_f
        @lon = @longitude = stop["lon"].to_f
      end

      def predictions!
        CTA::BusTracker.predictions!(:stop => self.id)
      end
    end

    class Direction
      attr_reader :direction

      def initialize(d)
        @direction = d
      end
    end

    class Route
      attr_reader :route
      attr_reader :name
      attr_reader :color

      def initialize(route)
        @route = route["rt"]
        @name = route["rtnm"]
        @color = route["rtclr"]
      end
    end

    class Vehicle
      FIELDS = [:vehicle_id, :id, :timestamp, :lat, :latitude, :lon, :longitude,
                :heading, :pattern_id, :pattern_distance, :route, :is_delayed, :delayed,
                :speed, :tablockid, :tatripid, :zone ]

      FIELDS.each { |f| attr_reader f }

      def initialize(v)
        @vehicle_id = @id = v["vid"].to_i
        @timestamp = DateTime.parse(v["tmstmp"])
        @lat = @latitude = v["lat"].to_f
        @lon = @longitude = v["lon"].to_f
        @heading = v["hdg"].to_i
        @pattern_id = v["pid"].to_i
        @pattern_distance = v["pdist"].to_i
        @route = v["rt"]
        @is_delayed = @delayed = (v["dly"] == "true")
        @speed = v["spd"].to_i
        @tablockid = v["tablockid"]
        @tatripid = v["tatripid"]
        @zone = v["zone"]
      end

      def delayed?
        @delayed
      end

      def predictions!
        CTA::BusTracker.predictions!(:vehicle => self.id)
      end
    end
  end
end
