module CTA
  class Route < Sequel::Model
    set_primary_key :route_id

    one_to_many :trips, :key => :route_id

    def live!(vehicles)
      class << self
        attr_reader :vehicles
      end

      @vehicles = vehicles
    end

    def predictions!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.predictions!(options.merge({:route => self.route_id.downcase}))
      else
        CTA::BusTracker.predictions!(options.merge({:route => self.route_id}))
      end
    end

    def locations!(options = {})
      if CTA::Train::L_ROUTES.keys.include?(self.route_id.downcase)
        CTA::TrainTracker.locations!(options.merge({:routes => self.route_id.downcase}))
      else
        raise "CTA BusTracker has no direct analog of the TrainTracker locations api. Try predictions instead."
      end
    end

    def status!
      CTA::CustomerAlerts.status!(:routes => self.route_id).routes.first
    end

    def alerts!
      CTA::CustomerAlerts.alerts!(:route => self.route_id).alerts
    end
  end
end
