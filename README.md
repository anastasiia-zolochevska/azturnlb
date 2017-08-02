# azturnlb
Scripts and Config for deploying load balanced Coturn servers in Azure

Prerequisites:

+ [Postgres](https://www.postgresql.org/download/) installed on the local machine (command `psql --version` should work from powershell) 
+ [Docker](https://www.docker.com/) installed on the local machine (command `docker ps` should work from powershell) 
+ [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed (command `az` should work from powershell)

## Windows
1. Run postgres.ps1 in powershell 
Example (it will create Postgres DB with database for coturn and set turn username/password):
```sh
    .\postgres.ps1 -resource_group_name "resourceGroupName" -location "westus" -psql_server_name "psqlServername" -db_username "dbuser" -db_password "dbPassword" -turn_username "user" -turn_password "turnPassword"
```

Example (it will create Postgres DB with database for coturn and set turn shared secret):
```sh
    .\postgres.ps1 -resource_group_name "resourceGroupName" -location "westus" -psql_server_name "psqlServername" -db_username "dbuser" -db_password "dbPassword" -secret "sharedseret"
```

1. Put certificate pfx file to keyvault (documentation is not ready yet)
1. Deploy (arm template) N instances of TURN relay server (requires PSQL connection string, link to keyvault with certificate and default realm)

    Use this button to deploy to Azure and set parameters using Azure portal:
    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/anastasiia-zolochevska/coturn-to-azure-deployment/master/3dsrelay_arm/template.json)
    
Here are some parameters you'll need to specify:
 
        instanceCount - The number of turn servers that will be setup
        virtualMachineNamePrefix - The prefix used for various resources created (vm names, vnet, nsg, etc..)
        adminPublicKey - The ssh public key that will be used to login to the machines if needed (Default user is `turnroot`)
        diagnosticsStorageAccountName - Storage account that turn VMS will log diagnostics to
        postgreSqlConnectionString - Should be the same as the PSQL_COTURN_CS value above
        defaultTurnRealm - Ideally the same as the one configured for the users you added in the above step (e.g. azturntst.org)
        turnImage - The container image you created that runs the relay.  ([zolochevska/3dsrelay](https://hub.docker.com/r/zolochevska/3dsrelay/) or your image created from 3dsrelay/)
    
    

1. Deploy (arm template) TURN servers for load balancing (requires the external IP for each of the TURN server instances created in the previous step)
    1. Get the ip addresses from the previous step: `az network public-ip list -g azturntst-rly-rg`
    1. Create resource group for deployment: `az group create --name azturntst-rlylb-rg --location "Central US"`
    1. Update parameters as desired, namely set the following:
        1. `vmssName` - Unique name that will be used for various resources
        1. `instanceCount` - The number of servers that will be behind the Network load balancers
        1. `adminPublicKey` - The ssh public key that will be used to login to the machines (Default user is `turnroot`)
        1. `relayIPs` - A string containing space deliminated ip:port pairs for the relay servers (e.g. "24.55.76.33:3478 23.33.240.44:3478 36.34.243.55:3478")
        1. `relayImage` - The docker image that will be used (image created from 3dsrelaylb/)
    1. Deploy the template: `az group deployment create --resource-group "azturntst-rlylb-rg" --template-file 3dsrelaylb_arm\template.json --parameters @3dsrelaylb_arm\parameters.json --name azturntstrlylb`
    1. Get the public ip for it to use for client/server config: `az network public-ip list -g azturntst-rlylb-rg`

 

## Unix
1. Create and push docker images for turn server loadbalancer

1. Deploy (arm template) Azure PostgreSQL instance
    1. Create resource group for deployment `az group create --location 'Central US' --name 'azturntst-psql-rg'`
    1. Deploy: `az group deployment create --name 'psql' --template-file ./psql/template.json --parameters '@./psql/parameters.json' --parameters "{\"administratorLogin\": {\"value\": \"matthew\"}, \"administratorLoginPassword\":{\"value\": \"GoodPasswordMaybe?\"}, \"serverName\": {\"value\": \"azturntstpsqlsrv\"}}" --resource-group "azturntst-psql-rg"`
1. Create database in above instance that will be used for TURN
    1. Get connection string and set it to variable PSQL_COTURN_CS (the following command sets the result of program execution to variable in Unix bash, for Windows set the variable manually):

          ```sh
          PSQL_ADMIN_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv matthew "GoodPasswordMaybe?"`
          ```

    1. Add IP to Firewall rule list for DB in azure: go to azure portal, open db that was just created 
    1. Create database: `./dbsetup/create_turn_db.sh $PSQL_ADMIN_CS coturndb`
1. Apply the coturn schema to the above database
    1. Get connection string for new database and set it to variable PSQL_ADMIN_TDB_CS (the following command sets the result of program execution to variable in Unix bash, for Windows set the variable manually):

          ```sh
          PSQL_ADMIN_TDB_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv matthew "GoodPasswordMaybe?" coturndb`  
          ```
    1. Copy turnserver schema: `curl https://raw.githubusercontent.com/coturn/coturn/master/turndb/schema.sql > schema.sql`
    1. Apply schema: `./dbsetup/apply_schema_to_turn_db.sh $PSQL_ADMIN_TDB_CS ./schema.sql `
1. Create a role that can access the above database and related tables
    1. `./dbsetup/add_dbuser.sh $PSQL_ADMIN_TDB_CS coturn 'AnotherGoodPassword?' coturndb`
1. Using the 'admin' container image create users for clients that will use the relay (requires PSQL connection string)
    1. Create psql connection string for new user and set it to variable PSQL_COTURN_CS (the following command sets the result of program execution to variable in Unix bash, for Windows set the variable manually): 

          ```sh
          PSQL_COTURN_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv coturn "AnotherGoodPassword?" coturndb`  
          ```
    1. Turnserver can be authenticated either by 1) username/password or 2) temp passwords that are generated based on the shared secret. If you shoose the first path, add user: 
        `./dbsetup/add_turnuser.sh $PSQL_COTURN_CS user1 AGreatPassword azturntst.org` 
        If you shoose the second path, add shared secret:
        `./dbsetup/add_turnsecret.sh $PSQL_COTURN_CS AGreatSecret azturntst.org`

1. Deploy (arm template) N instances of TURN relay server (requires PSQL connection string, link to keyvault with certificate and default realm)

    Use this button to deploy to Azure and set parameters using Azure portal:
    [![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/anastasiia-zolochevska/coturn-to-azure-deployment/master/3dsrelay_arm/template.json)
    
Here are some parameters you'll need to specify:
 
        instanceCount - The number of turn servers that will be setup
        virtualMachineNamePrefix - The prefix used for various resources created (vm names, vnet, nsg, etc..)
        adminPublicKey - The ssh public key that will be used to login to the machines if needed (Default user is `turnroot`)
        diagnosticsStorageAccountName - Storage account that turn VMS will log diagnostics to
        postgreSqlConnectionString - Should be the same as the PSQL_COTURN_CS value above
        defaultTurnRealm - Ideally the same as the one configured for the users you added in the above step (e.g. azturntst.org)
        turnImage - The container image you created that runs the relay.  ([zolochevska/3dsrelay](https://hub.docker.com/r/zolochevska/3dsrelay/) or your image created from 3dsrelay/)
    
    
    1. Deploy the template: `az group deployment create --resource-group "azturntst-rly-rg" --template-file "3dsrelay_arm\template.json" --parameters "@3dsrelay_arm\parameters.json" --name "azturntstrly"`
1. Deploy (arm template) TURN servers for load balancing (requires the external IP for each of the TURN server instances created in the previous step)
    1. Get the ip addresses from the previous step: `az network public-ip list -g azturntst-rly-rg`
    1. Create resource group for deployment: `az group create --name azturntst-rlylb-rg --location "Central US"`
    1. Update parameters as desired, namely set the following:
        1. `vmssName` - Unique name that will be used for various resources
        1. `instanceCount` - The number of servers that will be behind the Network load balancers
        1. `adminPublicKey` - The ssh public key that will be used to login to the machines (Default user is `turnroot`)
        1. `relayIPs` - A string containing space deliminated ip:port pairs for the relay servers (e.g. "24.55.76.33:3478 23.33.240.44:3478 36.34.243.55:3478")
        1. `relayImage` - The docker image that will be used (image created from 3dsrelaylb/)
    1. Deploy the template: `az group deployment create --resource-group "azturntst-rlylb-rg" --template-file 3dsrelaylb_arm\template.json --parameters @3dsrelaylb_arm\parameters.json --name azturntstrlylb`
    1. Get the public ip for it to use for client/server config: `az network public-ip list -g azturntst-rlylb-rg`




Obviously still lots of work to automate this E2E and at some point there should be another amangement interface instead of a bunch of scripts talking directly to PSQL.
