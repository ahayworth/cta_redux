#!/usr/bin/env ruby

require 'sqlite3'
require 'csv'
require 'date'

KNOWN_COLUMN_TYPES = {
  "calendar" => {
    "service_id" => "INTEGER",
    "monday" => "BOOLEAN",
    "tuesday" => "BOOLEAN",
    "wednesday" => "BOOLEAN",
    "thursday" => "BOOLEAN",
    "friday" => "BOOLEAN",
    "saturday" => "BOOLEAN",
    "sunday" => "BOOLEAN",
    "start_date" => "DATE",
    "end_date" => "DATE"
  },
  "routes" => {
    "route_type" => "INTEGER"
  },
  "shapes" => {
    "shape_id" => "INTEGER",
    "shape_pt_lat" => "FLOAT",
    "shape_pt_lon" => "FLOAT",
    "shape_pt_sequence" => "INTEGER",
    "shape_dist_traveled" => "INTEGER"
  },
  "stop_times" => {
    "trip_id" => "INTEGER",
    # This would be nice to store as a native SQL type,
    # but ruby really has no notion of a time object w/o
    # an associated date, because ruby stores time as epoch.
    # so, in order to prevent ruby from attaching dates to our
    # stop_times, we just let it store naturally as a string.
    #"arrival_time" => "TIME",
    #"departure_time" => "TIME",
    "stop_id" => "INTEGER",
    "stop_sequence" => "INTEGER",
    "shape_dist_traveled" => "INTEGER"
  },
  "stops" => {
    "stop_id" => "INTEGER",
    "stop_code" => "INTEGER",
    "stop_lat" => "FLOAT",
    "stop_lon" => "FLOAT",
    "location_type" => "INTEGER",
    "parent_station" => "INTEGER",
    "wheelchair_boarding" => "BOOLEAN"
  },
  "transfers" => {
    "from_stop_id" => "INTEGER",
    "to_stop_id" => "INTEGER",
    "transfer_type" => "INTEGER"
  },
  "trips" => {
    "service_id" => "INTEGER",
    "trip_id" => "INTEGER",
    "direction_id" => "INTEGER",
    "block_id" => "INTEGER",
    "shape_id" => "INTEGER",
    "wheelchair_accessible" => "BOOLEAN"
  }
}

def usage
  "Usage: gtfs_to_sqlite.rb input_file output_db"
end

abort usage unless ARGV.size == 2

base_path = File.expand_path("..", __FILE__)
input_file = File.join(base_path, ARGV[0])
output_db  = File.join(base_path, ARGV[1])

table = input_file.split(File::SEPARATOR).last.gsub(".txt", "")

puts input_file
abort usage unless File.exists?(input_file)

db = SQLite3::Database.new(output_db)

first_row = true
n = 0
headers = nil

print "Loading"
CSV.foreach(input_file, :headers => true) do |row|
  if n % 100 == 0
    print "."
  end
  if n % 1000 == 0
    print n
  end

  if first_row
    columns = row.headers.map do |r|
      if KNOWN_COLUMN_TYPES[table] && KNOWN_COLUMN_TYPES[table][r]
        col = "#{r} #{KNOWN_COLUMN_TYPES[table][r]}"
      else
        col = r
      end
    end
    stmt = "CREATE TABLE #{table} (#{columns.join(',')})"
    db.execute(stmt)
    first_row = false
    headers = row.headers
  end

  stmt = "INSERT INTO #{table} (#{row.headers.join(',')}) VALUES (#{row.headers.map { '?' }.join(',')})"
  if row.headers.any? { |h| h =~ /date/ }
    fields = []
    row.headers.each_with_index do |header, index|
      if header =~ /date/
        fields << DateTime.parse(row.fields[index]).to_s
      else
        fields << row.fields[index]
      end
    end
  else
    fields = row.fields
  end
  db.execute(stmt, fields)
  n +=1
end

puts "\ndone"
puts "Creating indices..."
if headers
  headers.each do |h|
    if h =~ /_id/
      db.execute("CREATE INDEX #{table}_#{h}_index ON #{table} (#{h})")
    end
  end
end
