module CTA
  class Stop < Sequel::Model
    set_primary_key :stop_id

    one_to_many :child_stops, :class => self, :key => :parent_station
    many_to_one :parent_stop, :class => self, :key => :parent_station

    one_to_many :transfers_from, :class => 'CTA::Transfer', :key => :from_stop_id
    one_to_many :transfers_to, :class => 'CTA::Transfer', :key => :to_stop_id

    many_to_many :trips, :left_key => :stop_id, :right_key => :trip_id, :join_table => :stop_times
  end
end
