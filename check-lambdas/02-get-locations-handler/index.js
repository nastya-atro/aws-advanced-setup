"use strict";

/**
 * This function is the first step in the state machine.
 * It receives an input like { "feature_id": "..." }.
 * It should connect to RDS, fetch a list of locations, and return them.
 * For now, it returns a hardcoded list for demonstration purposes.
 */
exports.handler = async (event) => {
  console.log("--- Get Locations Handler ---");
  console.log("Input event:", JSON.stringify(event, null, 2));

  const { feature_id } = event;

  if (!feature_id) {
    throw new Error("Missing feature_id in the input.");
  }

  // TODO: Replace this with actual RDS query logic
  const mockLocations = [
    { location_id: 1, name: "Location A", email: "belle.nastja@gmail.com" },
    { location_id: 2, name: "Location B", email: "belle.nastja+01@gmail.com" },
    { location_id: 3, name: "Location C", email: "belle.nastja+02@gmail.com" },
  ];

  console.log(
    `Returning ${mockLocations.length} locations for feature_id: ${feature_id}`
  );

  return {
    feature_id: feature_id,
    locations: mockLocations,
  };
};
