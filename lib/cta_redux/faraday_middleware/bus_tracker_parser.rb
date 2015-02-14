module CTA
  class BusTracker
    class Parser < Faraday::Response::Middleware
      def initialize(app, debug)
        @debug = debug
        super(app)
      end

      def call(request_env)
        api_response = nil
        @app.call(request_env).on_complete do |response_env|
          parsed_body = ::MultiXml.parse(response_env.body)

          if has_errors?(parsed_body)
            api_response = CTA::API::Response.new(parsed_body, response_env.body, @debug)
          else
            case response_env.url.to_s
            when /bustime\/.+\/getvehicles/
              api_response = VehiclesResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/gettime/
              api_response = TimeResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getroutes/
              api_response = RoutesResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getdirections/
              api_response = DirectionsResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getstops/
              api_response = StopsResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getpatterns/
              api_response = PatternsResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getpredictions/
              api_response = PredictionsResponse.new(parsed_body, response_env.body, @debug)
            when /bustime\/.+\/getservicebulletins/
              api_response = ServiceBulletinsResponse.new(parsed_body, response_env.body, @debug)
            end
          end
        end

        api_response
      end

      def has_errors?(parsed_body)
        !parsed_body.has_key?("bustime_response") || parsed_body["bustime_response"].has_key?("error")
      end
    end
  end
end
