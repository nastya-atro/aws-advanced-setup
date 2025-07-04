// This Lambda function is the first step in the on-demand check workflow.
// It receives a user's location and email, scans DynamoDB for all events,
// and (for now) returns a hardcoded "success" response.

// const { DynamoDBClient, ScanCommand } = require("@aws-sdk/client-dynamodb");
// const client = new DynamoDBClient({});

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  const { latitude, longitude, email, name } = event;

  // TODO: Implement actual scanning and checking logic.
  // For now, we simulate a successful check where the location is affected.
  const isAffected = true;

  console.log(
    `Location (${latitude}, ${longitude}) check result: affected=${isAffected}`
  );

  // This is the output that will be passed to the next step in the Step Function.
  return {
    isAffected,
    location: {
      latitude,
      longitude,
      email,
      name,
    },
    message: `Location ${name} (${latitude}, ${longitude}) was found to be affected.`,
  };
};
