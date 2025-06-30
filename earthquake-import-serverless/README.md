# `earthquake-import-serverless`

This is a fully serverless application designed to periodically fetch, process, and store earthquake data from an external source. It is built using the AWS Serverless Application Model (SAM).

## Architecture

The application follows a decoupled, event-driven architecture:

1.  **Scheduled Trigger**: An **Amazon EventBridge (Schedule)** rule triggers the fetcher function every hour.
2.  **Fetcher Lambda**: The `FetcherFunction` is invoked, which calls an external earthquake data API, and saves the raw JSON response to a dedicated S3 bucket.
3.  **Fan-out Notification**: Upon object creation in the S3 bucket, an event notification is published to an **Amazon SNS** topic. Using SNS decouples the S3 event producer from any number of consumers.
4.  **Processor Lambda**: The `ProcessorFunction`, subscribed to the SNS topic, is invoked with the event details. It retrieves the raw data file from S3, processes it, and stores the structured data into an **Amazon DynamoDB** table.
5.  **Error Handling**: Both Lambda functions are configured with a Dead-Letter Queue (DLQ) using **Amazon SQS**. Any failed invocations are sent to this queue for later analysis and reprocessing.

![Architecture Diagram](https://user-images.githubusercontent.com/12345/some-image-url.png) <!-- TODO: Replace with a real diagram -->

### AWS Services Used

- **AWS Lambda**: For compute logic (fetching and processing).
- **Amazon S3**: For storing raw data.
- **Amazon DynamoDB**: For storing processed, structured data.
- **Amazon EventBridge (Scheduler)**: To trigger the import process on a recurring schedule.
- **Amazon SNS**: To decouple the data ingestion and processing steps.
- **Amazon SQS**: For dead-letter queueing and error handling.
- **AWS IAM**: To provide fine-grained permissions for each component.
- **AWS CloudFormation (via SAM)**: To define and deploy the infrastructure.

## How to Work with This Service

### Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
- [AWS SAM CLI](https://aws.amazon.com/serverless/sam/) installed.
- [Node.js](https://nodejs.org/en/) (version 20.x) and npm installed.
- [Docker](https://www.docker.com/) (optional, for local testing).

### Project Setup

Install the dependencies for both Lambda functions:

```bash
# From the root of this service (earthquake-import-serverless/)
npm install --prefix src/fetcher/
npm install --prefix src/processor/
```

### Build

To build the application, run the following command from the `earthquake-import-serverless/` directory. The SAM CLI will package the application code and dependencies into a format ready for deployment.

```bash
sam build
```

### Deployment

To deploy the application to your AWS account for the first time, run the guided deployment command:

```bash
sam deploy --guided
```

The CLI will prompt you for several parameters, such as a Stack Name (e.g., `earthquake-import-service`), AWS Region, and confirmation for creating IAM roles. These settings will be saved to a `samconfig.toml` file for future deployments.

For subsequent deployments, you can simply run:

```bash
sam deploy
```
