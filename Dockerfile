FROM ubuntu:16.04

ENV SPARK_VERSION=2.4.0
ENV SPARK_HADOOP_VERSION=2.7
ENV HADOOP_VERSION=2.7.7
ENV HBASE_VERSION=2.0.5
ENV ZOOKEEPER_VERSION=3.5.5
ENV HIVE_VERSION=2.3.6
ENV FLINK_VERSION=1.7.2

ADD https://raw.githubusercontent.com/guilhem/apt-get-install/master/apt-get-install /usr/bin/
RUN chmod +x /usr/bin/apt-get-install

#install spark-bin-hadoop
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN  apt-get clean

RUN apt-get-install -y curl wget python3 python3-setuptools python3-pip openssh-server vim

COPY package /

WORKDIR /

RUN tar -xvzf spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz \
      && mv spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION} spark \
      && rm spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz

# extract & move hadoop & clean up
RUN tar -zxvf hadoop-${HADOOP_VERSION}.tar.gz && mv /hadoop-${HADOOP_VERSION} /hadoop && rm -rf hadoop-${HADOOP_VERSION}.tar.gz

# extract & move hive & clean up
RUN tar -zxvf apache-hive-${HIVE_VERSION}-bin.tar.gz \
  && mv apache-hive-${HIVE_VERSION}-bin hive \
  && rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# extract & move zookeeper & clean up
RUN tar -zxvf apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz \
  && mv apache-zookeeper-${ZOOKEEPER_VERSION}-bin zookeeper \
  && rm apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz

# extract & move hbase & clean up
RUN tar -zxvf hbase-${HBASE_VERSION}-bin.tar.gz \
        && mv hbase-${HBASE_VERSION} hbase \
      && rm hbase-${HBASE_VERSION}-bin.tar.gz

RUN tar -zxvf flink-${FLINK_VERSION}-bin-hadoop27-scala_2.11.tgz \
  && mv flink-${FLINK_VERSION} flink \
  && rm flink-${FLINK_VERSION}-bin-hadoop27-scala_2.11.tgz


#add jdk
RUN mkdir -p  /scripts/
ADD /pkg/jdk-8u191-linux-x64.tar.gz /scripts/
RUN rm -rf /scripts/jdk-8u191-linux-x64.tar.gz
ENV JAVA_HOME /scripts/jdk1.8.0_191
ENV PATH ${PATH}:${JAVA_HOME}/bin
ENV JRE_HOME ${JAVA_HOME}/jre
ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH ${JAVA_HOME}/bin: $PATH
