openssl x509 -in /var/lib/waagent/$1.crt -out /etc/ssl/certs/turn/turn_server_cert.pem
cp /var/lib/waagent/$1.prv  /etc/ssl/certs/turn/turn_server_pkey.pem

docker run -v /var/lib/waagent:/etc/ssl -d -p 3478:3478 -p 3478:3478/udp --restart=always $2 $3 $4
