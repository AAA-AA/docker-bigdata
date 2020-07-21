#!/bin/bash
set -e

SSHD_PORT=${SSHD_PORT:-"5002"}
HIVE_USER=${HIVE_USER:-"root"}

sed -i "s/NAMENODE_HOST/${NAMENODE_HOST}/g" $HIVE_HOME/conf/hive-site.xml
sed -i "s/JDBC_URL/${JDBC_URL}/g" $HIVE_HOME/conf/hive-site.xml
sed -i "s/HIVE_USER/${HIVE_USER}/g" $HIVE_HOME/conf/hive-site.xml
sed -i "s/HIVE_PWD/${DEVOPS_INFRA_PASSWORD}/g" $HIVE_HOME/conf/hive-site.xml
sed -i "s/SKIP_HADOOPVERSION=false/SKIP_HADOOPVERSION=true/g" $HIVE_HOME/bin/hive
cp $HIVE_HOME/conf/hive-site.xml $SPARK_HOME/conf/





