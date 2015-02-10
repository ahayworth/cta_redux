module CTA
  class CustomerAlerts
    ALLOWED_ROUTE_KEYS = [:rt, :rts, :route, :routes, :route_id, :route_ids]
    ALLOWED_STATION_KEYS = [:station, :station_id, :stationid]

    def self.connection
      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.transitchicago.com/api/1.0/'
        faraday.use CTA::CustomerAlerts::Parser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.status(options = {})
      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k]).map { |r| FRIENDLY_L_ROUTES[r] || r }
      end
      routes = routes.flatten.compact.uniq.join(',')

      stations = []
      ALLOWED_STATION_KEYS.each do |k|
        stations << Array.wrap(options[k])
      end
      stations = stations.flatten.compact.uniq
      if stations.size > 1
        raise "Can only specify one station!"
      end

      connection.get('routes.aspx', { :type => options[:type], :routeid => routes, :stationid => stations.first })
    end

    def self.alerts(options = {})
      params = {}
      params.merge!({ :activeonly => options[:active] }) if options[:active]
      params.merge!({ :accessibility => options[:accessiblity] }) if options[:accessibility]
      params.merge!({ :planned => options[:planned] }) if options[:planned]

      routes = []
      ALLOWED_ROUTE_KEYS.each do |k|
        routes << Array.wrap(options[k]).map { |r| FRIENDLY_L_ROUTES[r] || r }
      end
      routes = routes.flatten.compact.uniq

      stations = []
      ALLOWED_STATION_KEYS.each do |k|
        stations << Array.wrap(options[k])
      end

      stations = stations.flatten.compact.uniq
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
  end

end
