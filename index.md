---
layout: default
title: "CTA Redux"
---

<p class='lead'>
Good data is useless if it's hard to access. <br />
<a href='http://github.com/ahayworth/cta_redux' target='_blank'>CTA Redux</a> takes obscure data from the
<a href='http://www.transitchicago.com/' target='_blank'>Chicago Transit Authority</a> and makes it easy to use.
</p>

```ruby
require 'cta_redux'
CTA::TrainTracker.key = 'foo'

# Access GTFS data with the power of Sequel
api_response = CTA::Stop.first(:stop_name => "Armitage").predictions!

api_response.predictions.each do |p|
  puts "A #{p.direction} #{p.route.long_name} train will be arriving at Armitage in #{p.minutes} minutes."
end
```
```bash
$ ruby ~/test.rb
A Loop-bound Brown Line train will be arriving at Armitage in 3 minutes.
A Loop-bound Brown Line train will be arriving at Armitage in 12 minutes.
```

### Features

* Clean, consistent access to the <a href='http://www.transitchicago.com/developers/traintracker.aspx' target='_blank'>TrainTracker</a>,
  <a href='http://www.transitchicago.com/developers/bustracker.aspx' target='_blank'>BusTracker</a>, and
  <a href='http://www.transitchicago.com/developers/alerts.aspx' target='_blank'>Customer Alerts</a> APIs.

* Powerful integration with <a href='http://www.transitchicago.com/developers/gtfs.aspx' target='_blank'>GTFS/Scheduled Service Data</a>,
  through the <a href='http://sequel.jeremyevans.net/' target='_blank'>Sequel ORM</a>.

* Built-in support for caching API responses via <a href='https://github.com/lostisland/faraday' target='_blank'>Faraday</a>. Use the
  built-in cache, or replace it with anything that quacks like an ActiveSupport::Cache.
