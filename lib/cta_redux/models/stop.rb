module CTA
  class Stop < Sequel::Model
    set_primary_key :stop_id

    one_to_many :child_stops, :class => self, :key => :parent_station
    many_to_one :parent_stop, :class => self, :key => :parent_station

    one_to_many :transfers_from, :class => 'CTA::Transfer', :key => :from_stop_id
    one_to_many :transfers_to, :class => 'CTA::Transfer', :key => :to_stop_id

    many_to_many :trips, :left_key => :stop_id, :right_key => :trip_id, :join_table => :stop_times

    def routes
      CTA::Route.with_sql(<<-SQL)
        SELECT r.*
        FROM routes r
        WHERE r.route_id IN (
          SELECT DISTINCT t.route_id
          FROM stop_times st
            JOIN trips t ON st.trip_id = t.trip_id
          WHERE st.stop_id = '#{self.stop_id}'
        )
      SQL
    end

    # Some CTA routes are seasonal, and are missing from the GTFS feed.
    # However, the API still returns that info. So, we create a dummy CTA::Stop
    # to fill in the gaps. I've emailed CTA developer support for clarification.
    def self.new_from_api_response(s)
      CTA::Stop.unrestrict_primary_key
      stop = CTA::Stop.new({
        :stop_id => s["stpid"].to_i,
        :stop_name => s["stpnm"],
        :stop_lat => s["lat"].to_f,
        :stop_lon => s["lon"].to_f,
        :location_type => 3, # Bus in GTFS-land
        :stop_desc => "#{s["stpnm"]} (seasonal, generated from API results - missing from GTFS feed)"
      })
      CTA::Stop.restrict_primary_key

      stop
    end

    def stop_type
      if self.stop_id < 30000
        :bus
      elsif self.stop_id < 40000
        :rail
      else
        :parent_station
      end
    end

    def predictions!(options = {})
      if self.stop_type == :bus
        CTA::BusTracker.predictions!(options.merge({:stops => self.stop_id}))
      else
        if self.stop_type == :rail
          CTA::TrainTracker.predictions!(options.merge({:station => self.stop_id}))
        else
          CTA::TrainTracker.predictions!(options.merge({:parent_station => self.stop_id}))
        end
      end
    end
  end
end
