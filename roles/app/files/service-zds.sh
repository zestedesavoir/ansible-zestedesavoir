#!/bin/bash

function usage()
{
        echo $0 "[ start | stop | status ]"
}

if [ "$1" = "stop" ]
then
        systemctl stop zds-watchdog.service
        systemctl stop zds.service
        systemctl stop zmd.service
        systemctl stop mariadb.service
elif [ "$1" = "start" ]
then
        systemctl start mariadb.service
        systemctl start zmd.service
        systemctl start zds.service
        systemctl start zds-watchdog.service
elif [ "$1" = "status" ]
then
        systemctl status mariadb.service --no-pager
        systemctl status zmd.service --no-pager
        systemctl status zds.service --no-pager
        systemctl status zds-watchdog.service --no-pager
else
        usage;
fi
