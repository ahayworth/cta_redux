module CTA
  class API
    class Error
      # @return [Integer] Error code from the API. Normalized across different CTA APIs, and 0 indicates success.
      attr_reader :code

      # @return [String] Detailed error message, if any, from the API.
      attr_reader :message

      def initialize(options = {})
        @message = options[:message] || "OK"
        @code = options[:code] ? options[:code].to_i : (@message == "OK" ? 0 : 1)
      end
    end

    class Response
      # @return [DateTime] Timestamp from the API server, if available. Defaults to DateTime.now if unavailable.
      attr_reader :timestamp

      # @return [CTA::API::Error] Error information from the API
      attr_reader :error

      # @return [String, nil] Raw XML from the API. Only set when {CTA::BusTracker.debug} or {CTA::TrainTracker.debug} is true.
      attr_reader :raw_body

      # @return [Hash, nil] Parsed XML from the API. Only set when {CTA::BusTracker.debug} or {CTA::TrainTracker.debug} is true.
      attr_reader :parsed_body

      def initialize(parsed_body, raw_body, debug)
        if parsed_body["bustime_response"]
          @timestamp = DateTime.now
          if parsed_body["bustime_response"].has_key?("error")
            @error = Error.new({ :message => parsed_body["bustime_response"]["error"]["msg"] })
          else
            @error = Error.new
          end
        elsif parsed_body["ctatt"]
          @timestamp = DateTime.parse(parsed_body["ctatt"]["tmst"])
          @error = Error.new({ :code => parsed_body["ctatt"]["errCd"], :message => parsed_body["ctatt"]["errNm"] })
        else # CustomerAlert
          key = parsed_body["CTARoutes"] ? "CTARoutes" : "CTAAlerts"
          code = Array.wrap(parsed_body[key]["ErrorCode"]).flatten.compact.uniq.first
          msg = Array.wrap(parsed_body[key]["ErrorMessage"]).flatten.compact.uniq.first
          @timestamp = DateTime.parse(parsed_body[key]["TimeStamp"])
          @error = Error.new({ :code => code, :message => msg })
        end

        if debug
          @parsed_body = parsed_body
          @raw_body = raw_body
        end
      end
    end
  end
end
