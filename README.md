# azturnlb
Scripts and Config for deploying load balanced Coturn servers in Azure

Very much a work in progress. 


Rough Steps:
1. Create and push docker images for turnserver (you can use zolochevska/3dsrelay), turn server loadbalancer, and turnadmin (you can use zolochevska/3dsrelayadmin)

1. Deploy (arm template) Azure PostgreSQL instance
    1. Create resource group for deployment `az group create --location 'Central US' --name 'azturntst-psql-rg'`
    1. Deploy: `az group deployment create --name 'psql' --template-file ./psql/template.json --parameters '@./psql/parameters.json' --parameters "{\"administratorLogin\": {\"value\": \"matthew\"}, \"administratorLoginPassword\":{\"value\": \"GoodPasswordMaybe?\"}, \"serverName\": {\"value\": \"azturntstpsqlsrv\"}}" --resource-group "azturntst-psql-rg"`
1. Create database in above instance that will be used for TURN
    1. Get connection string: 

          ```sh
          PSQL_ADMIN_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv matthew "GoodPasswordMaybe?"`
          ```

    1. Add IP to Firewall rule list for DB (or run in azure?)
    1. Create database: `./dbsetup/create_turn_db.sh $PSQL_ADMIN_CS coturndb`
1. Apply the coturn schema to the above database
    1. Get connection string for new database:

          ```sh
          PSQL_ADMIN_TDB_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv matthew "GoodPasswordMaybe?" coturndb`  
          ```
    1. Copy turnserver schema: `curl https://raw.githubusercontent.com/coturn/coturn/master/turndb/schema.sql > schema.sql`
    1. Apply schema: `./dbsetup/apply_schema_to_turn_db.sh $PSQL_ADMIN_TDB_CS ./schema.sql `
1. Create a role that can access the above database and related tables
    1. `./dbsetup/add_dbuser.sh $PSQL_ADMIN_TDB_CS coturn 'AnotherGoodPassword?' coturndb`
1. Using the 'admin' container image create users for clients that will use the relay (requires PSQL connection string)
    1. Create psql connection string for new user: 

          ```sh
          PSQL_COTURN_CS=``./dbsetup/get_psql_connectionstring.sh azturntstpsqlsrv coturn "AnotherGoodPassword?" coturndb`  
          ```
    1. Add user: `./dbsetup/add_turnuser.sh $PSQL_COTURN_CS user1 AGreatPassword azturntst.org`

1. Deploy (arm template) N instances of TURN relay server (requires PSQL connection string and default realm)
    1. Create Resource group: `az group create --name "azturntst-rly-rg" --location "Central US"`
    1. Edit parameters as desired, namely set the following:
        1. `instanceCount` - The number of turn servers that will be setup
        1. `virtualMachineNamePrefix` - The prefix used for various resources created (vm names, vnet, nsg, etc..)
        1. `adminPublicKey` - The ssh public key that will be used to login to the machines if needed (Default user is `turnroot`)
        1. `diagnosticsStorageAccountName` - Storage account that turn VMS will log diagnostics to
        1. `postgreSqlConnectionString` - Should be the same as the PSQL_COTURN_CS value above
        1. `defaultTurnRealm` - Ideally the same as the one configured for the users you added in the above step (e.g. azturntst.org)
        1. `turnImage` - The container image you created that runs the relay.  (image created from 3dsrelay/)
    1. Deploy the template: `az group deployment create --resource-group "azturntst-rly-rg" --template-file 3dsrelay_arm\template.json --parameters "@3dsrelay_arm\parameters.json" --name "azturntstrly"`
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
1. Done?



Obviously still lots of work to automate this E2E and at some point there should be another amangement interface instead of a bunch of scripts talking directly to PSQL.
