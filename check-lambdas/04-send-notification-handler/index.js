"use strict";

/**
 * This function is the final step for successful checks.
 * It receives the location data and sends a notification.
 * For now, it just logs the action.
 */
exports.handler = async (event) => {
  console.log("--- Send Notification Handler ---");
  console.log("Input event:", JSON.stringify(event, null, 2));

  const { location } = event;

  if (!location || !location.email) {
    throw new Error("Missing location or email in the input.");
  }

  // TODO: Implement actual email sending logic (e.g., using AWS SES)
  console.log(`Simulating sending email to ${location.email}...`);

  const result = {
    statusCode: 200,
    message: `Notification successfully sent to ${location.email}.`,
  };

  console.log(result.message);

  return result;
};
