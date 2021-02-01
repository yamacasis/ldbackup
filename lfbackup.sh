#!/bin/bash

# Linux Database Remote Backup Script
# Version: 1.0
# Script by: YamaCasis
# Email: yamacasis@gmail.com
# Created : 6 July 2020

########################
# Configuration        #
########################

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

. "$DIR/"config.conf

########################
# Functions            #
########################

create_dir_backup() {
  umask 177

  PFIX="$(date +'%Y%m%d%H%M%S')";
  FILE="$base_name-$PFIX.tar.gz"
  cd $backup_path 
  tar -cvzf $backup_path/$FILE $s


   fileskb=`du -k "$FILE" | cut -f1`
	if [ $fileskb -gt 0 ]
         then
                 MSG="----> Directory Backup Created  $S : $d : $FILE "
         else
	         MSG="----> Directory Backup Failed $S : $d : $FILE "
         fi

  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "$MSG"
  fi

}



clean_backup() {
  if [ $KEEPLB -eq 0 ]
  then
	rm -f $backup_path/$FILE
  fi

  find $s-*.gz ! -name "$FILE" -type f -exec rm -f {} +
  MSG="---- |__ Clear backup File  "
  echo $MSG

  if [ $LOGSTATE -eq 1 ]
  then
    log_it "$MSG"
  fi
}

send_backup() {
  if [ $TYPE -eq 1 ]
  then

    ftp -ni $SERVER <<EOF
	user $USERNAME $PASSWORD
	cd $REMOTEDIR	
        mls  $base_name-*.gz list.txt 
	quit
EOF

   ALLRemote="$(cat list.txt | wc -l)";
nl='
' # yeah, nl is a newline in single quotes
    counter=0
    dellist=''
    KNumber=$((ALLRemote-REMOTEKEEP))
    while IFS= read  -r N
    do

     if [ $counter -le $KNumber ]
     then
     	dellist=$dellist"mdel $N$nl"
     else
	echo "KEEP  : $N"
     fi
     counter=$((counter+1))

    done <list.txt

    ftp -n -p -i $SERVER <<EOF
    user $USERNAME $PASSWORD
    binary
    cd $REMOTEDIR
    $dellist
    mput $FILE
    quit
EOF

    MSG="---- |__ Send backup File (FTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it "$MSG"
    fi

  elif [ $TYPE -eq 2 ]
  then
    rsync --rsh="sshpass -p $PASSWORD ssh -p $PORT -o StrictHostKeyChecking=no -l $USERNAME" $backup_path/$FILE $SERVER:$REMOTEDIR

    MSG="---- |__ Send backup File (SFTP): $FILE "
    echo $MSG
    if [ $LOGSTATE -eq 1 ]
    then
      log_it "$MSG"
    fi
  else
    MSG="---- |__ Dont Send"
    echo $MSG
  fi
}

log_it() {
    today="$(date +'%Y%m%d')";
    logfile=$DIR'/logs/'$today'.log'
    if [ -e $logfile ]
    then
      echo '   ' >> $logfile;
    else
    	echo '' > $logfile;
    fi

    echo $1 >> $logfile;
	#echo $1$2
}

##############################
# Start Backup Script        #
##############################

cd $backup_path

d=$(date +%F-%H:%M:%S)
MSG="+ Start script ( $d ) : "
echo $MSG

if [ $LOGSTATE -eq 1 ]
then
  log_it "$MSG"
fi


  for s in "${directories_name[@]}";
  do
    d=$(date +%F-%H:%M:%S)

    create_dir_backup

    send_backup

    if [ $DELE -eq 1 ]
    then
      clean_backup
    fi
  done


d=$(date +%F-%H:%M:%S)
MSG="+ Ended script ( $d ) ;  "
echo $MSG

if [ $LOGSTATE -eq 1 ]
then
  log_it "$MSG"
fi

##############################
# End Backup Script          #
##############################
