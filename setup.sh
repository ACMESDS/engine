#!/bin/bash
# UNCLASSIFIED when IP addresses and passwords are undefined

#
# Setup env
#
if test -f config.sh; then
	source config.sh
fi

case "$1." in
#
# project enumerator cases
#
apply.)  # apply CMD to all projects

	for prj in "${PROJECTS[@]}"; do
		cd $prj
			echo ">>>>>>>>> ${prj}"
			$SETUP $2 $3 $4 $5
		cd ..
	done
	;;
	

#
# repo cases
#		

clone.)	# clone a project
	echo "Cloning project $2"
	git clone $REPO/$2.git
	;;	

baseline.)
	echo "Baseline project $2"
	cd $2
		git init
		git remote add origin $REPO/$2.git
		git pull origin master
	cd ..
	;;

commit.)   # commit changes
	git commit -am "$2"
	;;

push.)   # push code changes to git
	git push origin master
	;;
	
pull.)	# pull code changes from git
	git pull origin master
	;;
	
#
# Special cases
#

below.) 		# source vars down next node_modules

	here=`pwd`
	let depth=(`echo "$here" | grep -o "/" | wc -l`-1)/2
	echo "$depth-$2"
	if [ "$3" != "" ]; then			# dependent client exists
		cd node_modules/$3/
		echo "sourcing `pwd`"
		source geoclient.sh
		cd ../..
	fi
	export HERE=`pwd`
	;;

edit.)
	geany client.js config.js setup.sh &
	;;
	
help.)		# some help

	echo "usage:"
	echo "	\$SETUP CMD OPTIONS"
	echo "	\$SETUP all CMD OPTIONS"
	echo "	\$SETUP apply CMD OPTIONS"
	echo "	\$SETUP docker N FILE.js OPTIONS"
	echo "	\$SETUP CONFIG OPTIONS"
	echo "	\$SETUP FILE.js OPTIONS"
	echo ""
	echo "Repo CMDs:"
	echo "	clone PROJECT from repo"
	echo "	push commited changes to repo with 'gitCOMMENT npmVERSION' OPTIONS"
	echo "	pull latest changes from repo"
	echo "	baseline project (git init+push) to the repo"
	echo "Enumerator CMDs"
	echo " 	apply CMD to all projects [${PROJECTS[@]}]"
	echo "Testing CMDs:"
	echo "	list available totem.js applications"
	echo "	docker FILE.js.js in N docker containers with OPTIONS"
	echo "	CONFIG case to run from test.js"
	echo "	FILE.js to run in its geoclient.sh env with OPTIONS"
	echo "Maintenance CMDs:"
	echo "	startup dependent services (mysql, cesium, nodered, ...)"
	echo "	reset all allocated docker threads"
	echo "	config app parameters via mysql"
	echo "	help with $BASH_SOURCE"
	echo " 	notes on installation"
	echo "	proxy email via ssh"
	echo "Data Syncing CMDs:"
	echo "	checkpoint the mysql database"
	echo "	archive project to hosting machine"
	echo "	sync code changes with other machines"
	echo "Special CMDs:"
	echo "	bind known c-modules to geonode"
	echo "	redoc geoclient.js using doxygen compiler"
	echo "	restyle css styles using css compass complier"
	;;
	
#
# Maintenance cases
#

startup.)		# status and start dependent services
	if P=$(pgrep mysqld); then
		echo -e "mysql service running: \n$P"
	else
		rm /var/lib/mysql/mysql.sock      # in case its hanging around
		mysqld_safe --defaults-file=/base/mysql/my.cnf &
	fi

	if P=$(pgrep cesium); then
		echo -e "cesium service running: \n$P"
	else
		#node $BASE/cesium/geonode/geocesium --port 8083 --public &
		node $BASE/cesium/server --port 8083 --public &
	fi

	if P=$(pgrep node-red); then
		echo -e "nodered service running: \n$P"
	else
		#node $BASE/nodered/node_modules/node-red/red &
		node $BASE/nodered/node_modules/node-red/red -s $BASE/nodered/node_modules/node-red/settings.js &
	fi

	# docker
	# probe to expose /dev/nvidia device drivers to docker
	/base/nvidia/bin/x86_64/linux/release/deviceQuery

	sudo systemctl start docker.service

	echo "docked containers"
	docker ps -a

	# office products
	#acroread 										# starts adobe reader for indexing pdfs.  
	#openoffice4 									# starts openoffice server for indexing docs.  

	;;

config.)		# configure apps
	echo -e "use the OpEnv db to config the operating env for all apps\nuse the appN db to config the appN service"
	mysql -u$SECRETS_DB_USER -p$SECRETS_DB_PASS
	;;

restyle.)
	echo "to be developed"
	;;

redoc.)
	cd $HERE
		doxygen config.oxy
	;;

proxy.)	# establish email proxy
	ssh jamesdb@54.86.26.118 -L 5200:172.31.76.130:8080 -i ~/.ssh/aws_rsa.pri	
	;;
		
nada.)		# quite mode
	;;

notes.)

	vi admins/notes*.txt
	;;
	
bind.) 			# bind known genode c-modules

	cd $TAUIF/opencv
	$GEOBIND rebuild
	
	cd $TAUIF/python
	$GEOBIND rebuild
	
	cd $TAUIF
	$GEOBIND rebuild
	;;

#
# Syncing data cases
#

checkpoint.)  # export db to admins

	echo "Exporting sqldb to admins/db"

	cd $ADMIN/db
		mysqldump -u$DB_USER -p$DB_PASS openv >openv.sql
		mysqldump -u$DB_USER -p$DB_PASS app1 >app1.sql
		#mysqldump -u$DB_USER -p$DB_PASS --events mysql >mysql.sql
		#mysqldump -u$DB_USER -p$DB_PASS jou >jou.sql

		#sudo zip -r /media/sf_archives/sqldb.zip $ADMINS/db
		git commit -am $2
		git push origin master
	cd $HERE
	
	;;

archive.) 		# archive geonode to factory archive area

	echo "Archiving geonode to /media/sf_archives"
	sudo zip -r /media/sf_archives/geonode-N.zip $HERE
	;;
	
sync.)   # special forced code syncs
	#rsync $CHIPS/forecasts/* $SWAG02:$CHIPS/forecasts
	rsync $HOME/*.jpg $SWAG02:$HOME

	# rsync -r $NODEPATH/swag $SWAG01:$NODEPATH
	# rsync -r $NODEPATH/tauif $SWAG01:$NODEPATH
	# rsync -r $HERE/start.sh $SWAG01:/base/geonode
	# rsync -r $HERE/public/dets $SWAG02:$PUBLIC
	# rsync -r $HERE/public/dbs $SWAG02:$PUBLIC
	# rsync -r /base/sqldb/* $SWAG01:/base/sqldb	
	# rsync -r $PUBLIC/python/exccaffe.py $SWAG01:$PUBLIC/python
	# rsync -r $NODEPATH/caffe $SWAG01:$NODEPATH
	# rsync $DNN/cuda/lib64/libcudnn.* $SWAG02:/base/cuDNN/cuda/lib64   # make caffe creates the so.7 libs
	
	;;
		
#
# Run geoclient
#

reset.)		# stop and remove GPU-caffe docker instances
	docker stop `socker ps -qa`
	docker rm `docker ps -qa`
	;;

list.)	# list available geonode apps
	node client.js --help
	;;

docker.) 

	let con=$2
	while [ $con -gt 0 ]; do
		echo "docking $1 in container $con"
		docker $RUND centos.nvidia sh -c "`pwd`/setup.sh $3 $4 $5 $6"
		let con-=1
	done
	;;

.)
	echo "See 'setup help' for command options"
	;;
	
*)  	# start specified geonode client

	node test.js app1 $1 $2 $3 $4 $5
	;;

esac

# UNCLASSIFIED when IP addresses and passwords are undefined
