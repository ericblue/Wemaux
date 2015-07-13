#!/bin/bash

function shutdown {
   
    echo "Shutting down...."
    kill -9 `ps auxw | grep wemaux_httpd | grep -v grep  | awk '{print $2}'` > /dev/null


}

trap shutdown SIGHUP SIGINT SIGTERM

echo "Starting HTTP daemon for Wemaux"
./wemaux_httpd.pl

echo "Starting UPNP daemon for Wemaux"
./wemaux_upnpd.pl
