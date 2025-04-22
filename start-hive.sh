if [[ $HOSTNAME == "hive-metastore" ]]; then
sleep 60
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp/hive
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp/hive

  $HIVE_HOME/bin/schematool -initSchema -dbType postgres
  $HIVE_HOME/bin/hive --service metastore &
elif [[ $HOSTNAME == "hive-server2" ]]; then
  sleep 90
  hiveserver2 &
fi