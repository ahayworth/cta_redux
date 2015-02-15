module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}, inherited from {CTA::Trip}
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#trips_txt___Field_Definitions trips.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:route_id, :service_id, :trip_id, :direction_id, :block_id, :shape_id, :direction, :wheelchair_accessible, :schd_trip_id]
  class Trip < Sequel::Model
    L_ROUTES = ["Brn", "G", "Pink", "P", "Org", "Red", "Blue", "Y"]
    BUS_ROUTES = CTA::Trip.exclude(:route_id => L_ROUTES).select_map(:route_id).uniq
    plugin :single_table_inheritance,
           :route_id,
           :model_map => proc { |v|
             if L_ROUTES.include?(v)
               'CTA::Train'
             else
               'CTA::Bus'
             end
           },
           :key_map => proc { |klass|
             if klass.name == 'CTA::Train'
               L_ROUTES
             else
               BUS_ROUTES
             end
           }

    set_primary_key :trip_id

    # @!method calendar
    #   @return [CTA::Calendar] The {CTA::Calendar} entry for this {CTA::Trip}. Can be used to determine
    #     if a given {CTA::Trip} is valid for a given date/time
    many_to_one :calendar, :key => :service_id

    # @!method stop_times
    #   @return [Array<CTA::StopTime>] The {CTA::StopTimes} that are serviced on this {CTA::Trip}
    one_to_many :stop_times, :key => :trip_id

    # @!method route
    #   @return [CTA::Route] The {CTA::Route} associated with this {CTA::Trip}
    many_to_one :route, :key => :route_id

    # @!method stops
    #   @return [Array<CTA::Stop>] All {CTA::Stop}s serviced on this {CTA::Trip}
    many_to_many :stops, :left_key => :trip_id, :right_key => :stop_id, :join_table => :stop_times

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
    def self.find_active_run(run, timestamp, fuzz = false)
      if self.to_s == "CTA::Train" # This is admittedly hacky.
        join_str = "WHERE t.schd_trip_id = 'R#{run}'"
      else
        join_str = "WHERE t.route_id = '#{run}'"
      end
      d = timestamp.is_a?(DateTime) ? timestamp : DateTime.parse(timestamp)
      wday = d.strftime("%A").downcase
      end_ts = (fuzz ? (d.to_time + (60 * 60 * 6) - (90 * 60)) : d).strftime("%H:%M:%S")
      Trip.with_sql(<<-SQL)
        SELECT t.*
        FROM trips t
          JOIN stop_times st ON t.trip_id = st.trip_id
          JOIN calendar   c  ON t.service_id = c.service_id
        #{join_str}
          AND c.start_date <= '#{d.to_s}'
          AND c.end_date   >= '#{d.to_s}'
          AND c.#{wday}
        GROUP BY t.trip_id, st.departure_time
        HAVING  MAX(st.departure_time) >= '#{end_ts}'
      SQL
    end

  end
end
