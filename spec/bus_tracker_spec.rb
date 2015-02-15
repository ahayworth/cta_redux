base_path = File.expand_path(File.dirname(__FILE__))
data_path = File.expand_path(File.join(base_path, 'stubs'))

require File.join(base_path, "..", "lib", "cta_redux")

RSpec.describe CTA::BusTracker do
  stubs = Faraday::Adapter::Test::Stubs.new do |stub|
    stub.get('/bustime/api/v2/gettime?key=') { |env| [200, {}, File.read(File.join(data_path, 'gettime_response.xml'))] }
    stub.get('/bustime/api/v2/getvehicles?key=&rt=22') { |env| [200, {}, File.read(File.join(data_path, 'getvehicles_rt22_response.xml'))] }
    stub.get('/bustime/api/v2/getvehicles?key=&vid=4394') { |env| [200, {}, File.read(File.join(data_path, 'getvehicles_vid4394_response.xml'))] }
    stub.get('/bustime/api/v2/getroutes?key=') { |env| [200, {}, File.read(File.join(data_path, 'getroutes_response.xml'))] }
    stub.get('/bustime/api/v2/getdirections?key=&rt=22') { |env| [200, {}, File.read(File.join(data_path, 'getdirections_response.xml'))] }
    stub.get('/bustime/api/v2/getstops?key=&rt=22&dir=Northbound') { |env| [200, {}, File.read(File.join(data_path, 'getstops_response.xml'))] }
    stub.get('/bustime/api/v2/getpatterns?key=&rt=22') { |env| [200, {}, File.read(File.join(data_path, 'getpatterns_rt22_response.xml'))] }
    stub.get('/bustime/api/v2/getpredictions?key=&rt=22&stpid=15895&top=&vid=') { |env| [200, {}, File.read(File.join(data_path, 'getpredictions_rt22stpid15895_response.xml'))] }
    stub.get('/bustime/api/v2/getpredictions?key=&vid=4361') { |env| [200, {}, File.read(File.join(data_path, 'getpredictions_vid4361_response.xml'))] }
    stub.get('/bustime/api/v2/getservicebulletins?key=&rt=8') { |env| [200, {}, File.read(File.join(data_path, 'getservicebulletins_rt8_response.xml'))] }
  end

  CTA::BusTracker.key = ''
  CTA::BusTracker.connection.instance_variable_get(:@builder).delete(Faraday::Adapter::NetHttp)
  CTA::BusTracker.connection.adapter :test, stubs

  describe "time!" do
    result = CTA::BusTracker.time!

    it "returns an error code" do
      expect(result.error).to  be_instance_of(CTA::API::Error)
      expect(result.error.code).to eq(0)
      expect(result.error.message).to eq("OK")
    end

    it "returns a time" do
      expect(result.timestamp).to be_instance_of(DateTime)
      expect(result.timestamp.to_s).to eq("2015-02-14T11:31:13+00:00")
    end
  end

  describe "vehicles!" do
    it "returns vehicles for route 22" do
      result = CTA::BusTracker.vehicles!(:routes => 22)

      expect(result).to be_instance_of(CTA::BusTracker::VehiclesResponse)
      expect(result.vehicles.size).to eq(13)

      expect(result.vehicles.first.route).to be_instance_of(CTA::Route)
      expect(result.vehicles.first.route.route_id).to eq("22")
      expect(result.vehicles.first.live.vehicle_id).to eq(4394)
      expect(result.vehicles.first.live.pattern_distance).to eq(115)
    end

    it "returns information about one vehicle" do
      result = CTA::BusTracker.vehicles!(:vehicles => 4394)

      expect(result).to be_instance_of(CTA::BusTracker::VehiclesResponse)
      expect(result.vehicles.size).to eq(1)
      expect(result.vehicles.first.route).to be_instance_of(CTA::Route)
      expect(result.vehicles.first.route.route_id).to eq("22")
      expect(result.vehicles.first.live.vehicle_id).to eq(4394)
      expect(result.vehicles.first.live.heading).to eq(359)
    end
  end

  describe "routes!" do
    it "returns information about all routes" do
      result = CTA::BusTracker.routes!

      expect(result).to be_instance_of(CTA::BusTracker::RoutesResponse)
      expect(result.routes.size).to eq(127)
      expect(result.routes.first.route_id).to eq("1")
    end
  end

  describe "directions!" do
    it "returns two directions for route 22" do
      result = CTA::BusTracker.directions!(:route => 22)

      expect(result).to be_instance_of(CTA::BusTracker::DirectionsResponse)
      expect(result.directions.size).to eq(2)
      expect(result.directions.first.direction).to eq("Northbound")
    end
  end

  describe "stops!" do
    it "returns information about Northbound route 22 stops" do
      result = CTA::BusTracker.stops!(:route => 22, :direction => :northbound)

      expect(result).to be_instance_of(CTA::BusTracker::StopsResponse)
      expect(result.stops.size).to eq(86)
      expect(result.stops.first).to be_instance_of(CTA::Stop)
      expect(result.stops.first.stop_name).to eq("Clark & Addison")
    end
  end

  describe "patterns!" do
    it "returns information about patterns for route 22" do
      result = CTA::BusTracker.patterns!(:route => 22)

      expect(result).to be_instance_of(CTA::BusTracker::PatternsResponse)
      expect(result.patterns.first.direction).to be_instance_of(CTA::BusTracker::Direction)
      expect(result.patterns.first.id).to eq(3936)
      expect(result.patterns.first.points.size).to eq(124)
      expect(result.patterns.first.points.first.sequence).to eq(1)
      expect(result.patterns.first.points.first.stop).to be_instance_of(CTA::Stop)
      expect(result.patterns.first.points.first.stop.stop_id).to eq(14096)
      expect(result.patterns.first.points[1].lat).to eq(42.019043088282)
      expect(result.patterns.first.points[1].type).to eq(:waypoint)
      expect(result.patterns.first.points[1].sequence).to eq(2)
    end
  end

  describe "predictions!" do
    it "returns predictions for route 22 stop 15898" do
      result = CTA::BusTracker.predictions!(:routes => 22, :stops => 15895)

      expect(result).to be_instance_of(CTA::BusTracker::PredictionsResponse)
      expect(result.vehicles.size).to eq(2)
      expect(result.vehicles.first.route.route_id).to eq("22")
      expect(result.predictions.size).to eq(2)
      expect(result.predictions.first.type).to eq("D")
      expect(result.predictions.first.minutes).to eq(5)
      expect(result.predictions.first.arrival_time.to_s).to eq("2015-02-14T12:25:00+00:00")
      expect(result.predictions.first.delayed).to eq(false)
    end

    it "returns predictions for vehicle 4361" do
      result = CTA::BusTracker.predictions!(:vehicles => 4361)

      expect(result).to be_instance_of(CTA::BusTracker::PredictionsResponse)
      expect(result.vehicles.size).to eq(30)
      expect(result.vehicles.first.route.route_id).to eq("22")
      expect(result.predictions.size).to eq(30)
      expect(result.predictions.first.type).to eq("A")
      expect(result.predictions.first.minutes).to eq(2)
      expect(result.predictions.first.arrival_time.to_s).to eq("2015-02-14T12:38:00+00:00")
      expect(result.predictions.first.delayed).to eq(false)
    end
  end

  it "returns bulletins for route 8" do
    result = CTA::BusTracker.bulletins!(:routes => 8)

    expect(result).to be_instance_of(CTA::BusTracker::ServiceBulletinsResponse)
    expect(result.bulletins.size).to eq(6)
    expect(result.bulletins.first.subject).to eq("#8 Halsted reroute Halsted/35th")
    expect(result.bulletins.first.affected_services.size).to eq(1)
    expect(result.bulletins.first.affected_services.first.route.route_id).to eq("8")
  end
end
