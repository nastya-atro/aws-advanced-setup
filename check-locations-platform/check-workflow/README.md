# Check Workflow Handlers

This directory contains the source code for the individual AWS Lambda functions that constitute the platform's workflows. The workflows themselves are orchestrated by AWS Step Functions.

The handlers are organized into subdirectories based on the business workflow they belong to.

## Directories

### `/proactive_monitoring_handlers`

Contains the set of Lambda functions that are part of the proactive monitoring workflow. This workflow periodically checks all known locations against new events. See the [README](./proactive_monitoring_handlers/README.md) inside for more details.

### `/on_demand_check_handlers`

Contains the Lambda functions for the on-demand workflow, which is triggered via the API to check a single location. See the [README](./on_demand_check_handlers/README.md) inside for more details.

### `/shared_handlers`

Contains common Lambda functions that are reused across multiple workflows, such as the `send-notification` handler.
