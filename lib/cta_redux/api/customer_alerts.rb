require 'date'
require 'faraday'
require 'multi_xml'

module CTA
  class CustomerAlerts
    class RouteStatus
      # @return [CTA::Route] The {CTA::Route} that corresponds to this {RouteStatus}
      attr_reader :route
      # @return [String] The color the CTA suggests when displaying information about this alert.
      attr_reader :route_color
      # @return [String] The color of text the CTA suggests when displaying information about this alert.
      attr_reader :route_text_color
      # @return [String] A text description of the status of this route.
      attr_reader :status
      # @return [String] A color suggestion from the CTA when displaying information about the route status.
      attr_reader :status_color

      def initialize(s)
        @route = CTA::Route.where(:route_id => s["Route"].split(" ").first).or(:route_id => s["ServiceId"]).first
        @route_color = s["RouteColorCode"]
        @route_text_color = s["RouteTextColor"]
        @status = s["RouteStatus"]
        @status_color = s["RouteStatusColor"]
      end
    end

    class Alert
      # @return [Integer] The internal ID of this alert
      attr_reader :id
      # @return [Integer] The internal ID of this alert
      attr_reader :alert_id
      # @return [String] A descriptive one-line summary for this alert
      attr_reader :headline
      # @return [String] A descriptive short summary for this alert
      attr_reader :short_description
      # @return [String] A long-form summary for this alert.
      # @note HTML formatted.
      attr_reader :full_description
      # @return [0..99] A score that describes how an impact this alert will have on any affected services.
      # @note The score ranges from +0-99+. It's unclear how this is calculated internally, but higher numbers seem to be worse.
      attr_reader :score
      # @return [String] The hex color used to color text related to this alert on transitchicago.com
      attr_reader :severity_color
      # @return [Symbol] One of +[:normal, :planned, :major, :minor]+
      attr_reader :category
      # @return [String] Descriptive text detailing the impact of this alert.
      attr_reader :impact
      # @return [DateTime] The date and time at which this alert takes effect.
      attr_reader :start
      # @return [DateTime] The date and time at which this alert ends. May be unknown.
      attr_reader :end
      # @return [true,false] Returns true if the alert is 'TBD' - that is, the end time is unknown.
      attr_reader :tbd
      # @return [true,false] Returns true if the alert is 'major' - that is the CTA is displaying it prominently on transitchicago.com and expects it to cause major headaches.
      attr_reader :major_alert
      # @return [true,false] Returns true if the alert is 'major' - that is the CTA is displaying it prominently on transitchicago.com and expects it to cause major headaches.
      attr_reader :is_major_alert
      # @return [String] A URL where customers could learn more about the alert.
      attr_reader :url
      # @return [Array<CTA::Route>] An array of {CTA::Route} objects that are impacted by this alert.
      attr_reader :services

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

      # @return [true,false] Returns true if the alert is 'major' - that is the CTA is displaying it prominently on transitchicago.com and expects it to cause major headaches.
      def major?
        @major_alert
      end
    end

    class AlertsResponse < CTA::API::Response
      # @return [Array<Alert>] An array of {Alert} objects that match the requested query.
      attr_reader :alerts

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @alerts = Array.wrap(parsed_body["CTAAlerts"]["Alert"]).map { |a| Alert.new(a) }
      end
    end

    class RouteStatusResponse < CTA::API::Response
      # @return [Array<RouteStatus>] An array of {RouteStatus} objects that match the requested query.
      attr_reader :routes

      def initialize(parsed_body, raw_body, debug)
        super(parsed_body, raw_body, debug)
        @routes = Array.wrap(parsed_body["CTARoutes"]["RouteInfo"]).map { |r| RouteStatus.new(r) }
      end
    end

  end
end
