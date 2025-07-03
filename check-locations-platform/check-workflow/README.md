# Check Workflow Lambdas

This directory contains the source code for the individual AWS Lambda functions that constitute the location checking workflow. The workflow is orchestrated by a Step Function state machine.

## Workflow Overview

The primary purpose of this workflow is to check a given geographic location against a database of known weather events and notify a user via email if their location is affected.

The process is as follows:

1.  **Trigger**: An external event (e.g., an API call to `check-service` or a scheduled event) starts the workflow.
2.  **Get Locations**: The workflow retrieves relevant location data from the RDS database.
3.  **Process Locations (Map State)**: For each location, the workflow performs the following steps in parallel:
    a. **Check Location**: The location's coordinates are checked against a dataset of weather events stored in DynamoDB.
    b. **Decision**: Based on the check, the workflow decides if a notification is needed.
    c. **Send Notification**: If needed, an email is sent to the user via Amazon SES.

## Lambda Functions

This directory contains the handlers for each step:

### `01-notify-trigger-handler`

- **Purpose**: Acts as the main trigger for the `NotifyLocationsWorkflow` Step Function. It receives an event (e.g., from an SQS queue or an EventBridge schedule) and initiates a new state machine execution.

### `02-get-locations-handler`

- **Purpose**: The first task in the state machine. It connects to the RDS database and fetches the list of locations that need to be checked.
- **Input**: The initial payload from the trigger.
- **Output**: A JSON object containing an array of locations.

### `03-check-location-handler`

- **Purpose**: This function runs for each individual location within the Map state. It takes a location's data and checks it against the weather event data stored in the `EarthquakeData` DynamoDB table.
- **Input**: A single location object.
- **Output**: A status indicating if the location is affected.

### `04-send-notification-handler`

- **Purpose**: The final step for an affected location. It receives the check result and the user's email address. It then uses Amazon SES (Simple Email Service) to send a notification email.
- **Input**: The result from the `check-location-handler`.
- **Output**: The result of the `ses:SendEmail` API call.
