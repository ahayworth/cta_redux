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
  Dir.glob("#{base_path}/cta_redux/faraday_middleware/*") { |lib| require lib }
  Dir.glob("#{base_path}/cta_redux/api/*") { |lib| require lib }
  require "#{base_path}/cta_redux/train_tracker.rb"
  require "#{base_path}/cta_redux/bus_tracker.rb"
  require "#{base_path}/cta_redux/customer_alerts.rb"

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

  Dir.glob("#{base_path}/cta_redux/models/*") do |lib|
    next if lib =~ /train/ || lib =~ /bus/
    require lib
  end

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
