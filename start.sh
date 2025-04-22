#!/bin/bash
sudo service ssh start
if hostname | grep -q "master"; then
  hdfs --daemon start journalnode
  echo $(hostname | tail -c 2) > /usr/local/zookeeper/data/myid
  zkServer.sh start
  if [[ $(hostname | tail -c 2) == "1" ]]; then
    if [ ! -d /usr/local/hadoop/hdfs/namenode/current ]; then
      hdfs namenode -format -force -nonInteractive
      hdfs zkfc -formatZK -force -nonInteractive
    fi
    hdfs --daemon start namenode
  else
    if [ ! -d /usr/local/hadoop/hdfs/namenode/current ]; then
      hdfs namenode -bootstrapStandby
    fi
    hdfs --daemon start namenode
  fi
  hdfs --daemon start zkfc
  yarn --daemon start resourcemanager
  start-all.sh
elif [[ $HOSTNAME == "worker" ]]; then 
  sleep 30
  hdfs --daemon start datanode
  yarn --daemon start nodemanager

# elif [[ $HOSTNAME == "hive-metastore" ]]; then
# sleep 60
#   echo "Starting Hive services on $HOSTNAME"
#   hdfs dfs -mkdir -p /user/hive/warehouse
#   hdfs dfs -mkdir -p /tmp/hive
#   hdfs dfs -chmod g+w /user/hive/warehouse
#   hdfs dfs -chmod g+w /tmp/hive

#   $HIVE_HOME/bin/schematool -initSchema -dbType postgres
#   $HIVE_HOME/bin/hive --service metastore &
# elif [[ $HOSTNAME == "hive-server2" ]]; then
#   sleep 90
#   echo "Starting Hive services on $HOSTNAME"
#   hiveserver2 &
fi

sleep infinity