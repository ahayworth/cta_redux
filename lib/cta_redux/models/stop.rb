module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#stops_txt___Field_Definitions stops.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:stop_id, :stop_code, :stop_name, :stop_desc, :stop_lat, :stop_lon, :location_type, :parent_station, :wheelchair_boarding]
  class Stop < Sequel::Model
    set_primary_key :stop_id

    # @!method child_stops
    #   Stops can have a hierarchical relationship. The CTA designates certain stops as "parent stops" which contain "child stops"
    #   A great example of this is an 'L' station - the station itself will be a parent stop, but each platform will be a child stop.
    #   @return [Array<CTA::Stop>] Child {CTA::Stop}s of this stop
    one_to_many :child_stops, :class => self, :key => :parent_station
    # @!method parent_stop
    #   Stops can have a hierarchical relationship. The CTA designates certain stops as "parent stops" which contain "child stops"
    #   A great example of this is an 'L' station - the station itself will be a parent stop, but each platform will be a child stop.
    #   @return [CTA::Stop] Parent {CTA::Stop} of this stop
    many_to_one :parent_stop, :class => self, :key => :parent_station

    # @!method transfers_from
    #   GTFS defines a {CTA::Transfer} object, that describes where customers may transfer lines.
    #   This method defines which {CTA::Stop} customers may transfer *from* at this {CTA::Stop}.
    #   By then introspecting on {CTA::Route}s attached to these stops, you can find the transfer points between routes at this stop.
    #   @return [Array<CTA::Stop>] All {CTA::Stop}s from which a customer may transfer at this stop
    one_to_many :transfers_from, :class => 'CTA::Transfer', :key => :from_stop_id
    # @!method transfers_to
    #   GTFS defines a {CTA::Transfer} object, that describes where customers may transfer lines.
    #   This method defines which {CTA::Stop} customers may transfer *to* at {CTA::Stop}.
    #   By then introspecting on {CTA::Route}s attached to these stops, you can find the transfer points between routes at this stop.
    #   @return [Array<CTA::Stop>] All {CTA::Stop}s to which a customer may transfer at this stop
    one_to_many :transfers_to, :class => 'CTA::Transfer', :key => :to_stop_id

    # @!method trips
    #   A {CTA::Route} may be related to many trips, through {CTA::StopTime} objects
    #   @return [Array<CTA::Trip>] The trips that will at some point use this {CTA::Stop}
    many_to_many :trips, :left_key => :stop_id, :right_key => :trip_id, :join_table => :stop_times

    # @!method stop_id
    #  @return [Integer]
    # @!method stop_code
    #  @return [Integer]
    # @!method stop_name
    #  @return [String]
    # @!method stop_desc
    #  @return [String]
    # @!method stop_lat
    #  @return [Float]
    # @!method stop_lon
    #  @return [Float]
    # @!method location_type
    #  @return [Integer]
    # @!method parent_station
    #  @return [Integer]
    # @!method wheelchair_boarding
    #  @return [true, false]
    alias_method :id, :stop_id
    alias_method :code, :stop_code
    alias_method :name, :stop_name
    alias_method :description, :stop_desc
    alias_method :lat, :stop_lat
    alias_method :lon, :stop_lon

    # Returns a {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Dataset.html Sequel::Dataset} that corresponds to all routes
    # associated with this {CTA::Stop} at some point
    # @return [Sequel::Dataset] All routes associated with this stop
    # @example
    #   CTA::Stop.first.routes.first #=> #<CTA::Route...
    #   CTA::Stop.first.routes.all   #=> [#<CTA::Route..., #<CTA::Route...]
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

    # Internal method.
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

    # The type of this stop. CTA partitions all stops on the numeric stop_id. It's unclear why the CTA does this,
    # but the TrainTracker API seems to separate out parent stations and stations in their requests, which complicates
    # following the GTFS spec to the letter. Additionally, because GTFS has no concept of differentiating stops based
    # on the type of vehicle expected to service that stop, the numerical ID can also differentiate a bus stop from a rail stop.
    # Bottom line? The CTA's APIs and GTFS itself is really confusing, and the actual reasons why this method exists
    # are unclear. You should just be able to rely on it.
    # @return [:bus, :rail, :parent_station]
    def stop_type
      if self.stop_id < 30000
        :bus
      elsif self.stop_id < 40000
        :rail
      else
        :parent_station
      end
    end

    # Returns predictions for this {CTA::Stop}. Accepts all options for {CTA::BusTracker.predictions!} or {CTA::TrainTracker.predictions!},
    # and will merge in # it's own stop/station/parent_station ID as needed.
    # @params [Hash] options
    # @return [CTA::BusTracker::PredictionsResponse, CTA::TrainTracker::ArrivalsResponse]
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
