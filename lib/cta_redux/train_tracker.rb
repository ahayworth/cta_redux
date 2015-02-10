module CTA
  class TrainTracker
    def self.connection
      raise "You need to set a developer key first. Try CTA::TrainTracker.key = 'foo'." unless @key

      @connection ||= Faraday.new do |faraday|
        faraday.url_prefix = 'http://lapi.transitchicago.com/api/1.0/'
        faraday.params = { :key => @key }

        faraday.use CTA::TrainTracker::APIParser
        faraday.response :caching, SimpleCache.new(Hash.new)
        faraday.adapter Faraday.default_adapter
      end
    end

    def self.arrivals(options={})
      if [:map_id, :stop_id].none? { |o| options.keys.include?(o) }
        raise "You must specify a map_id or a stop_id! Try arrivals(:stop_id => 30280..."
      end

      rt = []
      [:route, :rt].each do |k|
        rt << Array.wrap(options[k]).map { |r| FRIENDLY_ROUTES[r] || r }
      end
      rt = rt.flatten.compact.uniq

      if rt.size > 1
        raise "No more than 1 route may be specified!"
      end

      params = {}
      params.merge!({ :mapid => options[:map_id] }) if options[:map_id]
      params.merge!({ :stpid => options[:stop_id] }) if options[:stop_id]
      params.merge!({ :max => options[:max] }) if options[:max]
      params.merge!({ :rt => rt.first }) if rt.any?

      connection.get('ttarrivals.aspx', params)
    end

    def self.predictions(options={})
      self.arrivals(options)
    end

    def self.follow(options={})
      allowed_keys = [:run, :runnumber, :run_number]
      unless options.keys.any? { |k| allowed_keys.include?(k) }
        raise "Must specify a run! (Try follow(:run => 914) )"
      end

      runs = []
      allowed_keys.each do |k|
        runs << Array.wrap(options[k])
      end
      runs = runs.flatten.compact.uniq

      if runs.size > 1
        raise "Only one run may be specified!"
      end

      connection.get('ttfollow.aspx', { :runnumber => runs.first })
    end

    def self.locations(options={})
      allowed_keys = [:route, :routes, :rt]
      unless options.keys.any? { |k| allowed_keys.include?(k) }
        raise "Must specify at least one route! (Try locations(:routes => [:red, :blue]) )"
      end

      rt = []
      allowed_keys.each do |k|
        rt << Array.wrap(options[k]).map { |r| FRIENDLY_ROUTES[r] || r }
      end

      if rt.size > 8
        raise "No more than 8 routes may be specified!"
      end
      rt = rt.flatten.compact.join(",")

      connection.get('ttpositions.aspx', { :rt => rt })
    end

    def self.positions(options={})
      self.locations(options)
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
