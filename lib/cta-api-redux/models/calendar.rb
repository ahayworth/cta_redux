module CTA
  class Calendar < Sequel::Model(:calendar)
    set_primary_key :service_id

    one_to_many :trips, :key => :service_id
  end
end
