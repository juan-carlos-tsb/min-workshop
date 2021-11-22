#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -d domain.tld -p password"
   echo -e "\t-d FQDN Full qualified domain name"
   echo -e "\t-p Password"
   exit 1 # Exit script after printing help
}

while getopts "d:p:" opt
do
   case "$opt" in
      d ) DOMAIN="$OPTARG" ;;
      p ) PASSWORD="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done



echo $DOMAIN
echo $PASSWORD
# Print helpFunction in case parameters are empty
if [ -z "$DOMAIN" ] || [ -z "$PASSWORD" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi



cd /opt
mkdir virtualmin
cd virtualmin
wget https://software.virtualmin.com/gpl/scripts/install.sh
sudo /bin/sh install.sh -n $DOMAIN

virtualmin create-domain --domain "$DOMAIN" --pass "$PASSWORD" --desc "$DOMAIN" --unix --dir --web --ssl --limits-from-plan --ip-already --ip6-already
APACHEFILE="/etc/apache2/sites-available/${DOMAIN}.conf"
tail -n 1 "$APACHEFILE" | wc -c | xargs -I {} truncate "$APACHEFILE" -s -{}
#tail -n 1 "$APACHEFILE" | wc -c | xargs -I {} truncate "$APACHEFILE" -s -{}
EXTRACONF=$'#\n#\nSSLProxyEngine on\nSSLProxyVerify none\nSSLProxyCheckPeerCN off\nSSLProxyCheckPeerName off\nSSLProxyCheckPeerExpire off\nProxyPreserveHost Off\nProxyRequests off\nProxyPass / https://localhost:10000/\nProxyPassReverse / https://localhost:10000/\n#\n#\n</VirtualHost>'
echo "$EXTRACONF" >> $APACHEFILE
echo "referers=$DOMAIN" >> /etc/webmin/config
