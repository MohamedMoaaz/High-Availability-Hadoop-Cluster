# ================================
# Dockerfile for Hadoop HA Cluster Node
# ================================
FROM ubuntu:22.04

# System updates and essentials
RUN apt update -y && \
    apt upgrade -y && \
    apt install -y openjdk-8-jdk ssh sudo curl

# Environment setup
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

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

# SSH key setup for passwordless SSH
RUN mkdir -p /home/hadoop/.ssh && \
    chown -R hadoop:hadoop /home/hadoop/.ssh

RUN mkdir -p /usr/local/hadoop/hdfs/namenode /usr/local/hadoop/hdfs/datanode /usr/local/hadoop/journal \
    && chown -R hadoop:hadoop /usr/local/hadoop/hdfs /usr/local/hadoop/journal

USER hadoop
RUN ssh-keygen -t rsa -P "" -f /home/hadoop/.ssh/id_rsa && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chmod 600 /home/hadoop/.ssh/authorized_keys

USER root
RUN echo "hadoop ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory for the hadoop user
WORKDIR /home/hadoop

# Copy configuration and startup scripts
COPY hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
COPY yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml
COPY workers $HADOOP_HOME/etc/hadoop/workers
COPY zoo.cfg $HADOOP_HOME/../zookeeper/conf/zoo.cfg
COPY start.sh /home/hadoop/start.sh

# Make startup script executable
RUN chmod +x /home/hadoop/start.sh
RUN chown hadoop:hadoop /home/hadoop/start.sh


# Entry point to start Hadoop and related services
USER hadoop
ENTRYPOINT ["bash", "-c", "./start.sh"]

