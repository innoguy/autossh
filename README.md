# autossh

This service allows to have an ssh session with a remote device deployed in the field.

To set up on the remote device:
- copy the cirrus and cirrus.pub keys to ~/.ssh
- sudo chmod 600 cirrus
- sudo chmod 622 cirrus.pub
- sudo cp autossh.service /etc/systemd/system/autossh.service
- sudo systemctl start autossh
- sudo systemctl status autossh

Usage examples on safe host machine:

Login using own shell:
- ssh -p 10030 -i ~/.ssh/cirrus cirrus@161.35.73.10
Copy file /var/log/sensors.rrd to local machine  
- scp -P 10030 -i ~/.ssh/cirrus cirrus@161.35.73.10:/var/log/sensors.rrd .
(Notice capital -P for scp versus small -p for ssh)
