#!/bin/bash
set -e

SSHD_PORT=${SSHD_PORT:-"5002"}
ROLE=${ROLE:-"worker"}
RESOURCE_MODE=${MODE:-"yarn"}
NM_WORKER_MEMORY=${NM_WORKER_MEMORY:-"81920"}
NM_WORKER_CORES=${NM_WORKER_CORES:-"16"}

DATANODE_HOST=$DEVOPS_INTERNAL_IP
JBH_HOST=$NAMENODE_HOST
JBS_HOST=$NAMENODE_HOST
SECONDARYN_HOST=$NAMENODE_HOST
RM_HOST=$NAMENODE_HOST
NM_HOST=$DATANODE_HOST

USER_MAX_APPS_DEFAULT=${USER_MAX_APPS_DEFAULT:-"7"}
MAX_RUNNING_APPS=${MAX_RUNNING_APPS:-"7"}
ROOT_MAX_APPS=${ROOT_MAX_RUNNING_APPS:-"5"}
DEFAULT_MAX_APPS=${DEFAULT_MAX_RUNNING_APPS:-"2"}

NM_LOCAL_DIRS='/data/nm/data1,/data/nm/data2'
NM_LOG_DIRS='/data/nm/logs1,/data/nm/logs2'
DN_DATA_DIRS='/data/hdfs/data1,/data/hdfs/data2'
DN_REPL_COUNT=1
DN_BLOCK_SIZE=134217728
SNN_DIRS='/data/hdfs/snn'
NN_DATA_DIRS='file:/data/hdfs/name'

HOME='/root'
mkdir -p /var/run/sshd
/usr/sbin/sshd -p ${SSHD_PORT}

################spark################
#mkdir -p /spark/data/master /spark/data/worker
cat >> $SPARK_HOME/conf/spark-env.sh << EOF
export SSHD_PORT=$SSHD_PORT
export SPARK_SSH_OPTS="-p ${SSHD_PORT}"
export JAVA_HOME=/scripts/jdk1.8.0_191
export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_HOME=$HADOOP_HOME
export SPARK_HISTORY_OPTS="-Dspark.history.ui.port=18079 -Dspark.history.fs.cleaner.enabled=true -Dspark.history.fs.cleaner.maxAge=7d -Dspark.history.retainedApplications=25 -Dspark.history.fs.logDirectory=hdfs://$NAMENODE_HOST:18007/spark-events"
EOF

#offline job history
export HADOOP_MAPRED_IDENT_STRING='root'
cp $SPARK_HOME/conf/spark-defaults.conf.template $SPARK_HOME/conf/spark-defaults.conf
cat >> $SPARK_HOME/conf/spark-defaults.conf << EOF
spark.eventLog.enabled              true
spark.eventLog.dir                  hdfs://$NAMENODE_HOST:18007/spark-events
spark.eventLog.compress             true
spark.history.fs.cleaner.enabled    true
spark.history.fs.cleaner.interval   1d
spark.history.fs.cleaner.maxAge     7d
spark.history.ui.port               18080
spark.history.retainedApplications  25
spark.yarn.historyServer.address    $NAMENODE_HOST:18079
spark.history.fs.logDirectory       hdfs://$NAMENODE_HOST:18007/spark-events
EOF

################spark end################
cp /spark/conf/slaves.template /spark/conf/slaves
sed -i '/localhost/d' /spark/conf/slaves

###########HADOOP############
cat >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh << EOF
export HADOOP_SSH_OPTS="-p ${SSHD_PORT}"
#export HADOOP_IDENT_STRING=$USER
export JAVA_HOME=/scripts/jdk1.8.0_191
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
EOF

grep '^[a-z]'  $HADOOP_HOME/etc/hadoop/hadoop-env.sh
sed -i '/localhost/d' $HADOOP_HOME/etc/hadoop/slaves

mkdir -p $HADOOP_HOME/datas/
touch $HADOOP_HOME/datas/datanode.list
if [ "$DATANODE_HOST"x != "$NAMENODE_HOST"x ];then
    echo "this node is datanode"
    echo $NAMENODE_HOST >> $HADOOP_HOME/datas/datanode.list
    echo $DATANODE_HOST >> $HADOOP_HOME/datas/datanode.list
else
    echo "this node is namenode"
    echo $NAMENODE_HOST >> $HADOOP_HOME/datas/datanode.list
fi

# setup ssh
mkdir -p $HOME/.ssh
mv /tmp/ssh/ssh_config $HOME/.ssh/config
mv /tmp/ssh/id_rsa $HOME/.ssh
touch $HOME/.ssh/id_rsa.pub
chmod 600 $HOME/.ssh/id_rsa

for host in `cat $HADOOP_HOME/datas/datanode.list | uniq`
    do
        #hadoop/slaves
        echo $host >> $HADOOP_HOME/etc/hadoop/slaves
        #spark/slaves
        echo $host >> /spark/conf/slaves
        cat >> $HOME/.ssh/id_rsa.pub  << EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDK4PCQdGfRQzBaOhctpyROhAHUu/Y5HtzVS3Y7UmYFoEot8cZ4eoGD3v3nR6FCu9jSAKoEvhpRH/iUod7yEIoaDLiUO0YQWlKw4n/IdGqfWUqkx5S6c1eLi83lWRCs5prWtxpYID5DPVu9G3r1uj/B7Rbv/I4Y3meywl8qzvI01MacRZyqBAHLfOOBqsYyH3UCLACXLeilMv2kRNRf+z0Desij2Qya3GDSqvoDlLi9tBVBifNT52A2+4i4/8UV/IFzb48jrPbugX/DQy3i6BDXsRfv3aTN1C4y2io15rdoTnCZeWb2VwSz61oCz5zcOuLGh8dkMRk7JRQaFTC+e8tf root@$host
EOF
    done

cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

#perform
sed -i "s/NN_HOST/${NAMENODE_HOST}/g" $HADOOP_HOME/etc/hadoop/core-site.xml
sed -i "s/NN_HOST/${NAMENODE_HOST}/g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s#NN_DATA_DIRS#${NN_DATA_DIRS}#g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s#SNN_DIRS#${SNN_DIRS}#g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s/SECONDARYN_HOST/${SECONDARYN_HOST}/g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s/DN_HOST/${DATANODE_HOST}/g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s#DN_DATA_DIRS#${DN_DATA_DIRS}#g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s/DN_REPL_COUNT/${DN_REPL_COUNT}/g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s/DN_BLOCK_SIZE/${DN_BLOCK_SIZE}/g" $HADOOP_HOME/etc/hadoop/hdfs-site.xml
sed -i "s/RM_HOST/${RM_HOST}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/NM_HOST/${NM_HOST}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/NM_HOST/${NM_HOST}/g" $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i "s/JBH_HOST/${JBH_HOST}/g" $HADOOP_HOME/etc/hadoop/mapred-site.xml
sed -i "s#NM_LOCAL_DIRS#${NM_LOCAL_DIRS}#g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s#NM_LOG_DIRS#${NM_LOG_DIRS}#g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/NM_WORKER_MEMORY/${NM_WORKER_MEMORY}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/NM_WORKER_CORES/${NM_WORKER_CORES}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml
sed -i "s/JBS_HOST/${JBS_HOST}/g" $HADOOP_HOME/etc/hadoop/yarn-site.xml

sed -i "s/USER_MAX_APPS_DEFAULT/${USER_MAX_APPS_DEFAULT}/g" $HADOOP_HOME/etc/hadoop/fair-scheduler.xml
sed -i "s/MAX_RUNNING_APPS/${MAX_RUNNING_APPS}/g" $HADOOP_HOME/etc/hadoop/fair-scheduler.xml
sed -i "s/ROOT_MAX_APPS/${ROOT_MAX_APPS}/g" $HADOOP_HOME/etc/hadoop/fair-scheduler.xml
sed -i "s/DEFAULT_MAX_APPS/${DEFAULT_MAX_APPS}/g" $HADOOP_HOME/etc/hadoop/fair-scheduler.xml

#support WebHDFS
cat >> $HADOOP_HOME/etc/hadoop/httpfs-env.sh << EOF
export HTTPFS_HTTP_PORT=14000
export HTTPFS_ADMIN_PORT=`expr ${HTTPFS_HTTP_PORT} + 1`
EOF
#support LIVY
#mv /livy/conf/livy-env.sh.template /livy/conf/livy-env.sh
#cat >> /livy/conf/livy-env.sh << EOF
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export SPARK_HOME=/spark
EOF
#mv /livy/conf/livy.conf.template /livy/conf/livy.conf
#cat >> /livy/conf/livy.conf << EOF
#livy.spark.master = yarn
#livy.spark.deploy-mode =cluster
#EOF

################HADOOP END#####################
cat >> /etc/environment << EOF
DEVOPS_INTERNAL_IP=$DEVOPS_INTERNAL_IP
ROLE=$ROLE
SSHD_PORT=$SSHD_PORT

EOF

sed -i '/mesg n/d' ~/.profile
cat >> ~/.profile << EOF
#tty -s && mesg n
#HADOOP_HOME=/hadoop
HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
#LIVY_HOME=/livy
#SPARK_HOME=/spark
#PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$LIVY_HOME/bin
DEVOPS_INTERNAL_IP=$DEVOPS_INTERNAL_IP
ROLE=$ROLE
SSHD_PORT=$SSHD_PORT

EOF
. ~/.profile