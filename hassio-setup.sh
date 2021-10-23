# Prerequisites
currentDir=$(pwd)
apt-get update
apt-get upgrade -yq
apt-get install -yq software-properties-common apparmor-profiles apparmor-utils apt-transport-https ca-certificates curl dbus jq network-manager docker-compose
apt-get autoremove -yq
apt-get autoclean -yq

# Adjust logging driver and storage driver for the Docker daemon
jq '. + { "log-driver": "journald", "storage-driver": "overlay2" }' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp
mv /etc/docker/daemon.json /etc/docker/daemon.json.bk
mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
systemctl restart docker

# HASS Container
mkdir -p ./hassio
cat >> ./hassio/docker-compose.yml <<EOF
version: '3'
services:
  homeassistant:
    container_name: homeassistant
    image: homeassistant/home-assistant:stable
    volumes:
      - ${currentDir}/hassio:/config
      - /etc/localtime:/etc/localtime:ro
    restart: always
    network_mode: host
    devices:
      - /dev/ttyACM0:/dev/ttyACM0
EOF
cd ./hassio
docker-compose up -d

# HASS Supervised
cd $currentDir
mkdir network-manager-deb
cd network-manager-deb
wget http://ftp.br.debian.org/debian/pool/main/n/nettle/libnettle6_3.4.1-1+deb10u1_arm64.deb
sudo dpkg -i libnettle6_3.4.1-1+deb10u1_arm64.deb
wget http://ftp.br.debian.org/debian/pool/main/p/p11-kit/libp11-kit0_0.23.15-2+deb10u1_arm64.deb
sudo dpkg -i libp11-kit0_0.23.15-2+deb10u1_arm64.deb
wget http://ftp.br.debian.org/debian/pool/main/n/nettle/libhogweed4_3.4.1-1+deb10u1_arm64.deb
sudo dpkg -i libhogweed4_3.4.1-1+deb10u1_arm64.deb
wget http://ftp.br.debian.org/debian/pool/main/g/gnutls28/libgnutls30_3.6.7-4+deb10u7_arm64.deb
sudo dpkg -i libgnutls30_3.6.7-4+deb10u7_arm64.deb
wget http://ftp.br.debian.org/debian/pool/main/n/network-manager/libnm0_1.14.6-2+deb10u1_arm64.deb
sudo dpkg -i libnm0_1.14.6-2+deb10u1_arm64.deb
wget http://ftp.br.debian.org/debian/pool/main/i/init-system-helpers/init-system-helpers_1.56+nmu1_all.deb
sudo dpkg -i init-system-helpers_1.56+nmu1_all.deb
wget http://ftp.br.debian.org/debian/pool/main/n/network-manager/network-manager_1.14.6-2+deb10u1_arm64.deb
sudo dpkg --force-confold -i network-manager_1.14.6-2+deb10u1_arm64.deb
cd ..
systemctl disable ModemManager
systemctl stop ModemManager
./supervised-installer.sh -m qemuarm-64

systemctl restart hassio-supervisor.service
