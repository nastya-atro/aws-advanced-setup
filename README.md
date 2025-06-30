# AWS Advanced Setup Project

This project demonstrates a robust and secure setup for a serverless application on AWS, featuring a decoupled architecture for infrastructure, database management, and application services.

## Project Structure

- `earthquake-import-serverless/`: A standalone SAM application.
- `database/`: A dedicated component for managing the database schema (migrations) and initial data (seeds) using Knex.js.
- `terraform/`: Contains all infrastructure-as-code definitions for shared resources, including the VPC, RDS, and service components.

---

## `earthquake-import-serverless`

This is a standalone, event-driven SAM application that periodically fetches raw earthquake data, processes it, and stores it in DynamoDB.

For detailed architecture and setup instructions, please see the service-specific documentation:
[**`earthquake-import-serverless/README.md`**](./earthquake-import-serverless/README.md)

---

## Database and `check-service` Infrastructure

This part of the project is managed by Terraform and consists of a secure backend environment.

### Core Components

- **VPC**: An isolated network with public and private subnets.
- **RDS**: A PostgreSQL database instance located in a private subnet, inaccessible from the public internet.
- **Lambda Migrator**: A Lambda function that automatically runs database migrations and seeds from the `database/` directory.
- **Secrets Manager**: Securely stores and manages the database master password.

### Connecting to the Private RDS Database

Direct access to the RDS instance is disabled for security. To connect using a local SQL client like DBeaver, you must use AWS Systems Manager (SSM) Session Manager to create a secure tunnel.

**Prerequisites:**

1.  **AWS CLI** installed and configured.
2.  **Session Manager Plugin** for the AWS CLI installed.
3.  A SQL client like **DBeaver** installed.

**Connection Steps:**

1.  **Deploy the Infrastructure:**
    Navigate to the `terraform/` directory and apply the configuration. This will create all necessary resources, including a temporary `t2.nano` bastion host for SSM.

    ```bash
    cd terraform
    terraform apply
    ```

2.  **Get Connection Details:**
    After `apply` completes, Terraform will output the necessary values:

    - `rds_endpoint`: The address of your database.
    - `bastion_instance_id`: The ID of the temporary EC2 host.

3.  **Retrieve the Database Password:**

    - Go to the **AWS Secrets Manager** console.
    - Find the secret named `adv-setup/db-credentials`.
    - Click "Retrieve secret value" to get the master password.

4.  **Start the SSM Tunnel:**
    Open a **new terminal window** and run the following command, substituting the values from the previous steps. This terminal must remain open while you work with the database.

    ```bash
    aws ssm start-session \
        --target <YOUR_BASTION_INSTANCE_ID> \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters '{"host":["<YOUR_RDS_ENDPOINT>"],"portNumber":["5432"], "localPortNumber":["5432"]}'
    ```

5.  **Connect in DBeaver:**
    - Create a new **PostgreSQL** connection.
    - On the "Main" tab, use the following settings:
      - **Host:** `localhost`
      - **Port:** `5432`
      - **Database:** `checkservicedb`
      - **Username:** `masteruser`
      - **Password:** The password retrieved from Secrets Manager.
    - Test and save the connection. You can now interact with the database as if it were local.

### Shutdown Procedure

1.  **Close the Tunnel:** In the terminal window running the SSM session, press `Ctrl + C`.
2.  **Destroy the Infrastructure:** To avoid incurring costs, tear down all resources when you are finished.
    ```bash
    cd terraform
    terraform destroy
    ```
