#!/bin/bash
set -e

data_inited_flag="/data/.data_inited_flag"
datanode_inited_flag="/data/.datanode_inited_flag"
hive_inited_flag="/data/.hive_inited_flag"
#mkdir /data

sh /init/support-hadoop.sh

if [ "$ZOOKEEPER_ENABLE"x = "true"x ]; then
    sh /init/support-zookeeper.sh
fi

if [ "$HIVE_ENABLE"x = "true"x ]; then
    sh /init/support-hive.sh
fi

if [ "$HBASE_ENABLE"x = "true"x ]; then
    sh /init/support-hbase.sh
fi

if [ "$NAMENODE_ENABLE"x = "true"x ];then
    sleep 10
    if [ -f $data_inited_flag ];then
        $HADOOP_HOME/sbin/start-dfs.sh
        $HADOOP_HOME/sbin/httpfs.sh start
        $HADOOP_HOME/sbin/start-yarn.sh
#        /livy/bin/livy-server start
        sleep 60
        /spark/sbin/start-history-server.sh
        /hadoop/sbin/mr-jobhistory-daemon.sh start historyserver

    else
        echo Y | hadoop namenode -format
        $HADOOP_HOME/sbin/start-dfs.sh
        $HADOOP_HOME/sbin/httpfs.sh start
        $HADOOP_HOME/sbin/start-yarn.sh
#        /livy/bin/livy-server start
        touch $data_inited_flag

        sleep 60
        $HADOOP_HOME/bin/hadoop fs -mkdir hdfs://$NAMENODE_HOST:18007/spark-events
        /spark/sbin/start-history-server.sh
        /hadoop/sbin/mr-jobhistory-daemon.sh start historyserver

    fi
fi

if [ "$FLINK_ENABLE"x = "true"x ];then
     echo "start flink"
     "$FLINK_HOME/bin/start-cluster.sh"
fi
if [ "$HBASE_ENABLE"x = "true"x ];then
     echo "start hbase"
     "$HBASE_HOME/bin/start-hbase.sh"
fi

if [ "$DATANODE_ENABLE"x = "true"x ];then
  DN_BLOCK_SIZE=134217728
  if [ -f $datanode_inited_flag ];then
    $HADOOP_HOME/sbin/hadoop-daemon.sh start datanode
    $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager
  else
    sleep 120
    echo "start add datanode to namenode,datanode:$DATANODE_HOST"
    sshpass -p "root" ssh -p 5002 root@$NAMENODE_HOST "echo $DATANODE_HOST >> $HADOOP_HOME/datas/datanode.list"
    echo "start update ssh,home:$HOME,hadoop_home:$HADOOP_HOME"
    sshpass -p "root" ssh -p 5002 root@$NAMENODE_HOST "sh /tmp/ssh_set.sh $HOME $HADOOP_HOME"
    echo "start update local id_rsa.pub"
    scp -P 5002 root@$NAMENODE_HOST:$HOME/.ssh/id_rsa.pub $HOME/.ssh/
    echo "start update local authorized_keys"
    scp -P 5002 root@$NAMENODE_HOST:$HOME/.ssh/authorized_keys $HOME/.ssh/
    ssh -p 5002 root@$NAMENODE_HOST "$HADOOP_HOME/bin/hdfs dfsadmin -report"
    echo "DN_BLOCK_SIZE:$DN_BLOCK_SIZE"
    ssh -p 5002 root@$NAMENODE_HOST "$HADOOP_HOME/bin/hdfs dfsadmin -setBalancerBandwidth $DN_BLOCK_SIZE"
    touch $datanode_inited_flag
    $HADOOP_HOME/sbin/hadoop-daemon.sh start datanode
    $HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager
  fi
fi

if [ "$HIVE_ENABLE"x = "true"x ];then
    if [ -f $hive_inited_flag ];then
      $HIVE_HOME/bin/hive --service metastore &
      $HIVE_HOME/bin/hive --service hiveserver2 &
    else
      #hive中存储的数据和产生的临时文件需要存储在hdfs中，因此需要再hdfs中创建相应文件
      #存放hive中具体数据目录
      hadoop fs -mkdir -p /data/hive/warehouse
      #存放hive运行产生的临时文件
      hadoop fs -mkdir -p /data/hive/tmp
      #存放hive日志文件
      hadoop fs -mkdir -p /data/hive/log
      #修改文件权限
      hadoop fs -chmod -R 777 /data/hive/warehouse
      hadoop fs -chmod -R 777 /data/hive/tmp
      hadoop fs -chmod -R 777 /data/hive/log
      touch $hive_inited_flag
      $HIVE_HOME/bin/schematool -dbType mysql -initSchema
      $HIVE_HOME/bin/hive --service metastore &
      $HIVE_HOME/bin/hive --service hiveserver2 &
    fi
fi

#nohup java -jar -DMYSQL_HOST=$MYSQL_HOST -DMYSQL_PORT=$MYSQL_PORT -DDEVOPS_INFRA_PASSWORD=$MYSQL_PWD /schedule/catalpat-1.0.jar &

while :
do
    sleep 5
    #监控HBASE进程
    if [ "$HBASE_ENABLE"x = "true"x ];then
      if [ -z "`jps | grep "HMaster"`" ];then
            echo "======[error]: HMaster process does not exist."
            break
      fi
      if [ -z "`jps | grep "HRegionServer"`" ];then
            echo "======[error]: HRegionServer process does not exist."
            break
      fi
    fi
    #监控ZOOKEEPER进程
    if [ "$ZOOKEEPER_ENABLE"x = "true"x ];then
      if [ -z "`jps | grep "QuorumPeerMain"`" ];then
            echo "======[error]: QuorumPeerMain process does not exist."
            break
      fi
    fi
    #监控DATANODE进程
    if [ "$DATANODE_ENABLE"x = "true"x ];then
      if [ -z "`jps | grep "DataNode"`" ];then
            echo "======[error]: DataNode process does not exist."
            break
      fi
      if [ -z "`jps | grep "NodeManager"`" ];then
            echo "======[error]: NodeManager process does not exist."
            break
      fi
    fi
    #监控NAMENODE进程
    if [ "$NAMENODE_ENABLE"x = "true"x ];then
      if [ -z "`jps | grep "NameNode"`" ];then
            echo "======[error]: NameNode process does not exist."
            break
      fi
      if [ -z "`jps | grep "SecondaryNameNode"`" ];then
            echo "======[error]: SecondaryNameNode process does not exist."
            break
      fi
      if [ -z "`jps | grep "DataNode"`" ];then
            echo "======[error]: DataNode process does not exist."
            break
      fi
      if [ -z "`jps | grep "NodeManager"`" ];then
            echo "======[error]: NodeManager process does not exist."
            break
      fi
      if [ -z "`jps | grep "ResourceManager"`" ];then
            echo "======[error]: ResourceManager process does not exist."
            break
      fi
    fi
done
echo "======[error]: exit ======"