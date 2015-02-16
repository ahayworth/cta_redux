## Development Setup

1. Fork and clone the repo

2. ```bundle install```

3. Load your REPL like so: ```TRAVIS=true irb```. This ensures that the embedded SQLite database will be
   unzipped in the correct location for you. The TRAVIS environment variable is only necessary once for a fresh checkout.

4. Make changes, and submit a pull request. Open issues as needed.

If you make a substantial change to the code base, document your code and write some sort of test. Pull requests may be rejected without
at least some sort of smokescreen test.

Testing framework: rspec, builds set up on [travis-ci](https://travis-ci.org/ahayworth/cta_redux)

Documentation: yard, hosted on [rubydoc.info](http://www.rubydoc.info/github/ahayworth/cta_redux) and rubygems.org (for releases).


## Testing notes

Faraday has a stub interface that we use to stub out test data. The workflow usually goes something like:

1. Figure out what call you're making to the API

2. ```curl '<url for the api call>' > spec/stubs/some_response_name.xml

3. Add the appropriate stub in spec/{bus,train}_tracker_spec.rb or spec/customer_alerts_spec.rb

The Faraday stub interface is adequate, but picky - you must set up things with the *exact* URL - see the examples already there.


## How to reload CTA GTFS data

Note that this will take a long time - there are several million stop_time records. This should only be necessary
when the CTA releases new GTFS data, or if a manual correction to the data is needed.

1. cd data && curl 'http://www.transitchicago.com/downloads/sch_data/<latest file>' > gtfs.zip && unzip gtfs.zip

2. cd ../script && for i in `ls ../data/*.txt`; do echo $i; ./gtfs_to_sqlite.rb $i ../data/cta-gtfs.db; done

3. rm ../data/*{txt,htm,zip}

4. cd ../data && sqlite3 ./cta-gtfs.db

5. ANALYZE

6. VACUUM

7. gzip cta-gtfs.db

8. Commit / bump version / tag release / push / build and push gem
