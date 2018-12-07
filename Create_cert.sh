#!/bin/bash
 
#Required
#domain=$(hostname -f)
domain=ca.csi.local
commonname=$domain
 
#Change to your company details
country=NL
state=Noord-Holland
locality=Amsterdam
organization=CSI-Project
organizationalunit=IT
email=dummy_email@hva-cybersec.nl

#Optional
password=CSI_password
 
rootFile=/ca/private/cakey.pem

if [ -z "$domain" ]
then
    echo "Argument not present."
    echo "Useage $0 [common name]"
 
    exit 99
fi

#check if directories exist.
#if [ ! -d "/ca" ]; then
#    echo "creating /ca dir"
#    sudo mkdir /ca
#    sudo mkdir /ca/newcerts /ca/certs /ca/crl /ca/private /ca/requests
#else
#    echo "/ca dir already exists"
#fi

cacertcheck=/ca/cacert.pem
#echo "Generating key request for $domain"
if ! [ -e "$rootFile" ]; then
	
#Generate a root private key
    sudo openssl genrsa -aes256 -passout pass:$password -out /ca/private/cakey.pem 4096 -noout
 
#Remove passphrase from the key. Comment the line out to keep the passphrase
    echo "Removing passphrase from key"
    sudo openssl rsa -in /ca/private/cakey.pem -passin pass:$password -out /ca/private/cakey.pem
 
#Create root certificate
    if ! [ -e "$cacertcheck" ]; then
        echo "Creating root certificate"
        sudo openssl req -new -x509 -key /ca/private/cakey.pem -out /ca/cacert.pem -days 3650 -set_serial 0 -passin pass:$password -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" -noout
    fi
fi


#remove indexes and certificates if exist USE ONLY FOR TESTING! 
index=/ca/index.txt
oldIndex=/ca/index.txt.old
attrIndex=/ca/index.txt.attr
serial=/ca/serial
if [ -e "$index" ]; then
    sudo rm $index
    sudo touch $index
fi
#Generate private key for (web)server
sudo openssl genrsa -aes256 -passout pass:$password -out /ca/private/serverCertKey.pem 2048 -noout

#Remove passphrase from the key. Comment the line out to keep the passphrase
echo "Removing passphrase from key"
sudo openssl rsa -in /ca/private/serverCertKey.pem -passin pass:$password -out /ca/private/serverCertKey.pem 

#Create the request
echo "Creating CSR"
sudo openssl req -new -key /ca/private/serverCertKey.pem -out /ca/requests/serverCert.csr -passin pass:$password \
    -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email" 



echo "---------------------------"
echo "-----Below is your CSR-----"
echo "---------------------------"
echo
cat /ca/requests/serverCert.csr
 
echo
echo "---------------------------"
echo "-----Below is your Key-----"
echo "---------------------------"
echo
cat /ca/private/serverCertKey.pem

(echo y ; echo y; ) | sudo openssl ca -in /ca/requests/serverCert.csr -out /ca/certs/serverCertKey.pem
