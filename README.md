# azturnlb
Scripts and Config for deploying load balanced Coturn servers in Azure

Very much a work in progress. 


Rough Steps:
1. Create and push docker images for turnserver, turn server loadbalancer, and turnadmin
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
1. Deploy (arm template) TURN servers for load balancing (requires the external IP for each of the TURN server instances created in the previous step)
1. Done?



Obviously still lots of work to automate this E2E and at some point there should be another amangement interface instead of a bunch of scripts talking directly to PSQL.
