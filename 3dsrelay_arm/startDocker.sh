echo Input params $1 $2 $3 $4 $5

sudo mkdir /etc/ssl/certs/turn

sudo openssl x509 -in /var/lib/waagent/$1.crt -out /etc/ssl/certs/turn/turn_server_cert.pem

sudo cp /var/lib/waagent/$1.prv  /etc/ssl/certs/turn/turn_server_pkey.pem

if [ "$1" = 'true' || "$1" = '1' || "$1" = true || "$1" = 1  || "$1" = "True" ] ; then
    auth_method="shared_secret"
else
     auth_method="long_term_creds"
fi

echo $auth_method

echo Starting docker with params $2 "'$3'" $4 $auth_method

sudo docker run -v /etc/ssl/certs/turn:/etc/ssl -d -p 3478:3478 -p 3478:3478/udp -p 5349:5349 -p 5349:5349/udp --restart=always $2 "$3" $4 $auth_method
