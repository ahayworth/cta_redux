module CTA
  class Trip < Sequel::Model
    L_ROUTES = ["Brn", "G", "Pink", "P", "Org", "Red", "Blue", "Y"]
    BUS_ROUTES = CTA::Trip.exclude(:route_id => L_ROUTES).select_map(:route_id).uniq
    plugin :single_table_inheritance,
           :route_id,
           :model_map => proc { |v|
             if L_ROUTES.include?(v)
               'CTA::Train'
             else
               'CTA::Bus'
             end
           },
           :key_map => proc { |klass|
             if klass.name == 'CTA::Train'
               L_ROUTES
             else
               BUS_ROUTES
             end
           }

    set_primary_key :trip_id

    many_to_one :calendar, :key => :service_id
    one_to_many :stop_times, :key => :trip_id

    many_to_one :route, :key => :route_id

    many_to_many :stops, :left_key => :trip_id, :right_key => :stop_id, :join_table => :stop_times
  end
end
