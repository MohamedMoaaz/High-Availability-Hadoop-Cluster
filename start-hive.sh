#!/bin/bash
echo "put files"
if [[ "$HOSTNAME" == "hive-metastore" ]]; then
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp/hive
  hdfs dfs -mkdir -p /tez
  hdfs dfs -put -f $TEZ_HOME/share/* /tez/
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp/hive
  hdfs dfs -chmod g+w /tez
echo "schema"
  if [ ! -f /usr/local/hive/metastore_schema_initialized ]; then
      schematool -dbType postgres -initSchema
      touch /usr/local/hive/metastore_schema_initialized
  fi
  echo "start service"
  hive --service metastore &
fi

if [[ "$HOSTNAME" == "hive-server2" ]]; then
  hive --service hiveserver2 &
  mkdir /app
  sudo service cron start
  echo export PATH=/usr/local/hive/bin:/usr/local/hadoop/bin:/usr/bin:/bin >> /app/hive_cron.sh
  echo "beeline -u jdbc:hive2://localhost:10000 -n hive -p hive -f /app/test.sql >> /app/hive_cron.log 2>&1" >> /app/hive_cron.sh
  chmod +x /app/hive_cron.sh 
  echo "* * * * * /app/hive_cron.sh" | crontab -
fi
tail -f /dev/null