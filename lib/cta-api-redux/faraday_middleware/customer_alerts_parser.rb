module CTA
  class CustomerAlerts
    class APIParser < Faraday::Response::Middleware
      def call(request_env)
        api_response = nil

        @app.call(request_env).on_complete do |response_env|
          parsed_body = ::MultiXml.parse(response_env.body)

          if has_errors?(parsed_body)
            api_response = APIResponse.new(parsed_body, response_env.body)
          else
            case response_env.url.to_s
            when /routes\.aspx/
              api_response = RouteStatusResponse.new(parsed_body, response_env.body)
            when /alerts\.aspx/
              api_response = AlertsResponse.new(parsed_body, response_env.body)
            end
          end
        end

        api_response
      end

      def has_errors?(parsed_body)
        if parsed_body["CTARoutes"]
          Array.wrap(parsed_body["CTARoutes"]["ErrorCode"]).flatten.compact.uniq.first != "0"
        else
          Array.wrap(parsed_body["CTAAlerts"]["ErrorCode"]).flatten.compact.uniq.first != "0"
        end
      end
    end
  end
end
