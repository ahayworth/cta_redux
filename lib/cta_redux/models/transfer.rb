module CTA
  # A {http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html Sequel::Model}.
  # This corresponds to {https://developers.google.com/transit/gtfs/reference?csw=1#transfers_txt___Field_Definitions transfers.txt} in the
  # GTFS feed, though the CTA does not fully implement the standard.
  # @note Current columns: [:from_stop_id, :to_stop_id, :transfer_type]
  class Transfer < Sequel::Model
    # @!method from_stop
    #  The stop to transfer *from*
    #  @return [CTA::Stop]
    many_to_one :from_stop, :class => 'CTA::Stop', :key => :from_stop_id
    # @!method to_stop
    #  The stop to transfer *to*
    #  @return [CTA::Stop]
    many_to_one :to_stop, :class => 'CTA::Stop', :key => :to_stop_id
  end
end
