# Check Workflow Handlers

This directory contains the source code for the individual AWS Lambda functions that constitute the platform's workflows. The workflows themselves are orchestrated by AWS Step Functions.

Below is a description of each handler's role in the system.

---

## Proactive Monitoring Handlers

These functions are part of the scheduled workflow that periodically checks all known locations.

### `00-trigger-handler`

This is not currently used in the main workflow but is designed to manually trigger the proactive monitoring workflow for testing purposes.

### `01-get-locations` (`GetLocationsHandler`)

- **Triggered by:** The start of the `NotifyLocationsWorkflow`.
- **Purpose:** Connects to the RDS database to fetch the complete list of user locations that require monitoring.
- **Output:** An array of location objects.

### `02-check-location` (`CheckLocationHandler`)

- **Triggered by:** The `Map` state within the `NotifyLocationsWorkflow` for each location.
- **Purpose:** Receives a single location object. It queries the DynamoDB events table to determine if the location is affected by any known events.
- **Output:** A boolean flag `isAffected` along with the original location data.

---

## On-Demand Check Handlers

These functions are part of the API-driven workflow that checks a single location provided by a user.

### `01-check-location-against-events` (`OnDemandCheckHandler`)

- **Triggered by:** The `OnDemandCheckWorkflow` after a user makes a request to the API.
- **Purpose:** Similar to the proactive `CheckLocationHandler`, this function takes a single location from the user's request and checks it against the DynamoDB events table.
- **Output:** A JSON object containing the `isAffected` flag and details for the notification.

---

## Shared Handlers

These are common functions reused across multiple workflows.

### `send-notification` (`SendNotificationHandler`)

- **Triggered by:** Both the `NotifyLocationsWorkflow` and the `OnDemandCheckWorkflow` if a location is found to be affected.
- **Purpose:** Receives location and user details. It uses Amazon SES (Simple Email Service) to send an email notification to the user.
- **Output:** The result of the SES API call.
