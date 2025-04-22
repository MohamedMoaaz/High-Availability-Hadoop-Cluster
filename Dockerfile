# ================================
# Dockerfile for Hadoop HA Cluster Node with Hive (MapReduce instead of Tez)
# ================================
FROM ubuntu:22.04

# System updates and essentials
RUN apt update -y && \
    apt upgrade -y && \
    apt install -y openjdk-8-jdk ssh sudo curl wget

# Environment setup
ENV HADOOP_HOME=/usr/local/hadoop
ENV HIVE_HOME=/usr/local/hive
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64

# Create hadoop group and user
RUN addgroup hadoop && \
    adduser --disabled-password --ingroup hadoop hadoop

# Download and install Hadoop
ADD https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz /tmp
RUN tar -xzf /tmp/hadoop-3.3.6.tar.gz -C /usr/local/ && \
    mv /usr/local/hadoop-3.3.6 $HADOOP_HOME && \
    chown -R hadoop:hadoop $HADOOP_HOME && \
    rm /tmp/hadoop-3.3.6.tar.gz

# Download and install ZooKeeper
ADD https://dlcdn.apache.org/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-zookeeper-3.8.4-bin.tar.gz -C /usr/local && \
    mv /usr/local/apache-zookeeper-3.8.4-bin $HADOOP_HOME/../zookeeper && \
    mkdir $HADOOP_HOME/../zookeeper/data/ && \
    chown -R hadoop:hadoop $HADOOP_HOME/../zookeeper && \
    rm /tmp/apache-zookeeper-3.8.4-bin.tar.gz

# Install Apache Hive (using version 4.0.1)
ADD https://dlcdn.apache.org/hive/hive-4.0.1/apache-hive-4.0.1-bin.tar.gz /tmp/
RUN tar -xzf /tmp/apache-hive-4.0.1-bin.tar.gz -C /usr/local/ && \
    mv /usr/local/apache-hive-4.0.1-bin $HIVE_HOME && \
    chown -R hadoop:hadoop $HIVE_HOME && \
    rm /tmp/apache-hive-4.0.1-bin.tar.gz

# Install PostgreSQL JDBC driver and place it in Hive lib
ADD https://jdbc.postgresql.org/download/postgresql-42.6.0.jar /tmp/
RUN mv /tmp/postgresql-42.6.0.jar $HIVE_HOME/lib/ && \
    chown hadoop:hadoop $HIVE_HOME/lib/postgresql-42.6.0.jar

# SSH key setup for passwordless SSH
RUN mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop/.ssh

# Set up Hadoop directories
RUN mkdir -p /usr/local/hadoop/hdfs/namenode /usr/local/hadoop/hdfs/datanode /usr/local/hadoop/journal \
    && chown -R hadoop:hadoop /usr/local/hadoop/hdfs /usr/local/hadoop/journal

# Generate SSH keys for the hadoop user
USER hadoop
RUN ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 600 /home/hadoop/.ssh/authorized_keys

# Allow passwordless sudo for hadoop user
USER root
RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory for the hadoop user
WORKDIR /home/hadoop

# Copy configuration and startup scripts
COPY config/* $HADOOP_HOME/etc/hadoop/
COPY zoo.cfg $HADOOP_HOME/../zookeeper/conf/zoo.cfg
COPY start.sh /home/hadoop/start.sh
COPY hive-site.xml $HIVE_HOME/conf/hive-site.xml

# Make startup script executable
RUN chmod +x /home/hadoop/start.sh
RUN chown hadoop:hadoop /home/hadoop/start.sh

ENV ZOOKEEPER_HOME=/usr/local/zookeeper
ENV PATH=$ZOOKEEPER_HOME/bin:$PATH
# Entry point to start Hadoop and related services
USER hadoop
ENTRYPOINT ["bash", "-c", "./start.sh"]