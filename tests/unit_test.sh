#!/bin/bash

. ./backup.sh

test_mysql() {
	echo 'test mysql mode1'
	db "1" 
	
	echo 'test mysql mode2'
	db "2"
	
	echo 'test mysql mode3'
	db "3" "fishing35"
}

test_loging() {
	id root
	event "id test toxa"
	
	id blabla
	event "id test blabla"
}

test_directory() {
	echo "test directory mode1"
	directory "1" "work"
	rm -r ${TMPDIR}/*

	echo "test directory mode2"
	directory "2" "work"
	rm -r ${TMPDIR}/*
	
	echo "test directory mode3"
	directory "3" "work/site3"
	directory "3" "work/site4" "exclude.list"
	rm -r ${TMPDIR}/*
}   

test_pack() {
	echo "test pack mode1"
	mkdir ${TMPDIR}/site
	touch ${TMPDIR}/site/index.html
	touch ${TMPDIR}/site_db.sql
	pack "1" "site"
	ls -lh ${BACKDIR}/
	rm -r ${TMPDIR}/* ${BACKDIR}/*

	echo "test pack mode2"
	mkdir ${TMPDIR}/{site1,site2}
	touch ${TMPDIR}/{site1,site2}/index.html
	touch ${TMPDIR}/{site1_db.sql,site2_db.sql}
	pack "2" "site"
	ls -lh ${BACKDIR}/
	rm -r ${TMPDIR}/* ${BACKDIR}/*
}

test_copy() {
	copy
}

test_size_backup() {
	size_backup
}
		
#test_mysql
#test_loging
#test_directory
#test_pack
#test_copy
#test_size_backup
