"use strict";

/**
 * This function is executed for each location in the Map state.
 * It receives an input containing one location and the original feature_id.
 * It should fetch data from DynamoDB and perform custom checks.
 * For now, it just logs the data and returns a success status.
 */
exports.handler = async (event) => {
  console.log("--- Check Location Handler ---");
  console.log("Input event:", JSON.stringify(event, null, 2));

  const { location, feature_id } = event;

  if (!location || !feature_id) {
    throw new Error("Missing location or feature_id in the input.");
  }

  // TODO: Implement actual DynamoDB fetch and custom logic
  console.log(
    `Checking location "${location.name}" for feature_id: ${feature_id}`
  );

  // Simulate a successful check
  const checkResult = {
    isAffected: false, // In the proactive flow, "success" means not affected.
    message: `Check for ${location.name} completed successfully.`,
    location: location, // Pass the location data to the next step
  };

  console.log("Check result:", checkResult);

  return checkResult;
};
