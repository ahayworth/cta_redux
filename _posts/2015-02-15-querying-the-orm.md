---
layout: page
title: "Querying the ORM"
category: doc
date: 2015-02-15 23:39:19
order: 2
---

The ORM underlying CTA Redux is none other than <a href='http://sequel.jeremyevans.net/' target='_blank'>Sequel</a>,
which exposes a rich and powerful syntax for queries. CTA Redux ships with a read-only SQLite3 database of GTFS
data, indexed to be reasonably performant. Each table is mapped to a <a href='http://sequel.jeremyevans.net/rdoc/classes/Sequel/Model.html' target='_blank'>Sequel::Model</a>.

Selecting a model by primary key:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> CTA::Route["22"]
=> #<CTA::Route @values={:route_id=>"22", :route_short_name=>"22", :route_long_name=>"Clark", :route_type=>3, :route_url=>"http://www.transitchicago.com/riding_cta/busroute.aspx?RouteId=181", :route_color=>nil, :route_text_color=>nil}>
```

Finding a model with a chained condition:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> CTA::Route.where(:route_id => "Red").or(:route_id => "Blue")
=> #<Sequel::SQLite::Dataset: "SELECT * FROM `routes` WHERE ((`route_id` = 'Red') OR (`route_id` = 'Blue'))">
[3] pry(main)> CTA::Route.where(:route_id => "Red").or(:route_id => "Blue").all
=> [#<CTA::Route @values={:route_id=>"Blue", :route_short_name=>"", :route_long_name=>"Blue Line", :route_type=>1, :route_url=>"http://www.transitchicago.com/riding_cta/systemguide/blueline.aspx", :route_color=>"00A1DE", :route_text_color=>"FFFFFF"}>,
 #<CTA::Route @values={:route_id=>"Red", :route_short_name=>"", :route_long_name=>"Red Line", :route_type=>1, :route_url=>"http://www.transitchicago.com/riding_cta/systemguide/redline.aspx", :route_color=>"C60C30", :route_text_color=>"FFFFFF"}>]
 ```

Find all rail routes except for the Red, Blue, and Pink lines:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> CTA::Route.exclude(:route_id => ["Red", "Blue", "Pink"]).where(:route_type => 1)
=> #<Sequel::SQLite::Dataset: "SELECT * FROM `routes` WHERE ((`route_id` NOT IN ('Red', 'Blue', 'Pink')) AND (`route_type` = 1))">
[3] pry(main)> CTA::Route.exclude(:route_id => ["Red", "Blue", "Pink"]).where(:route_type => 1).all
=> [#<CTA::Route @values={:route_id=>"P", :route_short_name=>"", :route_long_name=>"Purple Line", :route_type=>1, :route_url=>"http://www.transitchicago.com/riding_cta/systemguide/purpleline.aspx", :route_color=>"522398", :route_text_color=>"FFFFFF"}>,
 #<CTA::Route @values={:route_id=>"Y", :route_short_name=>"", :route_long_name=>"Yellow Line", :route_type=>1, :route_url=>"http://www.transitchicago.com/riding_cta/systemguide/yellowline.aspx", :route_color=>"F9E300", :route_text_color=>"000000"}>,
...
```

Searching for something really esoteric:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> CTA::Stop.distinct.where(Sequel.like(:stop_name, "%Jackson%")).limit(3)
=> #<Sequel::SQLite::Dataset: "SELECT DISTINCT * FROM `stops` WHERE (`stop_name` LIKE '%Jackson%' ESCAPE '\\') LIMIT 3">
[3] pry(main)> CTA::Stop.distinct.where(Sequel.like(:stop_name, "%Jackson%")).limit(3).select_map(:stop_name)
=> ["Jackson & Austin Terminal", "5900 W Jackson", "Jackson & Menard"]
```

Recommended reading:

* <a href='http://sequel.jeremyevans.net/rdoc/files/doc/querying_rdoc.html' target='_blank'>Querying in Sequel</a>

* <a href='http://sequel.jeremyevans.net/rdoc/files/doc/cheat_sheet_rdoc.html' target='_blank'>Sequel Cheat Sheet</a>

* <a href='http://sequel.jeremyevans.net/rdoc/files/doc/active_record_rdoc.html' target='_blank'>Sequel for ActiveRecord Users</a>

* <a href='http://www.transitchicago.com/developers/gtfs.aspx' target='_blank'>CTA GTFS Information</a>

* <a href='https://developers.google.com/transit/gtfs/reference?csw=1' target='_blank'>GTFS Specification</a>
