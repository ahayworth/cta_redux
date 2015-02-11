module CTA
  class BusTracker
    def self.connection
      raise "You need to set a developer key first. Try CTA::BusTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.ctabustracker.com/bustime/api/v2/'
        faraday.params = { :key => @key }

        faraday.use CTA::BusTracker::Parser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.time!
      connection.get('gettime')
    end

    def self.vehicles!(options={})
      has_vehicle = options.has_key?(:vehicles)
      has_route   = options.has_key?(:routes)

      if !(has_vehicle || has_route) || (has_vehicle && has_route)
        raise "Must specify either vehicle OR route options! Try vehicles(:routes => 37)"
      end

      vehicles = Array.wrap(options[:vehicles]).flatten.compact.uniq.join(',')
      routes   = Array.wrap(options[:routes]).flatten.compact.uniq.join(',')

      connection.get('getvehicles', { :rt => routes, :vid => vehicles })
    end

    def self.routes!
      connection.get('getroutes')
    end

    def self.directions!(options={})
      unless options.has_key?(:route)
        raise "Must specify a route! (Try directions(:route => 914) )"
      end

      routes = Array.wrap(options[:route]).flatten.compact.uniq

      if routes.size > 1
        raise "Only one route may be specified!"
      end
      connection.get('getdirections', { :rt => routes.first })
    end

    def self.stops!(options={})
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

    def self.patterns!(options={})
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

    def self.predictions!(options={})
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

    def self.bulletins!(options={})
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

    def self.key
      @key
    end

    def self.key=(key)
      @key = key
      @connection = nil
    end
  end
end
