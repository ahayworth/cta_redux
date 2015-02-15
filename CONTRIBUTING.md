# Notes

When running the gem from a git checkout, you'll need to unzip the CTA database yourself.

````cd data && gunzip cta-gtfs.db.gz````

# How to reload CTA GTFS data

Note that this will take a long time - there are several million stop_time records.

1. cd data && curl 'http://www.transitchicago.com/downloads/sch_data/<latest file>' > gtfs.zip && unzip gtfs.zip

2. cd ../script && for i in `ls ../data/*.txt`; do echo $i; ./gtfs_to_sqlite.rb $i ../data/cta-gtfs.db; done

3. rm ../data/*{txt,htm,zip}

4. cd ../data && sqlite3 ./cta-gtfs.db

5. ANALYZE

6. VACUUM

7. gzip cta-gtfs.db

8. Commit / push / create release and gem

