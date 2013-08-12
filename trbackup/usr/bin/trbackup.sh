#!/bin/bash

. /usr/lib/shflags/src/shflags

DEFINE_string 'name_site' 'null' 'Name config backup site' 'n'
DEFINE_boolean 'debug' 'false' 'Debug mode' 'd'
DEFINE_boolean 'copy' 'false' 'Copy file in remote server' 'c'
DEFINE_string 'config' '/etc/trbackup/config' 'Set config file' 'f'
DEFINE_boolean 'keycopy' 'false' 'Copy public key' 'k'
DEFINE_boolean 'log' 'false' 'Stdin write in log file' 'l'
DEFINE_boolean 'all' 'false' 'Backup all configuration in config file' 'a'

FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

. ${FLAGS_config}

if [[ ${FLAGS_log} -eq 0 ]]
then 
	exec 2>&1
	exec &>>$LOGFILE
fi

event() {
	if [[ $? == 1 ]]
		then echo `date "+%d.%m.%Y %H:%M:%S"` '[ERROR]' $1
	else echo `date "+%d.%m.%Y %H:%M:%S"` '[INFO]' $1 
	fi
}	

param() {
	if [[ ${FLAGS_debug} -eq 0 ]]
	then
		echo `date "+d.%m.%Y %H:%M%:%S"` '[DEBUG]' $1 $2
	fi
}

db() {
	case $1 in
		"1" )
		mysqldump -ARE > ${TMPDIR}/${NAME_SITE}/${SQL}_${backupdate}.sql
			event "backup ${SQL}.sql";;
		"2" ) 	
			dblist=$(/usr/bin/mysql -e 'show databases;' | egrep -v '("+--"|Database|information_schema|performance_schema)')
			event "get list databases"
			for i in $dblist
			do
				mysqldump $i -RE > ${TMPDIR}/${NAME_SITE}/${i}_${backupdate}.sql
				event "backup base ${i}"
			done;;
		"3" )
			mysqldump ${2} -R > ${TMPDIR}/${NAME_SITE}/${2}_${backupdate}.sql
			event "backup base ${2}";;
	esac
}

directory() {
	case $1 in
	"1" )
		mkdir -p ${TMPDIR}/${NAME_SITE}/${NAME_SITE}
		rsync -az --exclude-from ${EXCLUDE_GLOBAL} ${2}/ ${TMPDIR}/${NAME_SITE}/${NAME_SITE}/
		event "copy directory $2 mode1";;
	"2" )
		list_dir=$(find ${2} -mindepth 1 -maxdepth 1 -type d)
		event "get list directories"
		for i in $list_dir
		do
			name_dir=`basename ${i}`
			mkdir -p ${TMPDIR}/${NAME_SITE}/${name_dir}
			rsync -az --exclude-from ${EXCLUDE_GLOBAL} ${i}/ ${TMPDIR}/${NAME_SITE}/${name_dir}/
			event "copy directory ${i} mode2"
		done;;
	"3" )
		name_dir=`basename ${2}`
		mkdir -p ${TMPDIR}/${NAME_SITE}/${name_dir}
		if [[ -z $3 ]]
			then 
				rsync -az ${2}/ ${TMPDIR}/${NAME_SITE}/${name_dir}/
		else 
			rsync -az --exclude-from ${3} ${2}/ ${TMPDIR}/${NAME_SITE}/${name_dir}/
		fi
		event "copy directory ${2} mode3";;
	esac
}

pack() {
	case $1 in
		"1" ) 
			ls -1 ${TMPDIR}/${NAME_SITE}/*.sql > /dev/null 2>&1
			if [[ $? -eq 0 ]]
			then
				sql_list=$(ls -1 ${TMPDIR}/${NAME_SITE}/*.sql)
				event "get file name database dump"
				for i in $sql_list
				do
					name_file=`basename ${i}`
					dir_file=`dirname ${i}`
					tar -czf ${TMPDIR}/${NAME_SITE}/${name_file}.tar -C ${dir_file} ${name_file}
					event "pack database dump"
					rm ${TMPDIR}/${NAME_SITE}/${name_file}
					event "remove file $name_file"
				done
			fi
			tar -cf ${BACKDIR}/${2}_${backupdate}.tar ${TMPDIR}/${NAME_SITE} -C ${TMPDIR}
			event "pack all files";;
		"2" )
			sql_list=$(ls -1 ${TMPDIR}/${NAME_SITE}/*.sql)
			event "get list database dump files"
			for i in $sql_list
			do
				name_file=`basename ${i}`
				dir_file=`dirname ${i}`
				tar -czf ${BACKDIR}/${name_file}.tar -C ${dir_file} ${name_file}
				event "pack database dump ${name_file}"
			done
			dir_list=$(find ${TMPDIR}/${NAME_SITE} -mindepth 1 -maxdepth 1 -type d)
			event "get list backup directory"
			for i in $dir_list
			do
				name_file=`basename ${i}`
				dir_file=`dirname ${i}`
				tar -cf ${BACKDIR}/${name_file}.tar -C ${dir_file} ${name_file}
				event "pack directory name ${name_file}"
			done;;
	esac
}

copy() {
	event "copy file in remote server ${RMUSER}@${REMOTEADDR}"
	rsync -avz -e ssh ${BACKDIR}/ ${RMUSER}@${REMOTEADDR}:~/${RMDIR}
}

keycopy()
{
	event "copy public key user"
	scp $PUB_KEY ${RMUSER}@${REMOTEADDR}:~/	
	name_file_key=`basename $PUB_KEY`
	ssh $RMUSER@${REMOTEADDR} "cd ~ ;mkdir -p .ssh; cat ~/$name_file_key >> .ssh/authorized_keys; rm ~/$name_file_key; mkdir -p $RMDIR"
	exit 0	
}

size_backup() {
	if [[ ! $SAVE_TIME -eq 0 ]]
	then 
		find $BACKDIR -mtime +${SAVE_TIME} -exec rm {} \;
		event "delete old files"
	fi
	if [[ ! $BACKUP_SIZE_LOC -eq 0 ]]
	then 
		while true
		do
			size_loc=`du -sb $BACKDIR | awk '{print $1}'`
			if [[ $size_loc -gt $BACKUP_SIZE_LOC ]]
			then
				list_delete_file=$(ls -1rt $BACKDIR | head -1)
				for i in $list_delete_file
				do
					rm $BACKDIR/${i}
					echo $BACKDIR/${i}
					event "delete file $BACKDIR/${i}"
				done
			else
				break
			fi
		done
	fi
}


mode() {
	param 'mode' $1
	MODE=$1
}

name() {
	param 'name' $1
	NAME_SITE=$1
}

dir() {
	param 'dir' $1
	DIR=$1
	if [[ -n $2 ]]
	then 
		EXCLUDE_FILE=$2
		directory $MODE $DIR $EXCLUDE_FILE
	else
		directory $MODE $DIR
	fi
}

sql() {
	param 'sql' $1
	if [[ -z $1 ]]
		then SQL=$NAME_SITE
	else 
		SQL=$1
	fi
	db $MODE $SQL
}

testdir() {
	if [[ -z $1 ]]
	then 
		echo 'not found config file'
		exit 1
	fi
	name_dir=$1
	if [[ -e $name_dir ]]
	then
		if [[ -f $name_dir ]]
			then mv $name_dir ${TMP}_`date +%N`
		fi
	fi
	
	if [[ ! -d $name_dir ]]
		then mkdir -p $name_dir
	fi
}

if [[ ${FLAGS_keycopy} -eq 0 ]]
then
	keycopy
fi

if [[ ${FLAGS_all} -eq 0 ]]
then
	list=$(grep -E '^[a-zA-Z]+' /etc/trbackup/config|grep '()'|cut -d"(" -f 1)
	event "backup option --all"
	for site in $list
	do
		trbackup.sh -n $site $OPTIONS
	done
	exit 0
fi

if [[ ${FLAGS_name_site} == "null" ]]
then
	echo -e "Usage trbackup.sh --name_site parameter\n\t show info in trbackup.sh --help"
	exit 1
fi

if [[ -n ${FLAGS_name_site} ]]
then
	name ${FLAGS_name_site}
	testdir $TMPDIR
	mkdir -p ${TMPDIR}/${NAME_SITE}
	if [[ ! `ls -A ${TMPDIR}/${NAME_SITE}| wc -l` -eq 0 ]]
	then
		rm -f ${TMPDIR}/${NAME_SITE}/*.tar
	fi
	testdir $BACKDIR
	${FLAGS_name_site}
fi

if [[ $MODE -eq "1" || $MODE -eq "3" ]]
then
	pack "1" $NAME_SITE
else
	pack "2"
fi

if [[ ${FLAGS_copy} -eq 0 ]]
then
	copy
fi

if [[ ! -z $TMPDIR/${NAME_SITE} ]]
then
	rm -f $TMPDIR/${NAME_SITE}/*.tar
fi

size_backup
