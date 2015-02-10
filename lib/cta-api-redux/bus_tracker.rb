module CTA
  class BusTracker
    ALLOWED_VEHICLE_KEYS = [:vehicle_id, :vehicle_ids, :vid, :vids, :vehicle, :vehicles]
    ALLOWED_ROUTE_KEYS = [:rt, :rts, :route, :routes, :route_id, :route_ids]
    ALLOWED_DIRECTION_KEYS = [:dir, :direction]
    ALLOWED_PATTERN_KEYS = [:pid, :pattern_id, :pattern_ids, :pids, :pattern, :patterns]
    ALLOWED_STOP_KEYS = [:stpid, :stpids, :stop, :stops, :stop_id, :stop_ids]
    ALLOWED_TOP_KEYS = [:top, :max, :limit]


    def self.connection
      raise "You need to set a developer key first. Try CTA::BusTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.ctabustracker.com/bustime/api/v2/'
        faraday.params = { :key => @key }

        faraday.use CTA::BusTracker::APIParser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.time
      connection.get('gettime')
    end

    def self.vehicles(options={})
      has_vehicle = options.keys.any? { |k| ALLOWED_VEHICLE_KEYS.include?(k) }
      has_route = options.keys.any? { |k| ALLOWED_ROUTE_KEYS.include?(k) }

      if !(has_vehicle || has_route) || (has_vehicle && has_route)
        raise "Must specify either vehicle or route options! Try vehicles(:route => 37)"
      end

      vehicles = []
      ALLOWED_VEHICLE_KEYS.each do |k|
        vehicles << Array.wrap(options[k])
      end
      vehicles = vehicles.flatten.compact.uniq.join(',')

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq.join(',')

      connection.get('getvehicles', { :rt => routes, :vid => vehicles })
    end

    def self.routes
      connection.get('getroutes')
    end

    def self.directions(options={})
      unless options.keys.any? { |k| ALLOWED_ROUTE_KEYS.include?(k) }
        raise "Must specify a route! (Try directions(:run => 914) )"
      end

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq

      if routes.size > 1
        raise "Only one route may be specified!"
      end
      connection.get('getdirections', { :rt => routes.first })
    end

    def self.stops(options={})
      has_route = options.keys.any? { |k| ALLOWED_ROUTE_KEYS.include?(k) }
      has_direction = options.keys.any? { |k| ALLOWED_DIRECTION_KEYS.include?(k) }

      if !(has_direction && has_route)
        raise "Must specify both direction and route options! Try stops(:route => 37, :direction => :northbound)"
      end

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq
      if routes.size > 1
        raise "Only one route may be specified!"
      end

      directions = []
      ALLOWED_DIRECTION_KEYS.each do |k|
        directions << Array.wrap(options[k])
      end
      directions = directions.flatten.compact.uniq
      if directions.size > 1
        raise "Only one direction may be specified!"
      end

      connection.get('getstops', { :rt => routes.first, :dir => directions.first.to_s.capitalize })
    end

    def self.patterns(options={})
      has_route = options.keys.any? { |k| ALLOWED_ROUTE_KEYS.include?(k) }
      has_pattern = options.keys.any? { |k| ALLOWED_PATTERN_KEYS.include?(k) }

      if !(has_pattern || has_route) || (has_pattern && has_route)
        raise "Must specify a pattern OR route option! Try patterns(:route => 37)"
      end

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq
      if routes.size > 1
        raise "Only one route may be specified!"
      end

      patterns = []
      ALLOWED_PATTERN_KEYS.each do |k|
        patterns << Array.wrap(options[k])
      end
      patterns = patterns.flatten.compact.uniq.join(',')

      connection.get('getpatterns', { :pid => patterns, :rt => routes.first })
    end

    def self.predictions(options={})
      has_stop = options.keys.any? { |k| ALLOWED_STOP_KEYS.include?(k) }
      has_vehicle = options.keys.any? { |k| ALLOWED_VEHICLE_KEYS.include?(k) }

      if !(has_stop || has_vehicle) || (has_stop && has_vehicle)
        raise "Must specify a stop (and optionally route), or vehicle! Try predictions(:stop => 6597)"
      end

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq.join(',')

      stops = []
      ALLOWED_STOP_KEYS.each do |k|
        stops << Array.wrap(options[k])
      end
      stops = stops.flatten.compact.uniq.join(',')

      vehicles = []
      ALLOWED_VEHICLE_KEYS.each do |k|
        vehicles << Array.wrap(options[k])
      end
      vehicles = vehicles.flatten.compact.uniq.join(',')

      limits = []
      ALLOWED_TOP_KEYS.each do |k|
        limits << Array.wrap(options[k])
      end
      limits = limits.flatten.compact.uniq.max

      connection.get('getpredictions', { :rt => routes, :vid => vehicles, :stpid => stops, :top => limits })
    end

    def self.bulletins(options={})
      has_route = options.keys.any? { |k| ALLOWED_ROUTE_KEYS.include?(k) }
      has_stop = options.keys.any? { |k| ALLOWED_STOP_KEYS.include?(k) }

      if !(has_route || has_stop)
        raise "Must provide at least a route or a stop! Try bulletins(:route => 22)"
      end

      directions = []
      ALLOWED_DIRECTION_KEYS.each do |k|
        directions << Array.wrap(options[k])
      end
      directions = directions.flatten.compact.uniq
      if directions.size > 1
        raise "Only one direction may be specified!"
      end

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k])
      end
      routes = routes.flatten.compact.uniq

      stops = []
      ALLOWED_STOP_KEYS.each do |k|
        stops << Array.wrap(options[k])
      end
      stops = stops.flatten.compact.uniq

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

    def self.key
      @key
    end

    def self.key=(key)
      @key = key
      @connection = nil
    end
  end
end
