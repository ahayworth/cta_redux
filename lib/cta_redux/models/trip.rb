module CTA
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

    many_to_one :calendar, :key => :service_id
    one_to_many :stop_times, :key => :trip_id

    many_to_one :route, :key => :route_id

    many_to_many :stops, :left_key => :trip_id, :right_key => :stop_id, :join_table => :stop_times

    # DRAGONS
    # The CTA doesn't exactly honor the GTFS spec (nor do they return GTFS trip_ids
    # in the API, grr). They specify multiple entries of # (schd_trip_id, block_id, service_id)
    # so the only way to know which trip_id to pick is to join against stop_times and
    # calendar dates, and # find out which run (according to stop_times) is happening *right now*.
    # Of course, this will break if the train is delayed more the total time
    # it takes to complete the run... so a delayed train will start to disappear
    # as it progresses through the run. We allow for a 'fuzz factor' to account
    # for this...
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
