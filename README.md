# cta_redux

[![Build Status](https://travis-ci.org/ahayworth/cta_redux.svg?branch=master)](https://travis-ci.org/ahayworth/cta_redux)

The CTA (http://www.transitchicago.com) provides a wealth of information for developers, but it's hard to access, inconsistent, and there are no official clients. CTA Redux is an easy to use, comprehensive client for that data.

This gem combines GTFS data with live API responses to create a consistent view of CTA vehicles and status.

Examples:

```ruby
require 'cta_redux'

CTA::TrainTracker.key = 'foo'
CTA::BusTracker.key   = 'bar'

# Pick a random stop on the brown line
stop = CTA::Route[:brown].stops.all.sample

routes = []
stop.predictions!.predictions.sort_by(&:seconds).each do |prd|
  routes << prd.route.route_id
  puts "A #{prd.direction} #{prd.route.route_long_name} " +
    "train will be arriving at #{stop.stop_name} in #{prd.minutes} minutes."
end

# Pick a random stop on the 8-Halsted route
stop = CTA::Route["8"].stops.all.sample
stop.predictions!.predictions.sort_by(&:seconds).each do |prd|
  routes << prd.route.route_id
  puts "A(n) #{prd.route.route_id}-#{prd.route.route_long_name} will be " +
    "arriving at #{stop.stop_name} in #{prd.minutes} minutes."
end

CTA::CustomerAlerts.alerts!(:routes => routes.uniq).alerts.each do |alert|
  puts "Alert: #{alert.short_description}"
end
```

More information is available at (http://www.rubydoc.info/github/ahayworth/cta_redux)
