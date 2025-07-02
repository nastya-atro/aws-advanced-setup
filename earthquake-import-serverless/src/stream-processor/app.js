const { SQSClient, SendMessageCommand } = require("@aws-sdk/client-sqs");
const { unmarshall } = require("@aws-sdk/util-dynamodb");

const sqsClient = new SQSClient({});
const SQS_QUEUE_URL = process.env.SQS_QUEUE_URL;

exports.handler = async (event) => {
  console.log(
    "Stream processor started. Event:",
    JSON.stringify(event, null, 2)
  );

  const promises = event.Records.map(async (record) => {
    // We are only interested in new items
    if (record.eventName !== "INSERT") {
      console.log(`Skipping event ${record.eventName}`);
      return;
    }

    console.log("DynamoDB Record:", JSON.stringify(record.dynamodb, null, 2));

    // The data from the stream is in DynamoDB JSON format, so we unmarshall it
    const fullRecord = unmarshall(record.dynamodb.NewImage);

    // We only want to send the feature_id
    const messagePayload = {
      feature_id: fullRecord.id, // Assuming the feature_id is stored in the 'id' attribute
    };

    const params = {
      QueueUrl: SQS_QUEUE_URL,
      MessageBody: JSON.stringify(messagePayload),
    };

    try {
      await sqsClient.send(new SendMessageCommand(params));
      console.log(
        `Successfully sent message to SQS for eventId ${record.eventID}`
      );
    } catch (error) {
      console.error("Error sending message to SQS:", error);
      // Depending on requirements, you might want to re-throw the error
      // to let the Lambda invocation fail and be reprocessed.
    }
  });

  await Promise.all(promises);

  return { statusCode: 200, body: "Stream processed successfully." };
};
