# Database Migrator

This component contains the logic for managing the database schema. It uses `knex.js` to run migrations and seeds via a Lambda function.

---

## Running Database Migrations

After the infrastructure is deployed, the database will be empty. The `db_migrator` Lambda function is responsible for running database migrations (to create tables) and seeds (to insert initial data).

You must invoke this Lambda manually after the first deployment or whenever you add new migrations.

**Steps to run migrations:**

1.  **Navigate to the AWS Lambda Console.**
2.  **Find the Migrator Lambda:** In the functions list, find the function named `check-locations-platform-db_migrator` (the prefix may vary based on the `project_name` Terraform variable).
3.  **Configure a Test Event:**
    - Go to the **Test** tab.
    - Create a new event. You can name it `RunMigration`.
    - The content of the event determines whether seeds are run along with migrations.
    - **To run migrations ONLY**, use an empty JSON object:
      ```json
      {}
      ```
    - **To run migrations AND seeds**, use the following JSON payload:
      ```json
      {
        "runSeeds": true
      }
      ```
    - Save the event.
4.  **Run the Test:**
    - Click the **Test** button.
    - The function will execute. This may take a few moments as it needs to establish a connection to the RDS instance within the VPC.
5.  **Check the Logs:**
    - The execution results will appear. Expand the **Log output** section.
    - Look for messages from `knex` indicating that migrations and seeds have run successfully. If there are any errors, they will be visible in these logs.

Once the migrations have run, your database schema will be up to date.

---

## Connecting to the Private RDS Database

Direct access to the RDS instance is disabled for security. To connect using a local SQL client like DBeaver, you must use AWS Systems Manager (SSM) Session Manager to create a secure tunnel.

**Prerequisites:**

1.  **AWS CLI** installed and configured.
2.  **Session Manager Plugin** for the AWS CLI installed.
3.  A bastion host deployed by the Terraform configuration.

**Connection Steps:**

1.  **Get Connection Details from Terraform Output:**
    After `terraform apply` completes, Terraform will output the necessary values:

    - `rds_endpoint`: The address of your database.
    - `bastion_instance_id`: The ID of the temporary EC2 host for tunneling.

2.  **Retrieve the Database Password:**

    - Go to the **AWS Secrets Manager** console.
    - Find the secret named `check-locations-platform/db_credentials` (the name may vary based on the `project_name` variable).
    - Click "Retrieve secret value" to get the master password.

3.  **Start the SSM Tunnel:**
    Open a **new terminal window** and run the following command, substituting the values from the previous steps. This terminal must remain open while you work with the database.

    ```bash
    aws ssm start-session \
        --target <YOUR_BASTION_INSTANCE_ID> \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters '{"host":["<YOUR_RDS_ENDPOINT>"],"portNumber":["5432"], "localPortNumber":["5432"]}'
    ```

4.  **Connect in a SQL Client (e.g., DBeaver):**
    - Create a new **PostgreSQL** connection.
    - On the "Main" tab, use the following settings:
      - **Host:** `localhost`
      - **Port:** `5432`
      - **Database:** `checklocationsdb` (or as defined in `variables.tf`)
      - **Username:** `masteruser` (or as defined in `variables.tf`)
      - **Password:** The password retrieved from Secrets Manager.
    - Test and save the connection. You can now interact with the database as if it were local.

### Shutdown Procedure

1.  **Close the Tunnel:** In the terminal window running the SSM session, press `Ctrl + C`.
