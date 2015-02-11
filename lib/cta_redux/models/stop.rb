module CTA
  class Stop < Sequel::Model
    set_primary_key :stop_id

    one_to_many :child_stops, :class => self, :key => :parent_station
    many_to_one :parent_stop, :class => self, :key => :parent_station

    one_to_many :transfers_from, :class => 'CTA::Transfer', :key => :from_stop_id
    one_to_many :transfers_to, :class => 'CTA::Transfer', :key => :to_stop_id

    many_to_many :trips, :left_key => :stop_id, :right_key => :trip_id, :join_table => :stop_times

    def stop_type
      if self.stop_id < 30000
        :bus
      elsif self.stop_id < 40000
        :rail
      else
        :parent_station
      end
    end

    def predictions!(options = {})
      if self.stop_type == :bus
        raise "E_NOTIMPLEMENTED"
      else
        if self.stop_type == :rail
          CTA::TrainTracker.predictions!(options.merge({:station => self.stop_id}))
        else
          CTA::TrainTracker.predictions!(options.merge({:parent_station => self.stop_id}))
        end
      end
    end
  end
end
