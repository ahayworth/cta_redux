module CTA
  class CustomerAlerts

    def self.connection
      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://www.transitchicago.com/api/1.0/'
        faraday.use CTA::CustomerAlerts::Parser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.status!(options = {})
      routes   = Array.wrap(options[:routes]).flatten.compact.uniq.join(',')
      stations = Array.wrap(options[:stations]).flatten.compact.uniq

      if stations.size > 1
        raise "Can only specify one station!"
      end

      connection.get('routes.aspx', { :type => options[:type], :routeid => routes, :stationid => stations.first })
    end

    def self.alerts!(options = {})
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
  end
end
