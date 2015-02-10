module CTA
  class TrainTracker
    class Parser < Faraday::Response::Middleware
      def call(request_env)
        api_response = nil

        @app.call(request_env).on_complete do |response_env|
          parsed_body = ::MultiXml.parse(response_env.body)

          if has_errors?(parsed_body)
            api_response = Response.new(parsed_body, response_env.body)
          else
            case response_env.url.to_s
            when /ttarrivals\.aspx/
              api_response = ArrivalsResponse.new(parsed_body, response_env.body)
            when /ttfollow\.aspx/
              api_response = FollowResponse.new(parsed_body, response_env.body)
            when /ttpositions\.aspx/
              api_response = PositionsResponse.new(parsed_body, response_env.body)
            end
          end
        end

        api_response
      end

      def has_errors?(parsed_body)
        parsed_body["ctatt"]["errCd"] != "0"
      end
    end
  end
end
