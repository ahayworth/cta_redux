require "cta_redux/version"
require "sequel"
require "sqlite3"
require "faraday"
require "faraday_middleware"
require "multi_xml"
require "zlib"

module CTA
  base_path = File.expand_path("..", __FILE__)
  data_dir = File.join(File.expand_path("../..", __FILE__), 'data')

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

  db_filename = File.join(data_dir, 'cta-gtfs.db')

  # First run
  if !File.exists?(db_filename)
    dbf = File.open(db_filename, 'wb')
    Zlib::GzipReader.open("#{db_filename}.gz") do |gz|
      dbf.puts gz.read
    end
    dbf.close
  end

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
