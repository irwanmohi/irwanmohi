#!/bin/bash
#script for setting up my hacking VMs

sudo apt update

sudo apt upgrade

sudo apt install openvpn

sudo apt install python3

sudo apt install python3-pip

git clone https://github.com/trustedsec/ptf

git clone https://github.com/tryhackme/openvpn-troubleshooting

cd ptf

sudo pip install -r requirements.txt

echo "DONE! Now you can setup the Penetration Testing Framework."


