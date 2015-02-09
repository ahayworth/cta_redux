#!/usr/bin/env ruby

require 'sqlite3'
require 'csv'

def usage
  "Usage: gtfs_to_sqlite.rb input_file output_db"
end

abort usage unless ARGV.size == 2

base_path = File.expand_path("..", __FILE__)
input_file = File.join(base_path, ARGV[0])
output_db  = File.join(base_path, ARGV[1])
puts input_file

table = input_file.split(File::SEPARATOR).last.gsub(".txt", "")

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
    stmt = "CREATE TABLE #{table} (#{row.headers.join(',')})"
    db.execute(stmt)
    first_row = false
    headers = row.headers
  end

  stmt = "INSERT INTO #{table} (#{row.headers.join(',')}) VALUES (#{row.headers.map { '?' }.join(',')})"
  db.execute(stmt, *row.fields)
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
