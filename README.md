# cta-api-redux

# Reloading CTA GTFS data

Note that this will take a long time - there are several million stop_time records.

1. cd data && curl 'http://www.transitchicago.com/downloads/sch_data/<latest file>' > gtfs.zip && unzip gtfs.zip

2. cd ../script && for i in `ls ../data/*.txt`; do echo $i; ./gtfs_to_sqlite.rb $i ../data/cta-gtfs.db; done

3. rm ../data/*{txt,htm,zip}

4. mv ../data/cta-gtfs.db /tmp/

4. Commit / push / create release - make sure to upload the database from /tmp with the release

