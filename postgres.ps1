Param(
    [string]$resource_group_name,
    [string]$location,
    [string]$psql_server_name,
    [string]$db_username,
    [string]$db_password,
    [string]$turn_username,
    [string]$turn_password,
    [string]$turn_secret,
    [string]$subscription_id = "",
    [string]$turn_realm = "azturntst.org",
    [string]$turnadmin_docker_image = "zolochevska/3dsrelayadmin:latest"
)

$env:PGPASSWORD = $db_password

az login

if ($subscription_id.Length -gt 0)
{
    "Selecting subscription $subscription_id"
    az account set --subscription $subscription_id
}

"Creating resource group in azure"
az group create --location $location --name $resource_group_name

"Creating postgres db in Azure"
az group deployment create --name 'psql' --resource-group $resource_group_name --template-file ./psql/template.json --parameters '@./psql/parameters.json' --parameters administratorLogin=$db_username administratorLoginPassword=$db_password location=$location serverName=$psql_server_name
 
"Updating firewall rules to allow access to database from all ip addresses"
az postgres server firewall-rule create --resource-group $resource_group_name --server $psql_server_name --name AllowAllIps --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.255

"Downloading schema for coturn db"
curl https://raw.githubusercontent.com/coturn/coturn/master/turndb/schema.sql -OutFile schema.sql

"Creating db coturndb"
createdb --host="$psql_server_name.postgres.database.azure.com" --port=5432 --username="$db_username@$psql_server_name" --password=$db_password coturndb

"Applying coturn schema to db coturndb"
psql --host="$psql_server_name.postgres.database.azure.com" --port=5432 `
    --username="$db_username@$psql_server_name" --dbname="coturndb" -f schema.sql 

"Creating role coturn in db coturndb"
psql --host="$psql_server_name.postgres.database.azure.com" --port=5432 --username="$db_username@$psql_server_name" `
     --dbname="coturndb" -c "CREATE ROLE coturn WITH NOCREATEDB NOCREATEROLE LOGIN PASSWORD '$db_password'"

"Granting permissions for user coturn for db coturndb"
psql --host="$psql_server_name.postgres.database.azure.com" --port=5432 --username="$db_username@$psql_server_name" --dbname="coturndb" `
   -c "GRANT ALL PRIVILEGES ON DATABASE coturndb TO coturn"

"Granting permissions to user coturn for every table"
$tables = 'turnusers_lt', `
          'turn_secret', `
          'allowed_peer_ip', `
          'denied_peer_ip', `
          'turn_origin_to_realm', `
          'turn_realm_option', `
          'oauth_key', `
          'admin_user'

Foreach ($table in $tables) {
    psql --host="$psql_server_name.postgres.database.azure.com" --port=5432 --username="$db_username@$psql_server_name" --dbname="coturndb" `
      -c "GRANT ALL PRIVILEGES ON $table to coturn;"
}

$psqlConnectionString = "host=$psql_server_name.postgres.database.azure.com dbname=coturndb user=coturn@$psql_server_name password=$db_password connect_timeout=30 sslmode=require port=5432"

If ($location -Eq 'westus' -Or $location -Eq 'eastus' -Or $location -Eq 'westeurope') {
    $resource_group_name_for_turnadmin=$resource_group_name   
}
Else{
    $resource_group_name_for_turnadmin = $resource_group_name + "-turnadmin"
    "Creating resource group for turnadmin in azure"
    az group create --location 'westus' --name $resource_group_name_for_turnadmin
}


If ($turn_username -And $turn_password) {
    "Running docker to set username/password for turn user"
     az container create -g $resource_group_name_for_turnadmin --name turnadmin-container --image "zolochevska/3dsrelayadmin" --ip-address public --command-line "/bin/sh ./run-3dsrelayadmin.sh -e '$psqlConnectionString' -a -u $turn_username -p $turn_password -r $turn_realm"
}

If ($turn_secret) {
    "Running docker to set shared secret for turn"
     az container create -g $resource_group_name_for_turnadmin --name turnadmin-container --image "zolochevska/3dsrelayadmin" --ip-address public --command-line "/bin/sh ./run-3dsrelayadmin.sh -e '$psqlConnectionString' -s $turn_secret -r $turn_realm"
}

"Done. Connection string: " 
$psqlConnectionString

