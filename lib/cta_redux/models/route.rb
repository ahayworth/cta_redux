module CTA
  class Route < Sequel::Model
    set_primary_key :route_id

    one_to_many :trips, :key => :route_id

    def live!(trains)
      class << self
        attr_reader :trains
      end

      @trains = trains
    end

    def predictions!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.predictions!(options.merge({:route => self.route_id.downcase}))
      else
        raise "E_NOTIMPLEMENTED"
      end
    end

    def locations!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.locations!(options.merge({:routes => self.route_id.downcase}))
      else
        raise "E_NOTIMPLEMENTED"
      end
    end

    def status!
      puts self.route_id
      CTA::CustomerAlerts.status!(:routes => self.route_id).routes.first
    end

    def alerts!
      CTA::CustomerAlerts.alerts!(:route => self.route_id).alerts
    end
  end
end
