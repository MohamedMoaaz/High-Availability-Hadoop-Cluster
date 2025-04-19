#!/bin/bash

echo "[INFO] Starting SSH service..."
sudo service ssh start

if hostname | grep -q "master"; then
  echo "[INFO] Detected master node: $(hostname)"

  echo "[INFO] Starting JournalNode..."
  hdfs --daemon start journalnode

  echo $(hostname | tail -c 2) > /usr/local/zookeeper/data/myid

  echo "[INFO] Starting ZooKeeper server..."
  /usr/local/zookeeper/bin/zkServer.sh start

  if [[ $(hostname | tail -c 2) == "1" ]]; then
    if [ ! -d /usr/local/hadoop/hdfs/namenode/current ]; then
      echo "[INFO] Formatting NameNode on master1..."
      hdfs namenode -format -force -nonInteractive
      hdfs zkfc -formatZK -force -nonInteractive
    else
      echo "[INFO] Skipping NameNode formatting - already formatted."
    fi

    echo "[INFO] Starting NameNode as ACTIVE..."
    hdfs --daemon start namenode

  else
    echo "[INFO] Bootstrapping standby NameNode on $(hostname)..."
    if [ ! -d /usr/local/hadoop/hdfs/namenode/current ]; then
      echo "[INFO] Formatting NameNode on standby node..."
      hdfs namenode -bootstrapStandby

    else
      echo "[INFO] Skipping NameNode formatting - already formatted."
    fi
    echo "[INFO] Starting Standby NameNode on $(hostname)..."
    hdfs --daemon start namenode
  fi

  echo "[INFO] Starting ZKFC on $(hostname)..."
  hdfs --daemon start zkfc

  echo "[INFO] Starting ResourceManager on $(hostname)..."
  yarn --daemon start resourcemanager

  start-all.sh
elif [[ $HOSTNAME == "worker" ]]; then 
  sleep 30
  echo "[INFO] Detected worker node: $(hostname)"
  echo "[INFO] Starting DataNode on $(hostname)..."
  hdfs --daemon start datanode

  echo "[INFO] Starting NodeManager on $(hostname)..."
  yarn --daemon start nodemanager
elif [[ $HOSTNAME == "hive" ]]; then
sleep 60
  echo "Starting Hive services on $HOSTNAME"
  hdfs dfs -mkdir -p /user/hive/warehouse
  hdfs dfs -mkdir -p /tmp/hive
  hdfs dfs -chmod g+w /user/hive/warehouse
  hdfs dfs -chmod g+w /tmp/hive

  $HIVE_HOME/bin/schematool -initSchema -dbType postgres
  $HIVE_HOME/bin/hive --service metastore > $HIVE_HOME/metastore.log 2>&1 &
  $HIVE_HOME/bin/hiveserver2 > $HIVE_HOME/hiveserver2.log 2>&1 &
fi

sleep infinity