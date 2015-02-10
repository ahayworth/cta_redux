module CTA
  class Transfer < Sequel::Model
    many_to_one :from_stop, :class => 'CTA::Stop', :key => :from_stop_id
    many_to_one :to_stop, :class => 'CTA::Stop', :key => :to_stop_id
  end
end
