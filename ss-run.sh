#!/bin/bash

# check user account
user_name=`whoami`
if [ $user_name != root ]; then
	echo "Please use root account to run this script, exit"
	exit 1
fi

# install pip
pip --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Installing pip..."
	yum install -y epel-release > /dev/null 2>&1
	yum install -y python-pip > /dev/null 2>&1
else
	echo "pip:ok"
fi

# install qrencode
qrencode --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Installing qrencode..."
	yum install -y qrencode > /dev/null 2>&1
else
	echo "qrencode:ok"
fi

# install shadowsocks
ssserver --version > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Installing shadowsocks..."
	pip install shadowsocks > /dev/null 2>&1
else
	echo "shadowsocks:ok"
fi

# Get ipv4 from public API
server=`curl  -s http://ipecho.net/plain`

# Generate password
password=`openssl rand -base64 8`

# Backup shadowsocks config
time_stamp=`date +%Y%m%d%H%M%S`
if [ -f /etc/shadowsocks.json ] ; then
	echo "/etc/shadowsocks.json file exits, rename to shadowsocks.json.bak${time_stamp}"
	mv /etc/shadowsocks.json /etc/shadowsocks.json.bak${time_stamp}
fi

# Generate config
echo  "{">/etc/shadowsocks.json
echo "    \"server\":\"0.0.0.0\",">>/etc/shadowsocks.json
echo "    \"server_port\":8388,">>/etc/shadowsocks.json
echo "    \"local_address\": \"127.0.0.1\",">>/etc/shadowsocks.json
echo "    \"local_port\":1080,">>/etc/shadowsocks.json
echo "    \"password\":\"$password\",">>/etc/shadowsocks.json
echo "    \"timeout\":300,">>/etc/shadowsocks.json
echo "    \"method\":\"aes-256-cfb\",">>/etc/shadowsocks.json
echo "    \"fast_open\": false">>/etc/shadowsocks.json
echo  "}">>/etc/shadowsocks.json

# iptabels allow 8388 port
iptables -I INPUT -p tcp --dport 8388 -j ACCEPT  > /dev/null 2>&1
# restart shadowsocks server
ssserver -c /etc/shadowsocks.json -d stop > /dev/null 2>&1
ssserver -c /etc/shadowsocks.json -d start 
if [ $? != 0 ]; then
	echo  "ssserver start failed, please check"
	exit 1
else
	echo  "ssserver start success"
fi

qrencode --version > /dev/null 2>&1
if [ $? = 0 ]; then
	echo "QR Code:"
	echo ""
	client_base64=`echo -n "aes-256-cfb:$password@$server:8388"|base64`
	ss_encode_str="ss://$client_base64"
	echo -n "${ss_encode_str}"| qrencode -o - -t UTF8
fi

cat /etc/shadowsocks.json
