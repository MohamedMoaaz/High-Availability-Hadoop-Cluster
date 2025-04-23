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
fi
tail -f /dev/null