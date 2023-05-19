# README file for autossh

% author	: Guy Coen
% contact	: gcoen@cirrusled.com

## Overview

This service allows to have an ssh session with a remote device deployed in the field.

To set up on the remote device:
- copy the cirrus and cirrus.pub keys to ~/.ssh
- sudo chmod 600 cirrus
- sudo chmod 644 cirrus.pub
- sudo cp autossh.service /etc/systemd/system/autossh.service
- sudo systemctl enable autossh
- sudo systemctl start autossh
- sudo systemctl status autossh

## Usage examples on safe host machine:

Login using own shell:
- ssh -p 10030 -i ~/.ssh/cirrus cirrus@161.35.73.10
Copy file /var/log/sensors.rrd to local machine  
- scp -P 10030 -i ~/.ssh/cirrus cirrus@161.35.73.10:/var/log/sensors.rrd .
(Notice capital -P for scp versus small -p for ssh)
- scp -P 10029 -O -i ~/.ssh/cirrus root@161.35.73.10:/var/log/sensors.rrd .
(On A1 controllers with Yocto and only root account)

## Registration API

In addition to that, this repository also contains a small API server
- developed using Python/Falcon/Gunicorn
- it exposes 3 API's:
	- controllers GET to get list of registered Cirrus controllers
	- controllers POST to add a new controller
	- next GET to get the next available port number for a new controller to be added
	- others GET to get a list of other devices registered (not controllers)
	- others POST to add a new device that is not a controller

The controllers are used my MyRRDash, therefore non-controllers were moved out to a separate API
  
## Notes

Originally we used `autossh`, which is a wrapper around ssh that uses keep-alive messages in the tunnel to test tunnel health and restart if needed. Our experience however was that `ssh` was stable enough and installed by default, whereas `autossh` requires a separate installation. 
For the same reason, we use `curl` instead of `httpie` to interact with the API service, since `curl` is by default available on most systems.