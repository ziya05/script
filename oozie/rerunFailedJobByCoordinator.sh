#!/bin/bash

oozieUrl=$1   		# oozie服务地址                                         http://oozieserver:11000/oozie
cId=$2        		# coordinator的ID                                      cId=0002560-190709105745051-oozie-oozi-C

day=$3        		# 执行日期                                              day=20190927
offset=$4     		# 执行日期的偏移量                                       offset=1
maxRunningCount=$5  # 同时运行的最多workflow的数量                          maxRunningCount=3

intervalTime=$6     # 两次执行处理的间隔时长， 单位为秒 intervalTime=10
waitTime=$7         # 当达到最大运行数量时，下一次检测数量的时间， 单位为秒 waitTime=60

failnodes=true  #是否只运行失败的节点

fDay=`date -d "${day} -${offset}day" +'%Y-%m-%d'`
echo ${fDay}

echo $cId
echo $oozieUrl

export OOZIE_URL=$oozieUrl

oozie job -info $cId -filter status=KILLED -localtime | grep oozie-oozi-W | while read line
do


arr=($line)

wfId=${arr[2]}
nominalDay=${arr[7]}
nominalTime=${arr[8]}

if [[ $nominalDay > $fDay ]] || [[ $nominalDay == $fDay ]]; then
		
currRunningCount=`oozie job -info ${cId} -filter status=RUNNING |grep oozie-oozi-W |wc -l` 
echo '当前coordinator正在运行的workflow数量: '${currRunningCount}
		
while [[ $currRunningCount -ge $maxRunningCount ]]
do

sleep ${waitTime}
currRunningCount=`oozie job -info ${cId} -filter status=RUNNING |grep oozie-oozi-W |wc -l` 

echo $line	

done

echo '正在重新运行job: '${wfId}' ; 其nominal 时间为：'${nominalDay}' '${nominalTime}
oozie job -rerun ${wfId} -D oozie.wf.rerun.failnodes=${failnodes}

sleep ${intervalTime} 

fi

done
