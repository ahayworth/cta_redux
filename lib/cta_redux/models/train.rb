module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}, inherited from {CTA::Trip}
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Train < CTA::Trip
    # @return [Live] Returns the {Live} data associated with this {CTA::Train} object, if available.
    # @note a {CTA::Train} will only contain live data when augmented with an {API::Response}
    attr_accessor :live

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

    ANNOYING_GREEN_RUNS = CTA::DB[:stop_times].with_sql(<<-SQL).select_map(:schd_trip_id)
      SELECT DISTINCT t.schd_trip_id
      FROM stop_times st
        JOIN trips t ON st.trip_id = t.trip_id
      WHERE t.route_id = 'G'
        AND st.stop_headsign = ''
    SQL

    HEADSIGNS = {
      "54th/Cermak"   => "54 / Cermak",
      "Ashland/63rd"  => "Ashland / 63",
      "UIC-Halsted"   => "UIC",
      "Harlem/Lake"   => "Harlem",
      "95th/Dan Ryan" => "95th",
    }

    # @!method route_id
    #  @return [String]
    # @!method service_id
    #  @return [Integer]
    # @!method trip_id
    #  @return [Integer]
    # @!method direction_id
    #  @return [Integer]
    # @!method block_id
    #  @return [Integer]
    # @!method shape_id
    #  @return [Integer]
    # @!method direction
    #  @return [String]
    # @!method wheelchair_accessible
    #  @return [true,false]
    # @!method schd_trip_id
    #  @return [String]
    alias_method :id, :route_id
    alias_method :scheduled_trip_id, :schd_trip_id
    alias_method :run, :schd_trip_id

    # Find a {CTA::Trip} that should be happening, given a timestamp and a route or run.
    # The CTA does not return GTFS trip_id information in either the BusTracker or TrainTracker API, so
    # it is actually somewhat difficult to associate an API response to a {CTA::Trip}. However, we
    # know what *should* be happening at any given time. This method attempts a fuzzy find - internally,
    # we often first try to find the exact Trip that should be happening according to the schedule, and
    # then failing that we assume that the CTA is running late and look for trips that should have
    # ended within the past 90 minutes. This almost always finds something.
    # That said, however, it means we may sometimes find a {CTA::Trip} that's incorrect. In practical usage
    # however, that doesn't matter too much - most Trips for a run service the same stops.
    # However, to be safe, your program may wish to compare certain other bits of the API responses to ensure
    # we found something valid. For example, almost all Brown line trains service the same stops, so
    # finding the wrong Trip doesn't matter too much. However, a handful of Brown line runs throughout the dat
    # actually change to Orange line trains at Midway - so, you may wish to verify that the destination of the
    # Trip matches the reported destination of the API.
    # Suggestions on how to approach this problem are most welcome (as are patches for better behavior).
    # @param [String] run The run or route to search for
    # @param [DateTime, String] timestamp The timestamp to search against.
    # @param [true,false] fuzz Whether or not to do an exact schedule search or a fuzzy search.
    # @param [String] direction The stop headsign. Highly recommended to use because otherwise results may be inaccurate.
    def self.find_active_run(run, timestamp, fuzz = false, direction = nil)
      # The TrainTracker API sets the stop_headsign to 'Cottage Grove' but GTFS has it as blank...
      if run == "516"
        puts run
        puts timestamp.to_s
        puts fuzz.inspect
        puts direction
      end
      if ANNOYING_GREEN_RUNS.any? { |r| r =~ /#{run}/ } && false
        direction_str = <<-EOF
          AND (st.stop_headsign = '#{(HEADSIGNS[direction] || direction).gsub("'", "''")}'
            OR (t.route_id = 'G' AND st.stop_headsign = ''))
        EOF
      elsif direction
        direction_str = "AND st.stop_headsign = '#{(HEADSIGNS[direction] || direction).gsub("'", "''")}'"
      else
        direction_str = ''
      end
      d = timestamp.is_a?(DateTime) ? timestamp : DateTime.parse(timestamp)
      wday = d.strftime("%A").downcase
      end_ts = (fuzz ? (d.to_time + (60 * 60 * 6) - (90 * 60)) : d).strftime("%H:%M:%S")
      Trip.with_sql(<<-SQL)
        SELECT t.*
        FROM trips t
          JOIN stop_times st ON t.trip_id = st.trip_id
          JOIN calendar   c  ON t.service_id = c.service_id
        WHERE t.schd_trip_id = 'R#{run}'
          #{direction_str}
          AND c.start_date <= '#{d.to_s}'
          AND c.end_date   >= '#{d.to_s}'
          AND c.#{wday}
        GROUP BY t.trip_id
        HAVING MAX(st.departure_time) >= '#{end_ts}'
        ORDER BY st.departure_time ASC
      SQL
    end

    # Follows a train, using the TrainTracker follow API
    # @return [CTA::TrainTracker::FollowResponse] A {CTA::TrainTracker::FollowResponse} with predictions for this train
    def follow!
      CTA::TrainTracker.follow!(:run => self.schd_trip_id.gsub("R", ""))
    end

    class Live
      # @return [Float] The current latitude of the train
      attr_reader :lat
      # @return [Float] The current longitude of the train
      attr_reader :lon
      # @return [Integer] The current heading of the train
      attr_reader :heading
      # @return [Array<Prediction>] An array of {Prediction} objects that correspond to predictions returned from the TrainTracker API
      attr_reader :predictions

      def initialize(position, predictions)
        @lat = position["lat"].to_f
        @lon = position["lon"].to_f
        @heading = position["heading"].to_i
        @predictions = Array.wrap(predictions).map { |p| Prediction.new(p) }
      end
    end

    class Prediction
      # @return [String] The run identifier for this train.
      # @note This is returned as a string, because the API will return results like "004" and the leading zeroes are important.
      attr_reader :run
      # @return [CTA::Trip] The {CTA::Trip} associated with this train
      attr_reader :trip
      # @return [CTA::Stop] The final {CTA::Stop} of this train
      attr_reader :destination
      # @return [String] A human-readable direction of this train, eg "O'Hare-bound"
      attr_reader :direction
      # @return [CTA::Stop] The next parent {CTA::Stop} of this train
      attr_reader :next_station
      # @return [CTA::Stop] The next {CTA::Stop} of this train
      attr_reader :next_stop
      # @return [DateTime] The time this {Prediction} was generated on the TrainTracker servers
      attr_reader :prediction_generated_at
      # @return [DateTime] The time this train is predicted to arrive at the next_station
      attr_reader :arrival_time
      # @return [Integer] The number of minutes until this train arrives at the next_station
      attr_reader :minutes
      # @return [Integer] The number of seconds until this train arrives at the next_station
      attr_reader :seconds
      # @return [true,false] True if this train is considered to be 'approaching' the next_station by the CTA
      attr_reader :approaching
      # @return [true,false] True if this train has not yet left it's origin station and started it's run
      attr_reader :scheduled
      # @return [true,false] True if this train is considered to be 'delayed' by the CTA
      # @note The CTA considers a train 'delayed' if it's not progressing along the tracks. This is *not* an indication
      #   that a predicted arrival time will be later than a scheduled arrival time (which is how most people would consider a train
      #   to be 'delayed'). The CTA recommends that you indicate a train is 'delayed' rather than continuing to display the last predicted
      #   arrival time, which may no longer be accurate.
      attr_reader :delayed
      # @return [String] Flags for this train. Unused at this time.
      attr_reader :flags
      # @return [CTA::Route] The {CTA::Route} this train is running.
      attr_reader :route

      def initialize(data)
        @run = data["rn"]
        @trip = CTA::Trip.where(:schd_trip_id => "R#{@run}").first
        @destination = CTA::Stop.where(:stop_id => data["destSt"]).first
        @next_station = CTA::Stop.where(:stop_id => (data["staId"] || data["nextStaId"])).first
        @next_stop = CTA::Stop.where(:stop_id => (data["stpId"] || data["nextStpId"])).first
        @prediction_generated_at = DateTime.parse(data["prdt"])
        @arrival_time = DateTime.parse(data["arrT"])
        @seconds = @arrival_time.to_time - @prediction_generated_at.to_time
        @minutes = (@seconds / 60).ceil
        @approaching = (data["isApp"] == "1")
        @delayed = (data["isDly"] == "1")
        @scheduled = (data["isSch"] == "1")
        @flags = data["flags"]
        @route = @trip.route
        @direction = L_ROUTES[@route.route_id.downcase][:directions][data["trDr"]]
      end
    end
  end
end
