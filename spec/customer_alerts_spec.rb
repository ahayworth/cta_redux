base_path = File.expand_path(File.dirname(__FILE__))
data_path = File.expand_path(File.join(base_path, 'stubs'))

require File.join(base_path, "..", "lib", "cta_redux")

RSpec.describe CTA::TrainTracker do
  stubs = Faraday::Adapter::Test::Stubs.new do |stub|
    stub.get('/api/1.0/routes.aspx?type=&routeid=&stationid=') { |env| [200, {}, File.read(File.join(data_path, 'routes_response.xml'))] }
    stub.get('/api/1.0/routes.aspx?type=&routeid=8&stationid=') { |env| [200, {}, File.read(File.join(data_path, 'route_status8_response.xml'))] }
    stub.get('/api/1.0/alerts.aspx') { |env| [200, {}, File.read(File.join(data_path, 'alerts_response.xml'))] }
  end

  CTA::CustomerAlerts.connection.instance_variable_get(:@builder).delete(Faraday::Adapter::NetHttp)
  CTA::CustomerAlerts.connection.adapter :test, stubs

  describe "status!" do
    it "returns all status information" do
      response = CTA::CustomerAlerts.status!

      expect(response).to be_instance_of(CTA::CustomerAlerts::RouteStatusResponse)
      expect(response.routes.size).to eq(140)
      expect(response.routes.first.route.route_id).to eq("Red")
      expect(response.routes.first.status).to eq("Planned Work w/Reroute")
    end

    it "returns status information for one route" do
      response = CTA::CustomerAlerts.status!(:routes => 8)

      expect(response).to be_instance_of(CTA::CustomerAlerts::RouteStatusResponse)
      expect(response.routes.size).to eq(1)
      expect(response.routes.first.route.route_id).to eq("8")
      expect(response.routes.first.status).to eq("Bus Stop Relocation")
    end
  end

  describe "alerts!" do
    it "returns all alerts" do
      response = CTA::CustomerAlerts.alerts!

      expect(response).to be_instance_of(CTA::CustomerAlerts::AlertsResponse)
      expect(response.alerts.size).to eq(44)
      expect(response.alerts.first.alert_id).to eq(23322)
      expect(response.alerts.first.category).to eq(:normal)
      expect(response.alerts.first.major_alert).to eq(false)
      expect(response.alerts.first.tbd).to eq(true)
    end
  end
end
