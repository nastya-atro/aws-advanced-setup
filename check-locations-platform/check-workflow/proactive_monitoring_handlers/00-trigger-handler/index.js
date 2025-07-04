"use strict";

const { SFNClient, StartExecutionCommand } = require("@aws-sdk/client-sfn");
const sfnClient = new SFNClient({});

const STATE_MACHINE_ARN = process.env.STATE_MACHINE_ARN;

exports.handler = async (event) => {
  console.log("--- Notify Trigger Handler started ---");
  console.log(JSON.stringify(event, null, 2));

  const executionPromises = event.Records.map(async (record) => {
    try {
      const body = JSON.parse(record.body);
      const featureId = body.feature_id;

      if (!featureId) {
        console.error("Missing feature_id in SQS message body:", record.body);
        return; // Skip this record
      }

      // The execution name has a max length of 80 chars and can only contain letters, numbers, and -_.
      // We truncate the featureId and replace invalid characters.
      const sanitizedId = featureId.replace(/[^a-zA-Z0-9-]/g, "_");
      const safeFeatureId = sanitizedId.substring(0, 40);

      const input = {
        feature_id: featureId,
      };

      const params = {
        stateMachineArn: STATE_MACHINE_ARN,
        input: JSON.stringify(input),
        // Use the truncated and sanitized featureId for the name
        name: `exec-${safeFeatureId}-${Date.now()}`,
      };

      console.log(`Starting Step Function execution with input:`, input);
      const command = new StartExecutionCommand(params);
      await sfnClient.send(command);

      console.log(
        `Successfully started Step Function for feature_id: ${featureId}`
      );
    } catch (error) {
      console.error("Failed to process record and start Step Function:", error);
      // Re-throw the error to ensure the SQS message is not deleted and will be retried
      throw error;
    }
  });

  await Promise.all(executionPromises);

  return {
    statusCode: 200,
    body: JSON.stringify("Successfully triggered Step Function executions."),
  };
};
