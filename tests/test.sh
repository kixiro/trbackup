#!/bin/bash

STATIC_DIR=/var/www
MASK_DB=trbackup
FOLDERS_LIST=(site1 site2 site3)
DATABASE_LIST=(site_db_1 supsersite site_work)


make_data()
{
	for folder in "${FOLDERS_LIST[@]}"
	do
		mkdir -p ${STATIC_DIR}/${folder}/{tmp,cache}
		echo -e "<h1>Hello!</h1>" > ${STATIC_DIR}/${folder}/index.html
		echo -e "<?php \nphpinfo(); ?>" > ${STATIC_DIR}/${folder}/infophp.php
		echo -e "log file content" > ${STATIC_DIR}/${folder}/sustem.log
		echo -e "tmp file data" > ${STATIC_DIR}/${folder}/tmp/xxx.tmp
		echo -e "tmp file data" > ${STATIC_DIR}/${folder}/cache/yyy.tmp
	done
}	

make_database()
{
	for name_db in "${DATABASE_LIST[@]}"
	do
		name_db=${MASK_DB}_${name_db}	
		if [[ -d /var/lib/mysql/${name_db} ]]
		then
			echo "database ${name_db} is exists"
		else
			mysql -e "create database ${name_db} default character set utf8;"
			mysql -e "create table ${name_db}.test_table (id int,value varchar(100));"
			mysql -e "insert into ${name_db}.test_table values (1,'trbackup'),(2,'triton'),(3,'script');"
		fi
	done
}

clean()
{
	if [[ -d ${STATIC_DIR} ]]
	then
		rm -r ${STATIC_DIR}
	fi
	for name_db in "${DATABASE_LIST[@]}"
	do
		name_db=${MASK_DB}_${name_db}
		if [[ -d /var/lib/mysql/${name_db} ]]
		then
			mysql -e "drop database ${name_db};"
		fi
	done
}

clean 

echo 'start make_data'
if [[ -d ${STATIC_DIR} ]]
then
	echo "directory $STATIC_DIR is exists"
	exit 1
else
	make_data
fi

echo 'start make_database'
make_database

echo 'trbackup site_all'
../trbackup/usr/bin/trbackup.sh -f config -d -n site_all
echo 'trbackup site_pack'
../trbackup/usr/bin/trbackup.sh -f config -d -n site_pack
echo 'trbakcup site_tema'
../trbackup/usr/bin/trbackup.sh -f config -d -n site_tema
echo 'trbackup site_13'
../trbackup/usr/bin/trbackup.sh -f config -d -n site_13

clean
