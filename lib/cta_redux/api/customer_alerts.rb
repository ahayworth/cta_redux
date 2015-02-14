require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class CustomerAlerts
    class RouteStatus
      attr_reader :route, :route_color, :route_text_color, :service_id, :route_url, :status, :status_color

      def initialize(s)
        @route = CTA::Route.where(:route_id => s["Route"].split(" ").first).or(:route_id => s["ServiceId"]).first
        @route_color = s["RouteColorCode"]
        @route_text_color = s["RouteTextColor"]
        @status = s["RouteStatus"]
        @status_color = s["RouteStatusColor"]
      end
    end

    class Alert
      attr_reader :id, :alert_id, :headline, :short_description, :full_description, :score,
                  :severity_color, :category, :impact, :start, :end, :tbd, :major_alert, :is_major_alert,
                  :url, :services

      def initialize(a)
        @id = @alert_id = a["AlertId"].to_i
        @headline = a["Headline"]
        @short_description = a["ShortDescription"]
        @full_description = a["FullDescription"]
        @score = a["SeverityScore"].to_i
        @severity_color = a["SeverityColor"]
        @category = a["SeverityCSS"].downcase.to_sym
        @impact = a["Impact"]
        @start = DateTime.parse(a["EventStart"]) if a["EventStart"]
        @end = DateTime.parse(a["EventEnd"]) if a["EventEnd"]
        @tbd = (a["TBD"] == "1")
        @major_alert = @is_major_alert = (a["MajorAlert"] == "1")
        @url = a["AlertURL"]

        @services = Array.wrap(a["ImpactedService"]["Service"]).map do |s|
          CTA::Route.where(:route_id => s["ServiceName"].split(" ")).or(:route_id => s["ServiceId"]).first
        end
      end

      def major?
        @major_alert
      end
    end

    class AlertsResponse < CTA::API::Response
      attr_reader :alerts

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @alerts = Array.wrap(parsed_body["CTAAlerts"]["Alert"]).map { |a| Alert.new(a) }
      end
    end

    class RouteStatusResponse < CTA::API::Response
      attr_reader :routes

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @routes = Array.wrap(parsed_body["CTARoutes"]["RouteInfo"]).map { |r| RouteStatus.new(r) }
      end
    end

  end
end
