#!/bin/bash

if [ "$EUID" -eq 0 ]
then
    echo "Please do not run with sudo"
	exit
fi

# Argument parsing 
! getopt --test > /dev/null
if [ ${PIPESTATUS[0]} != 4 ]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

OPTS="h:u:n:p:"
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

if [ -z "$PORT" ]
then
    PORT=$(curl -s http://161.35.73.10:8000/next | awk 'NR {print $0}')
    # PORT=$(http GET 161.35.73.10:8000/next | awk 'NR {print $0}') 
fi

if [ -z "$HOSTNAME" ]
then
    HOSTNAME=$(hostname | sed -e 's/.local//g')
fi

if [ -z "$USERNAME" ]
then
    USERNAME=$(whoami)
fi

echo "Port to be used  : "$PORT
echo "Hostname         : "$HOSTNAME
echo "Username         : "$USERNAME

while true 
do
    read -p "Do you want to proceed with these values? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

JSTRING="{\"name\":\""$HOSTNAME"\",\"port\":\""$PORT"\"}"
RESULT=$(curl -s --json $JSTRING http://161.35.73.10:8000/controllers)

echo $RESULT

if [ ! -f "$PWD/autossh.service" ]
then
    echo "[Unit]" >> autossh.service
    echo "Description=Remote tunnel through DigitalOcean droplet" >> autossh.service
    echo "After=network.target" >> autossh.service
    echo ""
    echo "[Service]" >> autossh.service
    echo "User=$USERNAME" >> autossh.service
    echo "Environment=\"AUTOSSH_GATETIME=0\"" >> autossh.service
    echo "ExecStart=/usr/bin/ssh -i /home/$USERNAME/.ssh/cirrus -N -R 161.35.73.10:$PORT:localhost:22 root@161.35.73.10" >> autossh.service
    echo "Restart=always" >> autossh.service
    echo "RestartSec=5s" >> autossh.service
    echo ""
    echo "[Install]" >> autossh.service
    echo "WantedBy=multi-user.target" >> autossh.service
fi

if [ ! -d "/home/$USERNAME/.ssh" ]
then
    echo "/home/$USERNAME/.ssh directory does not exist."
else
    sudo cp cirrus /home/$USERNAME/.ssh/
    sudo cp cirrus.pub /home/$USERNAME/.ssh/
    sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/cirrus
    sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh/cirrus.pub
    sudo chmod 600 /home/$USERNAME/.ssh/cirrus
    sudo chmod 644 /home/$USERNAME/.ssh/cirrus.pub    
fi
sudo cp $PWD/autossh.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable autossh
sudo ssh -i ~/.ssh/cirrus -n root@161.35.73.10 
sudo systemctl start autossh
