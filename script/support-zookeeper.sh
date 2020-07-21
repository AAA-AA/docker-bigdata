#!/bin/bash
set -e

ZK_DIR='/data/zookeeper/data'
ZK_LOG_DIR='/data/zookeeper/log'
ZK_PORT=${ZK_PORT:-"2181"}

hostname=`hostname`
echo "get hostname:$hostname"
index=1
myid=0

for host in $ZK_HOSTS
    do
      if [ "$hostname"x = "$host"x ];then
          myid=$index
      fi
      echo "server.$index=$host:2888:3888" >> $ZOOKEEPER_HOME/conf/zoo.cfg
      index=`expr $index + 1`
    done
echo "get zookeeper myid:$myid"

sed -i "s#ZOOKEEPER_DIR#${ZK_DIR}#g" $ZOOKEEPER_HOME/conf/zoo.cfg
sed -i "s#ZOOKEEPER_LOG_DIR#${ZK_LOG_DIR}#g" $ZOOKEEPER_HOME/conf/zoo.cfg
sed -i "s/ZOOKEEPER_PORT/${ZK_PORT}/g" $ZOOKEEPER_HOME/conf/zoo.cfg
if [ $myid -ne 0 ];then
  mkdir -p $ZK_DIR
  echo "$myid" > "$ZK_DIR/myid"
  $ZOOKEEPER_HOME/bin/zkServer.sh start
fi