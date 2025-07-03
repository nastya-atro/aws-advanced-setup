# Check Locations Platform

This directory contains the source code and infrastructure definitions for the Check Locations Platform.

The platform consists of several key components. Each component has its own `README.md` with detailed instructions.

## Components

- **`/terraform`**:
  Contains all infrastructure-as-code definitions. See the [**Terraform README**](./terraform/README.md) for instructions on how to deploy the platform.

- **`/db_migrator`**:
  Contains the database migration and seeding logic. See the [**DB Migrator README**](./db_migrator/README.md) for instructions on running migrations and connecting to the database.

- **`/check-service`**:
  An API service that acts as the entry point to the system. See the [**Check Service README**](./check-service/README.md) for API usage details.

- **`/check-workflow`**:
  Contains the source code for the individual Lambda functions that form the Step Functions workflow.

- **`build-artifacts.sh`**:
  A script to package all application code into deployable zip artifacts. See the [Terraform README](./terraform/README.md) for usage.
