module CTA
  class Train < CTA::Trip
    L_ROUTES = {
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
    FRIENDLY_L_ROUTES = Hash[L_ROUTES.values.map { |r| r[:name].downcase.to_sym }.zip(L_ROUTES.keys)]

    # DRAGONS
    # The CTA doesn't exactly honor the GTFS spec (nor do they return GTFS trip_ids
    # in the TrainTracker API, grr). They specify multiple entries of
    # (schd_trip_id, block_id, service_id) - so the only way to know which
    # trip_id to pick is to join against stop_times and calendar dates, and
    # find out which run (according to stop_times) is happening *right now*.
    # Of course, this will break if the train is delayed more the total time
    # it takes to complete the run... so a delayed train will start to disappear
    # as it progresses through the run. We allow for a 'fuzz factor' to account
    # for this...
    def self.find_active_run(run, timestamp, fuzz = false)
      d = timestamp.is_a?(DateTime) ? timestamp : DateTime.parse(timestamp)
      wday = d.strftime("%A").downcase
      dstr = d.strftime("%Y%m%d")
      ts = (fuzz ? d.to_time - (30 * 60) : d).strftime("%H:%M:%S")
      Trip.with_sql(<<-SQL)
        SELECT t.*
        FROM trips t
          JOIN stop_times st ON t.trip_id = st.trip_id
          JOIN calendar   c  ON t.service_id = c.service_id
        WHERE t.schd_trip_id = 'R#{run}'
          AND CAST(c.start_date AS NUMERIC) <= #{dstr}
          AND CAST(c.end_date   AS NUMERIC) >= #{dstr}
          AND c.#{wday} = '1'
        GROUP BY t.trip_id
        HAVING MIN(st.departure_time) <= '#{ts}'
          AND  MAX(st.departure_time) >= '#{ts}'
      SQL
    end

    def follow!
      CTA::TrainTracker.follow!(:run => self.schd_trip_id.gsub("R", ""))
    end

    def live!(position, predictions)
      class << self
        attr_reader :lat, :lon, :heading, :predictions
      end

      @lat = position["lat"].to_f
      @lon = position["lon"].to_f
      @heading = position["heading"].to_i

      @predictions = Array.wrap(predictions).map { |p| Prediction.new(p) }
    end

    class Prediction
      attr_reader :run, :trip, :destination, :direction, :next_station,
                  :prediction_generated_at, :arrival_time, :minutes, :seconds,
                  :approaching, :scheduled, :delayed, :flags, :route

      def initialize(data)
        @run = data["rn"].to_i
        @trip = CTA::Trip.where(:schd_trip_id => "R#{@run}").first
        @destination = CTA::Stop.where(:stop_id => data["destSt"]).first
        @next_station = CTA::Stop.where(:stop_id => (data["staId"] || data["nextStaId"])).first
        @prediction_generated_at = DateTime.parse(data["prdt"])
        @arrival_time = DateTime.parse(data["arrT"])
        @seconds = @arrival_time.to_time - @prediction_generated_at.to_time
        @minutes = (@seconds / 60).ceil
        @approaching = (data["isApp"] == "1")
        @delayed = (data["isDly"] == "1")
        @scheduled = (data["isSch"] == "1")
        @flags = data["flags"]
        @lat = data["lat"].to_f
        @lon = data["lon"].to_f
        @heading = data["heading"].to_i
        @route = @trip.route
        @direction = L_ROUTES[@route.route_id.downcase][:directions][data["trDr"]]
      end
    end
  end
end
