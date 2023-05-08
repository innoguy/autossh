#!/bin/bash

set -u

if [ "$EUID" -ne 0 ]
then
    echo "Please run with sudo"
	exit
fi

sudo cp cirrus $HOME/.ssh/
sudo cp cirrus.pub $HOME/.ssh/

PORT=$(http GET 161.35.73.10:8000/next | awk 'NR {print $0}')
HOST=$(hostname | sed -e 's/.local//g')

echo "Port to be used  : "$PORT
echo "Hostname         : "$HOST

while true; do
        read -p "Do you want to proceed with these values? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

RESULT=$(http POST 161.35.73.10:8000/controllers name=$HOST port=$PORT)

echo $RESULT

if [ ! -f "$PWD/autossh.service" ]
then
    echo "[Unit]" >> autossh.service
    echo "Description=Remote tunnel through DigitalOcean droplet" >> autossh.service
    echo "After=network.target" >> autossh.service
    echo ""
    echo "[Service]" >> autossh.service
    echo "User=root" >> autossh.service
    echo "Environment=\"AUTOSSH_GATETIME=0\"" >> autossh.service
    echo "ExecStart=/usr/bin/autossh -i $HOME/.ssh/cirrus -N -R 161.35.73.10:$PORT:localhost:22 root@161.35.73.10" >> autossh.service
    echo "Restart=on-failure" >> autossh.service
    echo "RestartSec=5s" >> autossh.service
    echo ""
    echo "[Install]" >> autossh.service
    echo "WantedBy=multi-user.target" >> autossh.service
fi

sudo cp $PWD/autossh.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start autossh
sudo systemctl status autossh
