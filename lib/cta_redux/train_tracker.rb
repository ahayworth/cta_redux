module CTA
  class TrainTracker
    def self.connection
      raise "You need to set a developer key first. Try CTA::TrainTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://lapi.transitchicago.com/api/1.0/'
        faraday.params = { :key => @key }

        faraday.use CTA::TrainTracker::Parser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.arrivals!(options={})
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
      params.merge!({ :max => options[:limit] }) if options[:limit]
      params.merge!({ :rt => route.first }) if route.any?

      connection.get('ttarrivals.aspx', params)
    end

    def self.predictions!(options={})
      self.arrivals!(options)
    end

    def self.follow!(options={})
      raise "Must specify a run! Try follow(:run => 914)..." unless options.has_key?(:run)

      runs = Array.wrap(options[:run]).flatten.compact.uniq

      if runs.size > 1
        raise "Only one run may be specified!"
      end

      connection.get('ttfollow.aspx', { :runnumber => runs.first })
    end

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

    def self.positions!(options={})
      self.locations!(options)
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
