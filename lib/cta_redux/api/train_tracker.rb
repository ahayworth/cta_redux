require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class TrainTracker

    ROUTES = {
      "red"   => { :name => "Red",
                   :directions => { "1" => "Howard-bound", "5" => "95th/Dan Ryan-bound" }
      },
      "blue"  => { :name => "Blue",
                   :directions => { "1" => "O'Hare-bound", "5" => "Forest Park-bound" }
      },
      "brn"   => { :name => "Brown",
                   :directions => { "1" => "Kimball-bound", "5" => "Loop-bound" }
      },
      "g"     => { :name => "Green",
                   :directions => { "1" => "Harlem/Lake-bound", "5" => "Ashland/63rd- or Cottage Grove-bound (toward 63rd St destinations)" }
      },
      "org"   => { :name => "Orange",
                   :directions => { "1" => "Loop-bound", "5" => "Midway-bound" }
      },
      "p"     => { :name => "Purple",
                   :directions => { "1" => "Linden-bound", "5" => "Howard- or Loop-bound" }
      },
      "pink"  => { :name => "Pink",
                   :directions => { "1" => "Loop-bound", "5" => "54th/Cermak-bound" }
      },
      "y"     => { :name => "Yellow",
                   :directions => { "1" => "Skokie-bound", "5" => "Howard-bound" }
      },
    }

    FRIENDLY_ROUTES = Hash[ROUTES.values.map { |r| r[:name].downcase.to_sym }.zip(ROUTES.keys)]

    class ArrivalsResponse < CTA::API::Response
      attr_reader :arrivals

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @arrivals = Array.wrap(parsed_body["ctatt"]["eta"]).map { |e| ETA.new(e) }
      end
    end

    class FollowResponse < CTA::API::Response
      attr_reader :position
      attr_reader :arrivals

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @position = Position.new(parsed_body["ctatt"]["position"])
        @arrivals = parsed_body["ctatt"]["eta"].map { |e| ETA.new(e) }
      end
    end

    class PositionsResponse < CTA::API::Response
      attr_reader :routes

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @routes = Array.wrap(parsed_body["ctatt"]["route"]).map { |r| Route.new(r["name"], r["train"]) }
      end
    end

    class Route
      attr_reader :trains
      attr_reader :name

      def initialize(name, trains)
        @name = ROUTES[name][:name]
        @trains = Array.wrap(trains).map { |t| Train.new(t, ROUTES[name]) }
      end

      def status!
        CTA::CustomerAlerts.status!(:route => self.name).routes.first
      end

      def alerts!
        CTA::CustomerAlerts.alerts!(:route => self.name).alerts
      end
    end

    class Train
      include Comparable
      FIELDS = [:run, :destination_station, :destination_name, :train_direction, :direction,
                :next_station_id, :next_stop_id, :next_station_name, :prediction_generated,
                :arrival_time, :minutes, :seconds, :is_approaching, :approaching, :is_delayed,
                :delayed, :flags, :lat, :latitude, :lon, :longitude, :heading, :route]

      FIELDS.each { |f| attr_reader f }

      def initialize(train, route)
        @run = train["rn"].to_i
        @route = route[:name]
        @destination_station = train["destSt"].to_i
        @destination_name = train["destNm"]
        @train_direction = @direction = route[:directions][train["trDr"]]
        @next_station_id = train["nextStaId"].to_i
        @next_stop_id = train["nextStpId"].to_i
        @next_station_name = train["nextStaNm"]
        @prediction_generated = DateTime.parse(train["prdt"])
        @arrival_time = DateTime.parse(train["arrT"])
        @seconds = @arrival_time.to_time - @prediction_generated.to_time
        @minutes = (@seconds / 60).ceil
        @is_approaching = @approaching = (train["isApp"] == "1")
        @is_delayed = @delayed = (train["isDly"] == "1")
        @flags = train["flags"]
        @lat = @latitude = train["lat"].to_f
        @lon = @longitude = train["lon"].to_f
        @heading = train["heading"].to_i
      end

      ["approaching?", "delayed?"].each do |m|
        define_method(m.to_sym) { self.instance_variable_get("@#{m.sub('?', '')}") }
      end

      def due?
        approaching?
      end

      def follow!
        CTA::TrainTracker.follow!(:run => self.run)
      end

      def <=>(other)
        self.arrival_time <=> other.arrival_time
      end
    end

    class ETA
      include Comparable

      FIELDS = [:station_id, :stop_id, :station_name, :stop_description, :run,
                :route, :destination_station, :destination_name, :train_direction, :direction,
                :prediction_generated, :arrival_time, :minutes, :seconds, :is_approaching,
                :is_scheduled, :is_fault, :is_delayed, :approaching, :scheduled, :fault,
                :delayed, :flags, :lat, :latitude, :lon, :longitude, :heading]

      FIELDS.each { |f| attr_reader f }

      def initialize(eta)
        rt = eta["rt"].split(/\s+/).first.downcase
        @station_id = eta["staId"].to_i
        @stop_id = eta["stpId"].to_i
        @station_name = eta["staNm"]
        @stop_description = eta["stpDe"]
        @run = eta["rn"].to_i
        @route = ROUTES[rt][:name]
        @destination_station = eta["destSt"].to_i
        @destination_name = eta["destNm"]
        @train_direction = @direction = ROUTES[rt][:directions][eta["trDr"]]
        @prediction_generated = DateTime.parse(eta["prdt"])
        @arrival_time = DateTime.parse(eta["arrT"])
        @seconds = @arrival_time.to_time - @prediction_generated.to_time
        @minutes = (@seconds / 60).ceil
        @is_approaching = @approaching = (eta["isApp"] == "1")
        @is_scheduled = @scheduled = (eta["isSch"] == "1")
        @is_fault = @fault = (eta["isFlt"] == "1")
        @is_delayed = @delayed = (eta["isDly"] == "1")
        @flags = eta["flags"]
        @lat = @latitude = eta["lat"].to_f
        @lon = @longitude = eta["lon"].to_f
        @heading = eta["heading"].to_i
      end

      ["approaching?", "scheduled?", "fault?", "delayed?"].each do |m|
        define_method(m.to_sym) { self.instance_variable_get("@#{m.sub('?', '')}") }
      end

      def due?
        approaching?
      end

      def <=>(other)
        self.arrival_time <=> other.arrival_time
      end
    end

    class Position
      FIELDS = [:lat, :latitude, :lon, :longitude, :heading]
      FIELDS.each { |f| attr_reader f }

      def initialize(position)
        @lat = @latitude = position["lat"]
        @long = @longitude = position["lon"]
        @heading = position["heading"]
      end
    end

  end
end
