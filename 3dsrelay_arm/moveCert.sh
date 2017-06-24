openssl x509 -in /var/lib/waagent/$1.crt -out /etc/ssl/certs/turn/turn_server_cert.pem
cp /var/lib/waagent/$1.prv  /etc/ssl/certs/turn/turn_server_pkey.pem
