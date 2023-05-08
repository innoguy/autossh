#!/bin/bash

set -u

if [ "$EUID" -ne 0 ]
then
    echo "Please run with sudo"
	exit
fi

# Argument parsing 
! getopt --test > /dev/null
if [ ${PIPESTATUS[0]} != 4 ]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

OPTS="h:u:n:p"
LONGOPTS="help:,user:,name:,port:"
print_help() {
	cat <<EOF
Usage: $(basename $0) [OTHER OPTIONS]

  -h, --help            this help message
  -u, --user            user name for keys
  -n, --name            host name to be used
  -p, --port            port to be used

EOF
}
! PARSED=$(getopt --options=${OPTS} --longoptions=${LONGOPTS} --name "$0" -- "$@")
if [ ${PIPESTATUS[0]} != 0 ]; then
    # getopt has complained about wrong arguments to stdout
    exit 1
fi
# read getopt's output this way to handle the quoting right
eval set -- "$PARSED"
while true; do
	case "$1" in
		-h|--help)
			print_help
			exit
			;;

		-u|--user)
			USERNAME="$2"
			shift 2
			;;
		-n|--name)
			HOSTNAME="$2"
			shift 2
			;;
		-p|--port)
			PORT="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			echo "argument parsing error"
			exit 1
	esac
done


for i in httpie
do
    dpkg -s $i &> /dev/null
    if [ $? -ne 0 ]
	then 
	  echo "Please install $i using sudo apt install $i" 
	fi
done

if [ ! -d "/home/$USERNAME/.ssh" ]
then
    echo ".ssh directory does not exist."
else
    sudo cp cirrus /home/$USERNAME/.ssh/
    sudo cp cirrus.pub /home/$USERNAME/.ssh/
fi

if [ -z "$PORT" ]
then
    PORT=$(http GET 161.35.73.10:8000/next | awk 'NR {print $0}')
fi 

if [ -z "$HOSTNAME" ]
then
    HOSTNAME=$(hostname | sed -e 's/.local//g')
fi


echo "Port to be used  : "$PORT
echo "Hostname         : "$HOSTNAME
echo "Username         : "$USERNAME

while true; do
        read -p "Do you want to proceed with these values? " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

RESULT=$(http POST 161.35.73.10:8000/controllers name=$HOSTNAME port=$PORT)

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