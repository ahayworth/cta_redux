---
layout: page
title: "Getting Started"
category: doc
date: 2015-02-15 22:14:59
order: 1
---

To get started with either the TrainTracker or BusTracker APIs, you'll need to get an API key from the CTA:

* TrainTracker: http://www.transitchicago.com/developers/traintrackerapply.aspx

* BusTracker: http://www.transitchicago.com/developers/bustracker.aspx

Use of the Customer Alerts API does not require an API key.

After you obtain an API key, using CTA Redux is simple. CTA Redux is, at its heart, an
ORM on top of the GTFS/Scheduled Service data from the CTA. Certain objects tie into the
CTA API to augment models with live data.

For example, here we search for the State/Lake L stop, and then ask the API for arrival predictions:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> CTA::TrainTracker.key = 'foo';
[3] pry(main)> state_and_lake = CTA::Stop.first(:stop_name => "State/Lake")
=> #<CTA::Stop @values={:stop_id=>30050, :stop_code=>nil, :stop_name=>"State/Lake", :stop_desc=>"", :stop_lat=>41.88574, :stop_lon=>-87.627835, :location_type=>0, :parent_station=>40260, :wheelchair_boarding=>false}>
[4] pry(main)> api_response = state_and_lake.predictions!;
[5] pry(main)> api_response.predictions[0].arrival_time
=> #<DateTime: 2015-02-15T23:20:17+00:00 ((2457069j,84017s,0n),+0s,2299161j)>
```

We could also search for a specific route, and then see if there are any service alerts for it:

```ruby
[1] pry(main)> require 'cta_redux';
[2] pry(main)> route = CTA::Route["22"]
=> #<CTA::Route @values={:route_id=>"22", :route_short_name=>"22", :route_long_name=>"Clark", :route_type=>3, :route_url=>"http://www.transitchicago.com/riding_cta/busroute.aspx?RouteId=181", :route_color=>nil, :route_text_color=>nil}>
[3] pry(main)> route.alerts!
=> [#<CTA::CustomerAlerts::Alert:0x007fce8696a918
  @alert_id=24585,
  @category=:planned,
  @headline="Temporary Bus Stop Relocation ",
  @id=24585,
  @impact="Bus Stop Relocation",
  @short_description="NB #22 bus stop on the southeast corner at Clark/Waveland will be temporarily relocated to the northeast corner at Clark/Waveland. ",
...
```

The following methods are all direct interfaces to the underlying CTA APIs:

```ruby
# BusTracker
CTA::BusTracker.bulletins!
CTA::BusTracker.directions!
CTA::BusTracker.patterns!
CTA::BusTracker.predictions!
CTA::BusTracker.routes!
CTA::BusTracker.stops!
CTA::BusTracker.time!
CTA::BusTracker.vehicles!

# TrainTracker
CTA::TrainTracker.arrivals!
CTA::TrainTracker.follow!
CTA::TrainTracker.locations!

# Customer Alerts
CTA::CustomerAlerts.alerts!
CTA::CustomerAlerts.status!
```

The following objects from the GTFS ORM are capable of returning live results:

```ruby
CTA::Bus.predictions!
CTA::Route.alerts!
CTA::Route.locations!
CTA::Route.predictions!
CTA::Route.status!
CTA::Stop.predictions!
CTA::Train.follow!
```

