module CTA
  class StopTime < Sequel::Model
    many_to_one :trip, :key => :trip_id
    many_to_one :stop, :key => :stop_id
  end
end
