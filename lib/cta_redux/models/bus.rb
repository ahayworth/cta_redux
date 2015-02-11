module CTA
  class Bus < CTA::Trip
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
        WHERE t.route_id = '#{run}'
          AND CAST(c.start_date AS NUMERIC) <= #{dstr}
          AND CAST(c.end_date   AS NUMERIC) >= #{dstr}
          AND c.#{wday} = '1'
        GROUP BY t.trip_id
        HAVING MIN(st.departure_time) <= '#{ts}'
          AND  MAX(st.departure_time) >= '#{ts}'
      SQL
    end

    def predictions!(options = {})
      opts = (self.vehicle_id ? { :vehicles => self.vehicle_id } : { :routes => self.route_id })
      puts opts
      CTA::BusTracker.predictions!(options.merge(opts))
    end

    def live!(position, predictions = [])
      class << self
        attr_reader :lat, :lon, :vehicle_id, :heading, :pattern_id, :pattern_distance,
                    :route, :delayed, :speed, :predictions
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

      @predictions = []
    end
  end
end
