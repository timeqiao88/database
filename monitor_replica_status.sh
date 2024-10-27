#!/bin/bash

# <300 - [Good]
# 300> <600 - [Warning]
# > 600 - [Critical]

MAIL_FROM="root@`hostname`"
MAIL_TO="mailid@mail.com"
Warningthreshold=300
Criticalthreshold=600
backup=$1
CMD=$(/root/bin/pt-heartbeat -D test --master-server-id 1 --check | cut
-d. -f1)

# Pass the parameter "test.sh backup" to denote the call is from the
backup script.

if [ $CMD -lt $Warningthreshold ]
then
MESSAGE=`date +'%m:%d:%Y %H:%M:%S'`" [Good] current delay: "$CMD;
elif [ $CMD -gt $Warningthreshold ] && [ $CMD -lt $Criticalthreshold ]
then
MESSAGE=`date +'%m:%d:%Y %H:%M:%S'`" [Warning] current delay: "$CMD;
elif [ $CMD -gt $Criticalthreshold ]
then
MESSAGE=`date +'%m:%d:%Y %H:%M:%S'`" [Critical] current delay: $CMD
Check the replication"
else
MESSAGE=`date +'%m:%d:%Y %H:%M:%S'`" [Error] Replication status check
failed need to investigate."
fi

#No arguments supplied"

if [ -z "$1" ] && [ $CMD -gt $Warningthreshold ]
then
(echo "Subject: Replication status on `hostname`";
echo "Replication status : "
echo $MESSAGE
) | /usr/sbin/sendmail -O NoRecipientAction=add-to -f$\{MAIL_FROM}
$\{MAIL_TO}

elif [ $# -eq 1 ]
then
(echo "Subject: Replication status check prior to backup on `hostname`";
echo "Replication status prior to backup:"
echo $MESSAGE
) | /usr/sbin/sendmail -O NoRecipientAction=add-to -f$\{MAIL_FROM}
$\{MAIL_TO}

fi
