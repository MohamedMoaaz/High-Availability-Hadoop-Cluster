FROM ubuntu:22.04 AS hadoop-base

RUN apt update -y && apt upgrade -y && \
    apt install -y openjdk-8-jdk ssh sudo curl wget

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV HADOOP_HOME=/usr/local/hadoop
ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$ZOOKEEPER_HOME/bin:$PATH

RUN addgroup hadoop && \
    adduser --disabled-password --ingroup hadoop hadoop && \
    echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME && \
    rm /tmp/hadoop-3.3.6.tar.gz

ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin $ZOOKEEPER_HOME && \
    mkdir $HADOOP_HOME/../zookeeper/data/ && \
    chown -R hadoop:hadoop $ZOOKEEPER_HOME && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz

RUN mkdir -p /usr/local/hadoop/hdfs/namenode /usr/local/hadoop/hdfs/datanode /usr/local/hadoop/journal \
    && mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop /usr/local/hadoop

USER hadoop
RUN ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 600 ~/.ssh/authorized_keys

WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hadoop-config/ $HADOOP_HOME/etc/hadoop/
COPY --chown=hadoop:hadoop zoo.cfg $ZOOKEEPER_HOME/conf/
COPY --chown=hadoop:hadoop --chmod=777 start-hadoop.sh /home/hadoop/

ENTRYPOINT ["bash", "-c", "./start-hadoop.sh"]

FROM hadoop-base as hive-base

ENV HIVE_HOME=/usr/local/hive
ENV TEZ_HOME=/usr/local/tez
ENV PATH=$HIVE_HOME/bin:$TEZ_HOME/bin:$PATH
ENV HADOOP_CLASSPATH=$HADOOP_HOME/etc/hadoop:$TEZ_HOME/lib/*:$TEZ_HOME/conf:$TEZ_HOME/*

USER root

ADD https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-hive-4.0.1-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-hive-4.0.1-bin $HIVE_HOME && \
    chown -R hadoop:hadoop $HIVE_HOME


ADD https://archive.apache.org/dist/tez/0.10.4/apache-tez-0.10.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-tez-0.10.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-tez-0.10.4-bin $TEZ_HOME && \
    chown -R hadoop:hadoop $TEZ_HOME


ADD https://jdbc.postgresql.org/download/postgresql-42.6.0.jar /tmp/
RUN mv /tmp/postgresql-42.6.0.jar $HIVE_HOME/lib/ && \
    chown hadoop:hadoop $HIVE_HOME/lib/postgresql-42.6.0.jar

USER hadoop
WORKDIR /home/hadoop
COPY --chown=hadoop:hadoop hive-config/hive-site.xml $HIVE_HOME/conf/
COPY --chown=hadoop:hadoop hive-config/tez-site.xml $TEZ_HOME/conf/
COPY --chown=hadoop:hadoop --chmod=777 start-hive.sh /home/hadoop/

# ENTRYPOINT ["bash", "-c", "./start-hive.sh"]