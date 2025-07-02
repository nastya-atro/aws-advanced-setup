"use strict";

exports.handler = async (event) => {
  console.log("--- SQS Event Received ---");

  for (const record of event.Records) {
    console.log("\n--- Processing Record ---");
    console.log(`Message ID: ${record.messageId}`);

    const body = record.body;
    if (body) {
      try {
        const parsedBody = JSON.parse(body);
        console.log("\nMessage Body (parsed JSON):");
        console.log(JSON.stringify(parsedBody, null, 2));
      } catch (error) {
        // Not a JSON string, already printed the raw version
        console.log("(Body is not a valid JSON string)");
      }
    }
    console.log("--- End of Record ---\n");
  }

  return {
    statusCode: 200,
    body: JSON.stringify("Successfully processed SQS messages."),
  };
};
