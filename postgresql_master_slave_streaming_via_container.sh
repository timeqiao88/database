1. creation of primary and slave container network
docker network create --driver bridge --subnet 192.168.10.0/24 pg_network


2. start primary docker container add your static ip for that container primary and slave
docker run --name primary \
 -e POSTGRES_USER=postgres \
 -e POSTGRES_PASSWORD=password \
 -v /data/pgsql/master:/var/lib/postgresql/data \
 --network pg_network \
 --ip 192.168.10.10 \
 -p 5532:5432 \
 -d postgres:14 \
 postgres -c wal_level=replica -c max_wal_senders=3 -c max_replication_slots=3 -c hot_standby=on

3. modify /data/pgsql/master/pg_hba.conf add the following two lines
host    replication          postgres   0.0.0.0/0 trust
host    all                  all        0.0.0.0/0 trust

4. stop primay container
docker stop primary 



5. start replica docker container 
docker run --name replica \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -v /data/pgsql/slave:/var/lib/postgresql/data \
  --network pg_network \
  --ip 192.168.10.11 \
  -p 5533:5432 \
  -d postgres:14




6. Create a Replication Slot on the Master container postgres user
psql -U postgres -c  "SELECT * FROM pg_create_physical_replication_slot('replica1');"

7. backup the full database on primary 
pg_basebackup -U postgres -D /tmp/base_backup -Ft -z -X stream -P 

8. copy the primary backup to host /tmp path
docker cp primary:/tmp/base_backup /tmp

9. stop replica container
docker stop replica

10.  remove all datafile from replica data path
rm -rf /data/pgsql/slave/*


11. extract the backup from host to replica data and wal path
cd /tmp/base_backup
tar zxvf base.tar.gz  -C /data/pgsql/slave/
tar zxvf pg_wal.tar.gz  -C /data/pgsql/slave/pg_wal

12. Create standby.signal File: On your host machine, create the standby.signal file to enable standby mode at /data/pgsql/slave to make it available to docker container:
touch /data/pgsql/slave/standby.signal

13. Set up primary_conninfo from replica
echo "primary_slot_name = 'replica1'" |  tee -a /data/pgsql/slave/postgresql.conf
echo "primary_conninfo = 'host=192.168.10.10 port=5432 user=postgres password=password application_name=replica1'" |  tee -a /data/pgsql/slave/postgresql.conf

14. start replica container
docker stop replica

15. check the primary status:
apk add postgresql-client
psql -p 5532 -h 192.168.0.28 -U postgres
postgres=# SELECT * FROM pg_replication_slots;
 slot_name | plugin | slot_type | datoid | database | temporary | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn | wal_status | safe_wal_size | two_phase 
-----------+--------+-----------+--------+----------+-----------+--------+------------+------+--------------+-------------+---------------------+------------+---------------+-----------
 replica1  |        | physical  |        |          | f         | t      |         62 |      |              | 0/3000148   |                     | reserved   |               | f
(1 row)


16. check the slave status: 
psql -p 5533 -h 192.168.0.28 -U postgres

SELECT * FROM pg_stat_replication;

SELECT * FROM pg_stat_wal_receiver;

32 | streaming | 0/3000000         |                 1 | 0/3000148   | 0/3000148   |            1 | 2024-12-30 08:31:53.202157+00 | 2024-12-30 08:31:53.20224+00 | 0/3000148      | 2024-12-30 08:23:52.126112+00 | replica1  | 192.168.10.10 |        5432 | 
user=postgres password=******** channel_binding=prefer dbname=replication host=192.168.10.10 port=5432 application_name=replica1 fallback_application_name=walreceiver sslmode=prefer sslnegotiation=postgres sslcompression=0 sslcertmode=allow sslsni=1 ssl_mi
n_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres gssdelegation=0 target_session_attrs=any load_balance_hosts=disable
