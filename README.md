# AWS Advanced Setup Project

This project demonstrates a robust and secure setup for a serverless application on AWS, featuring a decoupled architecture for infrastructure, database management, and application services.

## Project Components

This monorepo contains two primary components:

### 1. `check-locations-platform`

A comprehensive platform managed by Terraform that provides location-based event checking. It has two primary functions:

1.  **Proactive Monitoring:** The service listens for new weather events (specifically earthquakes in this implementation) and automatically checks if any locations stored in the system are affected, notifying users immediately.
2.  **On-Demand Checks:** It provides an API for users to submit a location and check it against the current database of events.

The platform includes a secure backend environment (VPC, RDS), a Step Functions workflow for processing the checks, and an API service.

For detailed architecture, setup, and usage instructions, please see the platform-specific documentation:
[**`check-locations-platform/README.md`**](./check-locations-platform/README.md)

### 2. `earthquake-import-serverless`

This is a standalone, event-driven SAM application that periodically fetches raw earthquake data, processes it, and stores it in DynamoDB.

For detailed architecture and setup instructions, please see the service-specific documentation:
[**`earthquake-import-serverless/README.md`**](./earthquake-import-serverless/README.md)
