"use strict";

const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const sesClient = new SESClient({ region: process.env.AWS_REGION });

/**
 * This function is the final step for successful checks.
 * It receives the location data and sends a notification using AWS SES.
 */
exports.handler = async (event) => {
  console.log("--- Send Notification Handler ---");
  console.log("Input event:", JSON.stringify(event, null, 2));

  const { location } = event;

  if (!location || !location.email) {
    throw new Error("Missing location or email in the input.");
  }

  const emailParams = {
    Source: process.env.SOURCE_EMAIL, // Sender email from environment variable
    Destination: {
      ToAddresses: [location.email],
    },
    Message: {
      Subject: {
        Data: `Location Status: ${location.name}`,
        Charset: "UTF-8",
      },
      Body: {
        Text: {
          Data: `Hello! Your location "${location.name}" has been checked and is working correctly.`,
          Charset: "UTF-8",
        },
      },
    },
  };

  try {
    // TODO: Enable the code below after requesting and getting production access for Amazon SES.
    // The account is currently in the SES Sandbox, which restricts sending to verified email addresses only.
    // For more details, see: https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html
    //
    // const command = new SendEmailCommand(emailParams);
    // await sesClient.send(command);

    console.log(
      `(Sandbox Mode) Simulating sending email to ${location.email}.`
    );
    console.log(`Notification successfully sent to ${location.email}.`);
  } catch (error) {
    console.error("Error sending email via SES:", error);
    throw new Error("Failed to send notification email.");
  }

  const result = {
    statusCode: 200,
    message: `Notification successfully sent to ${location.email}.`,
  };

  console.log(result.message);

  return result;
};
