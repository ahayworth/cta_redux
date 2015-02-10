require "cta-api-redux/version"
require "sequel"
require "sqlite3"
require "faraday"
require "faraday_middleware"
require "multi_xml"

module CTA
  Dir.glob("cta-api-redux/faraday_middleware/*") { |lib| require lib }
  Dir.glob("cta-api-redux/api/*") { |lib| require lib }
  require "cta-api-redux/train_tracker.rb"
  require "cta-api-redux/bus_tracker.rb"
  require "cta-api-redux/customer_alerts.rb"

  DB = "Not connected to a GTFS db!"

  def self.load_gtfs_data!(path)
    raise "Can't find #{path}" unless File.exists?(path)

    self.send(:remove_const, :DB)
    self.const_set(:DB, Sequel.sqlite(:database => path, :readonly => true))

    Dir.glob("cta-api-redux/models/*") do |lib|
      next if lib == "cta-api-redux/models/train.rb" || lib == "cta-api-redux/models/bus.rb"
      load lib
    end
    load "cta-api-redux/models/train.rb"
    load "cta-api-redux/models/bus.rb"
  end
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
