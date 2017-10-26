#!/bin/bash
#当前标准事件
currentTimeStamp=`date '+%s'`
#摇号网站标题列表地址
content=`curl -s 'http://jtzl.gzjt.gov.cn/index/gbl/' -L`
#当前月份
month=`date '+%m'`
#临时储存的pdf地址
pdfPath='/tmp/gz.pdf'
#临时储存的txt文件路径，根据pdf生成
txtPath='/tmp/gz.txt'
#当月第一次告警时间保存的文件路径
alarmStartFilePath='/tmp/gz.last'
#当月第一次告警事件，初始化为0
lastAlarmTime=0
#如果告警时间文件找不到，先赋一个当前时间，否则直接采用文件的时间
if [[ -e "$alarmStartFilePath" ]]
then
    lastAlarmTime=`cat $alarmStartFilePath`
else
    lastAlarmTime=$currentTimeStamp
fi
#首次告警后，持续的时间，秒
alarmSecond=600
#目标任务
filterName='YourName'
#此时离首次告警，经过的时间，秒
diffTime=$(($currentTimeStamp-$lastAlarmTime))

#存在2x号发出的公告，此时认为已经有摇号的结果
if [[ $content == *${month}"-2"* ]]
then
    result=''
    #如果告警文件不存在，或者告警月份发生变化，重新设置告警时间
    if [[ ! -e "$alarmStartFilePath" ]]||[[ $month != `date -d @$lastAlarmTime '+%m'` ]]
    then 
        echo $currentTimeStamp >${alarmStartFilePath}
    else 
        #如果已经过了告警时间
        if [[ $diffTime -gt $alarmSecond ]]
        then 
            exit 0
        fi
    fi 
   #进入更深的获取pdf等逻辑
    /home/pi/spy/mailPush.sh  YueA  &
    hURL=`curl -s 'http://jtzl.gzjt.gov.cn/index/gbl/' -L|grep ${month}'月广州市中小客车指标配置结'|grep 'http.*html' -oE`
    pdfURL=`curl -s ${hURL}|grep ${month}'月个人普通车指标配置结果'|grep 'http.*pdf' -oE`
    curl -so $pdfPath $pdfURL
    /usr/bin/pdftotext $pdfPath $txtPath
    unluck=`grep -P ${filterName} $txtPath`
    if [ -n "$unluck" ]; then 
        /home/pi/spy/mailPush.sh $unluck &
    else
       /home/pi/spy/mailPush.sh 'noBody'   &
    fi

    echo `date`
    rm $pdfPath
    rm $txtPath
else
    echo `date`
fi
