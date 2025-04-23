#!/bin/bash
sudo service ssh start
echo "$MYID" > /usr/local/zookeeper/data/myid

if [[ "$ROLE" == "master" ]]; then
  hdfs --daemon start journalnode
  zkServer.sh start
  if [[ "$MYID" == "1" ]]; then
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
elif [[ "$ROLE" == "worker" ]]; then 
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi
tail -f /dev/null