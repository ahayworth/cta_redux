module CTA
  class BusTracker
    # Returns the connection object we use to talk to the BusTracker API
    def self.connection
      raise "You need to set a developer key first. Try CTA::BusTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.ctabustracker.com/bustime/api/v2/'
        faraday.params = { :key => @key }

        faraday.use CTA::BusTracker::Parser, !!@debug
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    # Returns the current time according to the BusTime servers that power the BusTracker API.
    # @return [CTA::BusTracker::TimeResponse]
    def self.time!
      connection.get('gettime')
    end

    # Returns status of vehicles out on the road.
    # @param [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :vehicles A list or single vehicle IDs to query.
    #   Not available with :routes.
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes A list or single route IDs to query.
    #   Not available with :vehicles.
    # @return [CTA::BusTracker::VehiclesResponse]
    # @example
    #   CTA::BusTracker.vehicles!(:routes => [22,36])
    #   CTA::BusTracker.vehicles!(:vehicles => 4240)
    def self.vehicles!(options={})
      allowed_keys = [:vehicles, :routes]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_vehicle = options.has_key?(:vehicles)
      has_route   = options.has_key?(:routes)

      if !(has_vehicle || has_route) || (has_vehicle && has_route)
        raise "Must specify either vehicle OR route options! Try vehicles(:routes => 37)"
      end

      vehicles = Array.wrap(options[:vehicles]).flatten.compact.uniq.join(',')
      routes   = Array.wrap(options[:routes]).flatten.compact.uniq.join(',')

      connection.get('getvehicles', { :rt => routes, :vid => vehicles })
    end

    # Returns a list of all routes the BusTracker API knows about - whether or not they are active.
    # @return [CTA::BusTracker::RoutesResponse]
    def self.routes!
      connection.get('getroutes')
    end

    # Returns the directions in which a route operates (eg Eastbound, Westbound)
    # @param [Hash] options
    # @option options [String, Integer] :route The route to query for available directions
    # @return [CTA::BusTracker::DirectionsResponse]
    # @example
    #   CTA::BusTracker.directions!(:route => 37)
    def self.directions!(options={})
      allowed_keys = [:route]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      unless options.has_key?(:route)
        raise "Must specify a route! (Try directions(:route => 914) )"
      end

      routes = Array.wrap(options[:route]).flatten.compact.uniq

      if routes.size > 1
        raise "Only one route may be specified!"
      end
      connection.get('getdirections', { :rt => routes.first })
    end

    # Returns the stops along a route and direction
    # @params [Hash] options
    # @option options [String, Integer] :route The route to query for stops
    # @option options [String, Integer] :direction The direction to query for stops
    # @return [CTA::BusTracker::StopsResponse]
    # @example
    #   CTA::BusTracker.stops!(:route => 22, :direction => :northbound)
    def self.stops!(options={})
      allowed_keys = [:route, :direction]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_route     = options.has_key?(:route)
      has_direction = options.has_key?(:direction)

      if !(has_direction && has_route)
        raise "Must specify both direction and route options! Try stops(:route => 37, :direction => :northbound)"
      end

      routes     = Array.wrap(options[:route]).flatten.compact.uniq
      directions = Array.wrap(options[:direction]).flatten.compact.uniq
      if routes.size > 1
        raise "Only one route may be specified!"
      end

      if directions.size > 1
        raise "Only one direction may be specified!"
      end

      connection.get('getstops', { :rt => routes.first, :dir => directions.first.to_s.capitalize })
    end

    # Returns available patterns for a route
    # @params [Hash] options
    # @option options [String, Integer] :route The route to query for patterns. Not available with :patterns
    # @option options [Array<String>, Array<Integer>, String, Integer] :patterns Patterns to return. Not available with :route
    # @return [CTA::BusTracker::PatternsResponse]
    # @example
    #   CTA::BusTracker.patterns!(:route => 22)
    #   CTA::BusTracker.patterns!(:patterns => [3936, 3932])
    def self.patterns!(options={})
      allowed_keys = [:route, :patterns]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_route   = options.has_key?(:route)
      has_pattern = options.has_key?(:patterns)

      if !(has_pattern || has_route) || (has_pattern && has_route)
        raise "Must specify a pattern OR route option! Try patterns(:route => 37)"
      end

      routes   = Array.wrap(options[:route]).flatten.compact.uniq
      patterns = Array.wrap(options[:patterns]).flatten.compact.uniq.join(',')
      if routes.size > 1
        raise "Only one route may be specified!"
      end

      connection.get('getpatterns', { :pid => patterns, :rt => routes.first })
    end

    # Returns a set of arrival/departure predictions.
    # @params [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :vehicles Vehicles to predict. Not available with :routes
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes to predict. Not available with :vehicles
    # @option options [Array<String>, Array<Integer>, String, Integer] :stops Stops along a route to predict. Required with :routes
    # @option options [String, Integer] :limit Maximum number of predictions to return.
    # @return [CTA::BusTracker::PredictionsResponse]
    # @example
    #   CTA::BusTracker.predictions!(:routes => 22, :stops => 15895)
    #   CTA::BusTracker.predictions!(:vehicles => [2172, 1860], :limit => 1)
    def self.predictions!(options={})
      allowed_keys = [:vehicles, :stops, :routes, :limit]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_vehicle = options.has_key?(:vehicles)
      has_stop    = options.has_key?(:stops)

      if !(has_stop || has_vehicle) || (has_stop && has_vehicle)
        raise "Must specify a stop (and optionally route), or vehicles! Try predictions(:stops => 6597)"
      end

      routes   = Array.wrap(options[:routes]).flatten.compact.uniq.join(',')
      stops    = Array.wrap(options[:stops]).flatten.compact.uniq.join(',')
      vehicles = Array.wrap(options[:vehicles]).flatten.compact.uniq.join(',')
      limit    = Array.wrap(options[:limit]).first.to_i if options.has_key?(:limit)

      connection.get('getpredictions', { :rt => routes, :vid => vehicles, :stpid => stops, :top => limit })
    end

    # Returns active bulletins.
    # @note Consider using {CTA::CustomerAlerts.alerts!} or {CTA::CustomerAlerts.status!}, as those are not rate-limited.
    # @params [Hash] options
    # @option options [Array<String>, Array<Integer>, String, Integer] :routes Routes for which to retrieve bulletins.
    #   When combined with :direction or :stops, may only specify one :route.
    # @option options [String, Integer] :direction Direction of a route for which to retrieve bulletins.
    # @option options [String, Integer] :stop Stop along a route for which to retrieve bulletins.
    # @return [CTA::BusTracker::ServiceBulletinsResponse]
    # @example
    #   CTA::BusTracker.bulletins!(:routes => [8, 22])
    def self.bulletins!(options={})
      allowed_keys = [:routes, :directions, :stop]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal option!"
      end

      has_route = options.has_key?(:routes)
      has_stop  = options.has_key?(:stop)

      if !(has_route || has_stop)
        raise "Must provide at least a route or a stop! Try bulletins(:routes => 22)"
      end

      directions = Array.wrap(options[:direction]).flatten.compact.uniq
      routes     = Array.wrap(options[:routes]).flatten.compact.uniq
      stops      = Array.wrap(options[:stop]).flatten.compact.uniq

      if directions.size > 1
        raise "Only one direction may be specified!"
      end

      if directions.any? && routes.size != 1
        raise "Must specify one and only one route when combined with a direction"
      end

      if (directions.any? || routes.any?) && stops.size > 1
        raise "Cannot specify more than one stop when combined with a route and direction"
      end

      routes = routes.join(',')
      stops = stops.join(',')

      connection.get('getservicebulletins', { :rt => routes, :stpid => stops, :dir => directions.first })
    end

    # Returns the current API key used to talk to BusTracker
    # @return [String] the api key
    def self.key
      @key
    end

    # Sets the API key used to talk to BusTracker
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
