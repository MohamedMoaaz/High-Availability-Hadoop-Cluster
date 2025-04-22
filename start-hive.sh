#!/bin/bash

echo "[INFO] Starting Hive on node: $HOSTNAME"

# Wait for HDFS to become available
until hdfs dfs -test -d /; do
  echo "[WAIT] Waiting for HDFS to become ready..."
  sleep 3
done

if [[ "$HOSTNAME" == "hive-metastore" ]]; then
  echo "[INFO] Creating HDFS directories for Hive..."
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp/hive
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp/hive

  echo "[INFO] Uploading Tez to HDFS..."
  hdfs dfs -mkdir -p /apps/tez
  hdfs dfs -put -f $TEZ_HOME/* /apps/tez/

  # Check if schema is initialized
  echo "[INFO] Checking if Hive Metastore schema is initialized..."
  TABLE_EXISTS=$(PGPASSWORD=hivepassword psql -U hiveuser -h hive-postgres -d metastore -tAc "SELECT to_regclass('VERSION');")

  if [[ "$TABLE_EXISTS" != "version" ]]; then
    echo "[INFO] Initializing Hive Metastore schema..."
    $HIVE_HOME/bin/schematool -dbType postgres -initSchema
  else
    echo "[INFO] Hive Metastore schema already exists."
  fi

  echo "[INFO] Starting Hive Metastore..."
  $HIVE_HOME/bin/hive --service metastore &
fi

if [[ "$HOSTNAME" == "hive-server2" ]]; then
  echo "[INFO] Starting HiveServer2..."
  $HIVE_HOME/bin/hive --service hiveserver2 &
fi

# Keep container alive
tail -f /dev/null