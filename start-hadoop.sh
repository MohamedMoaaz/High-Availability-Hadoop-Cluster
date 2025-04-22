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
elif [[ $HOSTNAME == "worker" ]]; then 
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi
sleep infinity