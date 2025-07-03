# Terraform Infrastructure

This directory contains all the Terraform configurations for the Check Locations Platform.

## Deploying the Infrastructure

Deploying the platform is a two-step process: building the application artifacts and then applying the Terraform configuration.

### Prerequisites

- AWS CLI installed and configured.
- Terraform installed.
- Node.js and npm installed (for the build script).

### Step 1: Build Deployable Artifacts

Before running Terraform, you must build the application source code into zip archives. These archives will be placed in the `artifacts/` directory at the root of the platform.

From the root of the `check-locations-platform` directory, run the build script:

```bash
../build-artifacts.sh
```

_Note: The command is `../build-artifacts.sh` because you are running it from within the `terraform` directory._

Alternatively, from the `check-locations-platform` directory:

```bash
./build-artifacts.sh
```

### Step 2: Run Terraform

Once the artifacts are built, you can deploy the infrastructure.

1.  **Navigate to this directory (`terraform`).**

2.  **Initialize Terraform:**
    This downloads the necessary providers. You only need to do this once.

    ```bash
    terraform init
    ```

3.  **Plan the deployment:**
    This command shows you what resources will be created. You will need to provide the API key for the `check-service`.

    ```bash
    terraform plan -var="check_service_api_key=YOUR_SUPER_SECRET_API_KEY"
    ```

4.  **Apply the configuration:**
    This command creates the resources in your AWS account.
    ```bash
    terraform apply -var="check_service_api_key=YOUR_SUPER_SECRET_API_KEY"
    ```
