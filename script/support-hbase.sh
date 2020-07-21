#!/bin/bash
set -e

SSHD_PORT=${SSHD_PORT:-"5002"}
ZK_PORT=${ZK_PORT:-"2181"}
DN_REPL_COUNT=${BLOCK_REPL:-"1"}

rm $HBASE_HOME/conf/regionservers
touch $HBASE_HOME/conf/regionservers
rm -rf $HBASE_HOME/docs
index=1
ZK_URL=""
for host in $ZK_HOSTS
    do
      if [ $index -gt 1 ];then
              ZK_URL="$ZK_URL,$host:$ZK_PORT"
      else
              ZK_URL="$ZK_URL$host:$ZK_PORT"
      fi
      index=`expr $index + 1`
    done
echo "get zookeeper url :$ZK_URL"

echo $DEVOPS_INTERNAL_IP >> $HBASE_HOME/conf/regionservers
sed -i "s/ZK_URL/${ZK_URL}/g" $HBASE_HOME/conf/hbase-site.xml
sed -i "s/NN_HOST/${NAMENODE_HOST}/g" $HBASE_HOME/conf/hbase-site.xml
sed -i "s/DN_REPL_COUNT/${DN_REPL_COUNT}/g" $HBASE_HOME/conf/hbase-site.xml
cat >> $HBASE_HOME/conf/hbase-env.sh << EOF

export HBASE_SSH_OPTS="-p ${SSHD_PORT}"
export JAVA_HOME=/scripts/jdk1.8.0_191
export HBASE_MANAGES_ZK=false

EOF