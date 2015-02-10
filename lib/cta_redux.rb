require "cta_redux/version"
require "sequel"
require "sqlite3"
require "faraday"
require "faraday_middleware"
require "multi_xml"
require "zlib"

module CTA
  Dir.glob("cta_redux/faraday_middleware/*") { |lib| require lib }
  Dir.glob("cta_redux/api/*") { |lib| require lib }
  require "cta_redux/train_tracker.rb"
  require "cta_redux/bus_tracker.rb"
  require "cta_redux/customer_alerts.rb"

  data_dir = File.join(File.expand_path("../..", __FILE__), 'data')
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

  Dir.glob("cta_redux/models/*") do |lib|
    next if lib == "cta_redux/models/train.rb" || lib == "cta_redux/models/bus.rb"
    require lib
  end
  require "cta_redux/models/train.rb"
  require "cta_redux/models/bus.rb"
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
