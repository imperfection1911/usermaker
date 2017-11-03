#!/bin/bash
# script for adding users from external csv file
# input format user;password;group1,group2;/home/user
# example ./create_users.sh < users.csv
while read LINE
	do
	# get variables
	USER=$(echo $LINE | cut -d ';' -f 1)
	PASSWORD=$(echo $LINE | cut -d ';' -f 2)
	USER_GROUPS=$(echo $LINE | cut -d ';' -f 3)
	HOME_DIR=$(echo $LINE | cut -d ';' -f 4)
	# check for user defined
	if [ -z "$USER" ]
	then
		echo 'user is not defined'
		continue
	fi
	# check for user exists
	USER_EXISTS=$(cat /etc/passwd | awk -F ':' '{print $1}' |  grep ^"$USER"$ )
	if [ ! -z "$USER_EXISTS" ]
	then
		echo "user $USER already exists"
		continue
	fi
	# check for passwod is set
	if [ -z "$PASSWORD" ]
	then
		PASSWORD_FL=0
	else
		PASSWORD_FL=1
	fi
	# check for groups is set
	if [ -z "$USER_GROUPS" ]
	then
		USER_GROUPS_FL=0
	else
		USER_GROUPS_FL=1
	fi
	# check for home dir is set
	if [ -z "$HOME_DIR" ]
	then
		HOME_DIR_FL=0
	else
		HOME_DIR_FL=1
	fi
	# check for home dirt exists
	if [ -d $HOME_DIR ]
	then
		echo "home $HOME_DIR already exists"
		continue
	fi
	HOME_ALREADY_USED=$(cat /etc/passwd | awk -F ':' '{print $6}' | grep ^"$HOME_DIR"$)
	if [ ! -z "$HOME_ALREADY_USED" ]
	then
		echo "$HOME_DIR already used in passwd"
		continue
	fi
	# adding user
	if [ "$HOME_DIR_FL" -eq 1 ]
	then
		useradd -d $HOME_DIR $USER
	else
		useradd -m $USER
	fi
	# close login if no password
	if [ "$PASSWORD_FL" -eq 0 ]
	then
		usermod -s /sbin/nologin $USER
	else
		echo $PASSWORD | passwd $USER --stdin
	fi
	# add groups
	if [ "$USER_GROUPS_FL" -eq 1 ]
	then
		GROUPSS=$(echo $USER_GROUPS | tr "," "\n" )
	for group in $GROUPSS
	do
		GROUP_EXISTS=$(getent group "$group")
		if [ ! -z $GROUP_EXISTS ]
		then
			usermod -a -G $group $USER
		else
			echo "group $group is not exists"
			continue
		fi
	done
	fi
done		
