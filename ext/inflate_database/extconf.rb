require 'mkmf'
require 'zlib'
data_dir = File.join(File.expand_path("../../..", __FILE__), 'data')
db_filename = File.join(data_dir, 'cta-gtfs.db')
if !File.exists?(db_filename)
  dbf = File.open(db_filename, 'wb')
  Zlib::GzipReader.open("#{db_filename}.gz") do |gz|
    dbf.puts gz.read
  end
  dbf.close
  File.unlink("#{db_filename}.gz")
end
puts `ls -lh #{db_filename}`

create_makefile "inflate_database/inflate_database"
