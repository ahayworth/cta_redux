require "cta_redux/version"
require "sequel"
require "sqlite3"
require "faraday"
require "faraday_middleware"
require "multi_xml"

module CTA
  base_path = File.expand_path("..", __FILE__)

  require "#{base_path}/cta_redux/faraday_middleware/bus_tracker_parser.rb"
  require "#{base_path}/cta_redux/faraday_middleware/train_tracker_parser.rb"
  require "#{base_path}/cta_redux/faraday_middleware/customer_alerts_parser.rb"
  require "#{base_path}/cta_redux/faraday_middleware/simple_cache.rb"

  require "#{base_path}/cta_redux/api/api_response.rb"
  require "#{base_path}/cta_redux/api/bus_tracker.rb"
  require "#{base_path}/cta_redux/api/train_tracker.rb"
  require "#{base_path}/cta_redux/api/customer_alerts.rb"

  require "#{base_path}/cta_redux/train_tracker.rb"
  require "#{base_path}/cta_redux/bus_tracker.rb"
  require "#{base_path}/cta_redux/customer_alerts.rb"
  require "#{base_path}/cta_redux/version.rb"


  data_dir = File.join(File.expand_path("../..", __FILE__), 'data')
  db_filename = File.join(data_dir, 'cta-gtfs.db')
  DB = Sequel.sqlite(:database => db_filename, :readonly => true)

  require "#{base_path}/cta_redux/models/agency.rb"
  require "#{base_path}/cta_redux/models/calendar.rb"
  require "#{base_path}/cta_redux/models/route.rb"
  require "#{base_path}/cta_redux/models/shape.rb"
  require "#{base_path}/cta_redux/models/stop.rb"
  require "#{base_path}/cta_redux/models/stop_time.rb"
  require "#{base_path}/cta_redux/models/transfer.rb"
  require "#{base_path}/cta_redux/models/trip.rb"

  require "#{base_path}/cta_redux/models/train.rb"
  require "#{base_path}/cta_redux/models/bus.rb"

end

class Array
  # Encloses the object with an array, if it is not already
  # @param object [Object] the object to enclose
  # @return [Array<Object>] the object, enclosed in an array
  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end
