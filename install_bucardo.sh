# NB: you need to have ubuntu 16.04 for install last version of bucardo, with 14.04 apt installs version 4.xx
apt-get update
apt-get install bucardo nano -y

mkdir /srv/bucardo
mkdir /var/run/bucardo


service postgresql start

su - postgres -c "psql postgres"  
SET session_replication_role = 'replica';  
CREATE EXTENSION plperl;  
CREATE USER bucardo WITH LOGIN SUPERUSER ENCRYPTED PASSWORD 'bucardo-runner';  
CREATE DATABASE bucardo;  
\q

export PGDATABASE=test_database
export PGHOST=bucardo-pg
export PGHOST2=bucardo-pg2
export PGPORT=5432
export PGSUPERUSER=postgres
export PGSUPERPASS=test
export BUCARDOUSER=bucardo
export BUCARDOPASS=bucardo-runner

echo "127.0.0.1:5432:bucardo:$BUCARDOUSER:$BUCARDOPASS
$PGHOST:$PGPORT:$PGDATABASE:$PGSUPERUSER:$PGSUPERPASS
$PGHOST2:$PGPORT:$PGDATABASE:$PGSUPERUSER:$PGSUPERPASS" >> $HOME/.pgpass  


echo "dbhost=127.0.0.1  
dbname=bucardo  
dbport=5432  
dbuser=$BUCARDOUSER" >> $HOME/.bucardorc

chmod 0600 $HOME/.pgpass  

bucardo install --quiet
3
bucardo
P


# ON THE FIRST HOST:
su postgres
psql
CREATE DATABASE test_database;
\q
exit
wget http://domain.com/latest.dump
pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d test_database latest.dump


# EXTRACT SCHEMA
pg_dump "host=$PGHOST port=$PGPORT dbname=$PGDATABASE user=$PGSUPERUSER" --schema-only > schema.sql  

# CREATE DB ON HOST 2
psql "host=$PGHOST2 port=$PGPORT dbname=postgres user=$PGSUPERUSER" -c "CREATE DATABASE $PGDATABASE;" 


# LOAD SCHEMA ON HOST 2
psql "host=$PGHOST2 port=$PGPORT dbname=$PGDATABASE user=$PGSUPERUSER" -f schema.sql  

# ADD DBs TO BUCARDO
bucardo add db host1 dbhost=$PGHOST dbport=$PGPORT dbname=$PGDATABASE dbuser=$PGSUPERUSER dbpass=$PGSUPERPASS
bucardo add db host2 dbhost=$PGHOST2 dbport=$PGPORT dbname=$PGDATABASE dbuser=$PGSUPERUSER dbpass=$PGSUPERPASS

# CREATE DB GROUP
bucardo add dbgroup mydbs host1:source host2:source

# CREATE SYNC
bucardo add sync mysync tables=all dbs=mydbs

# COPY DB DATA
pg_dump -U $PGSUPERUSER -h $PGHOST --data-only -N bucardo $PGDATABASE \
| PGOPTIONS='-c session_replication_role=replica' \
psql -U $PGSUPERUSER -h $PGHOST2 -d $PGDATABASE


# START BUCARDO (and sync)
bucardo start

# CHECK BUCARDO STATUS
bucardo status
bucardo status mysync
bucardo list dbs


# BUCARDO LOGS
tail -f /var/log/bucardo/log.bucardo



# Most big problems are:
# If a postgres instance go down bucardo change its state to "stalled" (after about 30-60 sec, It's not immediate).
# When this postgres instand come back online, for bucardo it's always "stalled", and it doesn't sync it.
# For avoid this, you have to launch a "bucardo restart", so the postgres instance is set again as "online" and synched.
# Also, If you want to change a table structure or add a new one, this is not synched between DBs, and bucardo don't detect it.


# useful links:
# https://www.compose.io/articles/using-bucardo-5-3-to-migrate-a-live-postgresql-database/
# http://blog.endpoint.com/search?q=bucardo&updated-max=2015-01-28T08:00:00-05:00&max-results=20&start=8&by-date=true
# http://justatheory.com/computers/databases/postgresql/bootstrap-bucardo-mulitmaster.html
