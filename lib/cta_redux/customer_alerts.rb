module CTA
  class CustomerAlerts
    @cache_responses = true

    # Returns the connection object we use to talk to the CustomerAlerts API
    def self.connection
      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.transitchicago.com/api/1.0/'
        faraday.use CTA::CustomerAlerts::Parser, !!@debug
        if @cache_responses
          faraday.response :caching, (@cache || SimpleCache.new(Hash.new))
        end
        faraday.adapter Faraday.default_adapter
      end
    end

    # Returns an overview of system status.
    # @param [Hash] options
    # @option options [Array<Integer> Array<String>, Integer, String] :routes Routes to query for status
    # @option options [String, Integer] :stations Station to query for status
    # @return [CTA::CustomerAlerts::RouteStatusResponse]
    # @example
    #    CTA::CustomerAlerts.status!(:routes => [8,22])
    def self.status!(options = {})
      allowed_keys = [:routes, :station]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal argument!"
      end

      routes   = Array.wrap(options[:routes]).flatten.compact.uniq.join(',')
      stations = Array.wrap(options[:station]).flatten.compact.uniq

      if stations.size > 1
        raise "Can only specify one station!"
      end

      connection.get('routes.aspx', { :type => options[:type], :routeid => routes, :stationid => stations.first })
    end

    # Returns alerts for given routes or stations
    # @param [Hash] options
    # @option options [Array<Integer> Array<String>, Integer, String] :routes Routes to query for alerts. Not available with :station
    # @option options [Integer, String] :station Station to query for alerts. Not available with :route
    # @option options [true, false] :active Only return active alerts
    # @option options [true, false] :accessibility Include alerts related to accessibility (elevators, etc)
    # @option options [true, false] :planned Only return planned alerts
    # @option options [Integer] :recent_days Only return alerts within the specified number of days
    # @option options [Integer] :before Only return alerts starting prior to the specified number of days
    # @return [CTA::CustomerAlerts::AlertsResponse]
    # @example
    #    CTA::CustomerAlerts.alerts!(:route => 8)
    def self.alerts!(options = {})
      allowed_keys = [:active, :accessibility, :planned, :routes, :station, :recent_days, :before]
      if options.keys.any? { |k| !allowed_keys.include?(k) }
        raise "Illegal argument!"
      end

      params = {}
      params.merge!({ :activeonly => options[:active] }) if options[:active]
      params.merge!({ :accessibility => options[:accessiblity] }) if options[:accessibility]
      params.merge!({ :planned => options[:planned] }) if options[:planned]

      routes = Array.wrap(options[:routes]).flatten.compact.uniq
      stations = Array.wrap(options[:station]).flatten.compact.uniq

      if stations.size > 1
        raise "Can only specify one station!"
      end

      if routes.any? && stations.any?
        raise "Cannot use route and station together!"
      end

      if options[:recent_days] && options[:before]
        raise "Cannot use recent_days and before together!"
      end

      params.merge!({ :stationid => stations.first }) if stations.any?
      params.merge!({ :routeid => routes.join(',') }) if routes.any?
      params.merge!({ :recentdays => options[:recent_days] }) if options[:recent_days]
      params.merge!({ :bystartdate => options[:before] }) if options[:before]

      connection.get('alerts.aspx', params)
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

    # Returns whether or not cta_redux is caching responses
    # @return [true, false]
    def self.cache_responses
      @cache_responses
    end

    # Sets whether or not cta_redux is caching responses
    # @param [true, false] should_cache
    def self.cache_responses=(should_cache)
      @cache_responses = should_cache
      @connection = nil
    end

    # Returns the underlying cache object caching responses (if we're actually caching responses)
    # @return [Object]
    def self.cache
      if self.cache_responses
        # This is ugly
        @cache || self.connection.builder.handlers.find { |x| x == FaradayMiddleware::Caching }.instance_variable_get(:@args).first
      else
        nil
      end
    end

    # Sets the underlying cache object caching responses. Any object can be used that responds to #read, #write, and #fetch
    # @note Setting the cache object resets the connection. If you're using the default SimpleCache strategy (built-in 60
    #  second caching), then it will also *clear* the cache.
    # @param [Object] cache
    def self.cache=(cache)
      @cache = cache
      @connection = nil
    end
  end
end
