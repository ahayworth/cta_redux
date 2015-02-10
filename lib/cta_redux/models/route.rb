module CTA
  class Route < Sequel::Model
    set_primary_key :route_id

    one_to_many :trips, :key => :route_id
  end
end
