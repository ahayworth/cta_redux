module CTA
  class TrainTracker
    # Returns the connection object we use to talk to the TrainTracker API
    def self.connection
      raise "You need to set a developer key first. Try CTA::TrainTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://lapi.transitchicago.com/api/1.0/'
        faraday.params = { :key => @key }

        faraday.use CTA::TrainTracker::Parser, !!@debug
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    # Returns the arrivals for a route, or station
    # @param [Hash] options
    # @option options [String, Integer] :route The route to query
    # @option options [String, Integer] :station The station to query for arrivals
    # @option options [String, Integer] :parent_station The parent station to query for arrivals.
    # @option options [String, Integer] :limit Maximum number of results to return
    # @return [CTA::TrainTracker::ArrivalsResponse]
    # @example
    #    CTA::TrainTracker.arrivals!(:route => :red)
    def self.arrivals!(options={})
      allowed_keys = [:route, :parent_station, :station, :limit]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_map  = options.has_key?(:parent_station)
      has_stop = options.has_key?(:station)

      route = Array.wrap(options[:route]).flatten.compact.uniq
      map   = Array.wrap(options[:parent_station]).flatten.compact.uniq
      stop  = Array.wrap(options[:station]).flatten.compact.uniq
      limit = Array.wrap(options[:limit]).flatten.compact.uniq.first.to_i if options[:limit]

      if route.size > 1
        raise "No more than 1 route may be specified!"
      end

      if map.size > 1 || stop.size > 1
        raise "No more than 1 station or parent_station may be specified!"
      end

      if !(has_map || has_stop)
        raise "You must specify a station or a parent_station! Try arrivals(:station => 30280..."
      end

      params = {}
      params.merge!({ :mapid => map.first }) if options[:parent_station]
      params.merge!({ :stpid => stop.first }) if options[:station]
      params.merge!({ :max => limit }) if options[:limit]
      params.merge!({ :rt => route.first }) if route.any?

      connection.get('ttarrivals.aspx', params)
    end

    # Returns the arrivals for a route, or station
    # @param [Hash] options
    # @option options [String, Integer] :route The route to query
    # @option options [String, Integer] :station The station to query for arrivals
    # @option options [String, Integer] :parent_station The parent station to query for arrivals.
    # @option options [String, Integer] :limit Maximum number of results to return
    # @return [CTA::TrainTracker::ArrivalsResponse]
    # @example
    #    CTA::TrainTracker.predicitons!(:route => :red)
    def self.predictions!(options={})
      self.arrivals!(options)
    end

    # Returns a set of upcoming positions for a train/run
    # @param [Hash] options
    # @option options [String, Integer] :run The run number of the train to follow
    # @return [CTA::TrainTracker::FollowResponse]
    # @example
    #    CTA::TrainTracker.follow!(:run => 914)
    def self.follow!(options={})
      raise "Must specify a run! Try follow(:run => 914)..." unless options.has_key?(:run)

      runs = Array.wrap(options[:run]).flatten.compact.uniq

      if runs.size > 1
        raise "Only one run may be specified!"
      end

      connection.get('ttfollow.aspx', { :runnumber => runs.first })
    end

    # Returns the position and next station of all trains in service.
    # @param [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes for which to return positions
    # @return [CTA::TrainTracker::LocationsResponse]
    # @example
    #    CTA::TrainTracker.locations!(:route => [:red, :blue])
    def self.locations!(options={})
      unless options.has_key?(:routes)
        raise "Must specify at least one route! (Try locations(:routes => [:red, :blue]) )"
      end

      rt = Array.wrap(options[:routes]).flatten.compact.map { |r| (CTA::Train::FRIENDLY_L_ROUTES[r] || r).to_s }

      if rt.size > 8
        raise "No more than 8 routes may be specified!"
      end

      connection.get('ttpositions.aspx', { :rt => rt.join(',') })
    end

    # Returns the position and next station of all trains in service.
    # @param [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes for which to return positions
    # @return [CTA::TrainTracker::LocationsResponse]
    # @example
    #    CTA::TrainTracker.positions!(:route => [:red, :blue])
    def self.positions!(options={})
      self.locations!(options)
    end

    # Returns the current API key used to talk to TrainTracker
    # @return [String] the api key
    def self.key
      @key
    end

    # Sets the API key used to talk to TrainTracker
    # @note If using SimpleCache as a caching strategy, this resets the cache.
    # @param key [String] The key to use
    def self.key=(key)
      @key = key
      @connection = nil
    end

    # Returns the debug status of the API. When in debug mode, all API responses will additionally return
    # the parsed XML tree, and the original XML for inspection
    def self.debug
      !!@debug
    end

    # Sets the debug status of the API. When in debug mode, all API responses will additionally return
    # the parsed XML tree, and the original XML for inspection
    # @param debug [true, false]
    def self.debug=(debug)
      @debug = debug
      @connection = nil
    end
  end
end
