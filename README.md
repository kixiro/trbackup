trbackup
========

Backup web pages, static directory and database, copy remoute server backup.

Installing

	fakeroot dpkg-deb --build trbackup
	dpkg -i trbackup.deb

Configuration

	Open config file /etc/trbackup/config
		Replace all directives configuration file to your values.
		
	Generate public key
		ssh-keygen

	Copy file in remote server
		trbackup.sh -k

	Add in /etc/crontab lines
	* 1 * * *	root	/usr/bin/trbackup.sh -n site_block -c

	Where site_block is path in configuration file /etc/trbackup/config

	site_block()
	{
		mode 1
		dir /var/www/site1
		sql name_database
	}


	mode 1 - Compress all directories in "dir", compress all database in mysql server, add all files in one archive.
	mode 2 - Compress all directories and database in mysql server in a separate archive.
	mode 3 - Compress in directory "dir", compress database name "sql", add files in archive.

	dir - name directory www files

	sql - name database, if paramenter sql is empty - compress all databases.
