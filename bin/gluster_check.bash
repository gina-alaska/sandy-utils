#!/bin/bash
. $HOME/slack.env

if [ -d /gluster/cache ];  then
   echo "INFO: Has Gluster Mount, checking it is valid"
   if [ -f /gluster/cache/testfile ]; then
       echo "INFO: Has Gluster is ok!"
   else
       echo "INFO: Gluster isn't mounted!"
       curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"NRT STACK FAILURE: Gluster is not mounted on $(/usr/bin/hostname), restarting sidekiq and mounting gluster \"}" $OPS_SLACK_URL
       sudo systemctl restart sidekiq
       sudo mount /gluster/cache
       curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"NRT STACK: Done with restart for $(/usr/bin/hostname)\"}" $OPS_SLACK_URL
   fi
else
   echo "INFO: Doesnt have gluster."

fi
