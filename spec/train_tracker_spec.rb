base_path = File.expand_path(File.dirname(__FILE__))
data_path = File.expand_path(File.join(base_path, 'stubs'))

require File.join(base_path, "..", "lib", "cta_redux")

RSpec.describe CTA::TrainTracker do
  stubs = Faraday::Adapter::Test::Stubs.new do |stub|
    stub.get('/api/1.0/ttarrivals.aspx?key=&stpid=30141') { |env| [200, {}, File.read(File.join(data_path, 'ttarivals_stpid30141_response.xml'))] }
    stub.get('/api/1.0/ttfollow.aspx?key=&runnumber=217') { |env| [200, {}, File.read(File.join(data_path, 'ttfollow_run217_response.xml'))] }
    stub.get('/api/1.0/ttpositions.aspx?key=&rt=red,blue,g,y,p,org,brn,pink') { |env| [200, {}, File.read(File.join(data_path, 'ttpositions_response.xml'))] }
  end

  CTA::TrainTracker.key = ''
  CTA::TrainTracker.connection.instance_variable_get(:@builder).delete(Faraday::Adapter::NetHttp)
  CTA::TrainTracker.connection.adapter :test, stubs

  describe "arrivals!" do
    it "finds arrivals for washington/wells" do
      response = CTA::TrainTracker.arrivals!(:station => 30141)

      expect(response).to be_instance_of(CTA::TrainTracker::ArrivalsResponse)
      expect(response.predictions.size).to eq(4)
      expect(response.routes.size).to eq(2)
      expect(response.trains.size).to eq(4)

      expect(response.predictions.first.run).to eq("301")
      expect(response.predictions.first.destination.stop_name).to eq("54th/Cermak")
      expect(response.predictions.first.minutes).to eq(3)
      expect(response.predictions.first.route.route_id).to eq("Pink")

      expect(response.routes.last.route_id).to eq("Org")

      expect(response.trains.last.route.route_type).to eq(1)
      expect(response.trains.last.schd_trip_id).to eq("R705")
    end
  end

  describe "follow!" do
    it "finds all predictions for blue line run 217" do
      response = CTA::TrainTracker.follow!(:run => 217)

      expect(response).to be_instance_of(CTA::TrainTracker::FollowResponse)
      expect(response.train).to be_instance_of(CTA::Train)
      expect(response.train.route_id).to eq("Blue")
      expect(response.train.route.route_id).to eq("Blue")
      expect(response.train.live.predictions).to eq(response.predictions)
      expect(response.predictions.first.direction).to eq("O'Hare-bound")
      expect(response.predictions.first.destination.stop_name).to eq("O'Hare")
      expect(response.predictions.first.approaching).to eq(false)
      expect(response.predictions.first.minutes).to eq(2)
    end
  end

  describe "locations!" do
    it "finds all trains on the system" do
      response = CTA::TrainTracker.positions!(:routes => [:red, :blue, :green, :yellow, :purple, :orange, :brown, :pink])

      expect(response).to be_instance_of(CTA::TrainTracker::PositionsResponse)
      expect(response.predictions.size).to eq(80)
      expect(response.routes.size).to eq(8)
      expect(response.trains.size).to eq(80)

      expect(response.trains.last.route.route_id).to eq("P")
      expect(response.trains.first.live.lon).to eq(-87.65338)
      expect(response.predictions.first.route.route_id).to eq("Red")
      expect(response.predictions.first.destination.stop_id).to eq(30173)
      expect(response.predictions.first.trip.service_id).to eq(104701)
    end
  end

  describe "bugs" do
    it "uses proper station IDs for Green line runs, which are wrong from the CTA GTFS feed" do
      trip = CTA::Trip[47085599996]
      expect(trip.stops.map(&:stop_id)).to include(30033)
    end
  end
end
