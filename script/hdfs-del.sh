#!/bin/bash
set -e

array=$(echo $2|tr "," "\n")

safeMode=`$1/bin/hadoop dfsadmin -safemode get`

if [ -f /heartbeat/hdfsFsckFiltered.log ];then
  rm /heartbeat/hdfsFsckFiltered.log
fi

if [ -f /heartbeat/hdfsFsckTotal.log ];then
  rm /heartbeat/hdfsFsckTotal.log
fi


if [ "$safeMode"x = "Safe mode is ON"x ];then

  echo "Safe mode is ON"

  healthy=`$1/bin/hadoop fsck / | grep "Status:" | awk -F'Status: ' '{print$2}'`

  if [ "$healthy"x = "HEALTHY"x ];then

    echo "The filesystem under path '/' is HEALTHY,but safe mode is ON,We will try to stop him！！！"
    $1/bin/hadoop dfsadmin -safemode leave

  else

    $1/bin/hadoop fsck / | awk '{if(substr($0,1,1)=="/")print $0}' > /heartbeat/hdfsFsckTotal.log
    for var in $array
    do
     echo `grep "$var" /heartbeat/hdfsFsckTotal.log >> /heartbeat/hdfsFsckFiltered.log`
    done

    filteredLength=`wc -l /heartbeat/hdfsFsckFiltered.log | awk -F' ' '{print$1}'`
    totalLength=`wc -l /heartbeat/hdfsFsckTotal.log | awk -F' ' '{print$1}'`
    echo "filteredLength:$filteredLength,totalLength:$totalLength"

    if [ "$filteredLength"x = "$totalLength"x ];then
      echo "The filesystem under path '/' is CORRUPT,safe mode is ON,We will try to stop him！！！"
      $1/bin/hadoop dfsadmin -safemode leave
      $1/bin/hadoop fsck / -delete
    else
      echo "The filesystem under path '/' is CORRUPT,safe mode is ON,We didn't stop him！！！"
    fi

  fi
fi

if [ "$safeMode"x = "Safe mode is OFF"x ];then

  echo "Safe mode is OFF"

  healthy=`$1/bin/hadoop fsck / | grep "Status:" | awk -F'Status: ' '{print$2}'`

  if [ "$healthy"x = "HEALTHY"x ];then

    echo "The filesystem under path '/' is HEALTHY,safe mode is OFF,We will do nothing！"

  else

    $1/bin/hadoop fsck / | awk '{if(substr($0,1,1)=="/")print $0}' > /heartbeat/hdfsFsckTotal.log
    for var in $array
    do
     echo `grep "$var" /heartbeat/hdfsFsckTotal.log >> /heartbeat/hdfsFsckFiltered.log`
    done

    filteredLength=`wc -l /heartbeat/hdfsFsckFiltered.log | awk -F' ' '{print$1}'`
    totalLength=`wc -l /heartbeat/hdfsFsckTotal.log | awk -F' ' '{print$1}'`
    echo "filteredLength:$filteredLength,totalLength:$totalLength"

    if [ "$filteredLength"x = "$totalLength"x ];then
      echo "The filesystem under path '/' is CORRUPT,safe mode is OFF,We will delete the damaged directory！！！"
      $1/bin/hadoop fsck / -delete
    else
      echo "The filesystem under path '/' is CORRUPT,safe mode is OFF,We can't delete damaged directories！！！"
    fi

  fi
fi