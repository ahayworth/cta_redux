require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class CustomerAlerts
    class RouteStatus
      FIELDS = [:route, :route_color, :route_text_color, :service_id, :route_url, :status, :status_color]
      FIELDS.each { |f| attr_reader f }

      def initialize(s)
        @route = s["Route"]
        @route_color = s["RouteColorCode"]
        @route_text_color = s["RouteTextColor"]
        @service_id = s["ServiceId"]
        @route_url = s["RouteURL"]
        @status = s["RouteStatus"]
        @status_color = s["RouteStatusColor"]
      end
    end

    class Alert
      FIELDS = [:id, :alert_id, :headline, :short_description, :full_description, :score,
                :severity_color, :category, :impact, :start, :end, :tbd, :major_alert, :is_major_alert,
                :url, :services]

      FIELDS.each { |f| attr_reader f }
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

        @services = Array.wrap(a["ImpactedService"]["Service"]).map { |s| Service.new(s) }
      end

      def major?
        @major_alert
      end
    end

    class Service
      FIELDS = [:type, :description, :name, :id, :service_id, :service_color, :service_text_color, :service_url]
      FIELDS.each { |f| attr_reader f }

      def initialize(s)
        @id = @service_id = s["ServiceId"].to_i
        @type = s["ServiceType"].to_sym
        @description = s["ServiceTypeDescription"]
        @name = s["ServiceName"]
        @service_color = s["ServiceBackColor"]
        @service_text_color = s["ServiceTextColor"]
        @service_url = s["ServiceURL"]
      end
    end

    class AlertsResponse < CTA::API::Response
      attr_reader :alerts

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @alerts = Array.wrap(parsed_body["CTAAlerts"]["Alert"]).map { |a| Alert.new(a) }
      end
    end

    class RouteStatusResponse < CTA::API::Response
      attr_reader :routes

      def initialize(parsed_body, raw_body)
        super(parsed_body, raw_body)
        @routes = Array.wrap(parsed_body["CTARoutes"]["RouteInfo"]).map { |r| RouteStatus.new(r) }
      end
    end

  end
end
