"use strict";

const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");
const knex = require("knex");

let dbClient = null;

/**
 * Get database credentials from AWS Secrets Manager
 */
async function getDbCredentials() {
  const secretsClient = new SecretsManagerClient({});
  const secretName = process.env.DB_SECRET_NAME;

  if (!secretName) {
    throw new Error("DB_SECRET_NAME environment variable is not set");
  }

  try {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await secretsClient.send(command);
    return JSON.parse(response.SecretString);
  } catch (error) {
    console.error("Error getting database credentials:", error);
    throw error;
  }
}

/**
 * Initialize database connection
 */
async function initDbConnection() {
  if (dbClient) {
    return dbClient;
  }

  const credentials = await getDbCredentials();

  dbClient = knex({
    client: "pg",
    connection: {
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME,
      user: credentials.username,
      password: credentials.password,
      ssl: { rejectUnauthorized: false },
    },
    pool: {
      min: 0,
      max: 1, // Lambda functions are single-threaded, so we only need 1 connection
    },
  });

  return dbClient;
}

/**
 * Get locations from the database
 */
async function getLocationsFromDb(featureId) {
  const db = await initDbConnection();

  try {
    // Get all locations from the database
    // Note: In the future, you might want to filter by feature_id
    // if there's a relationship between features and locations
    const locations = await db("locations")
      .select("id as location_id", "name", "email")
      .where("email", "is not", null) // Only get locations with email addresses
      .orderBy("id");

    console.log(`Found ${locations.length} locations in database`);
    return locations;
  } catch (error) {
    console.error("Error querying database:", error);
    throw error;
  }
}

/**
 * This function is the first step in the state machine.
 * It receives an input like { "feature_id": "..." }.
 * It connects to RDS, fetches a list of locations, and returns them.
 */
exports.handler = async (event) => {
  console.log("--- Get Locations Handler ---");
  console.log("Input event:", JSON.stringify(event, null, 2));

  const { feature_id } = event;

  if (!feature_id) {
    throw new Error("Missing feature_id in the input.");
  }

  try {
    // Get locations from PostgreSQL database
    const locations = await getLocationsFromDb(feature_id);

    console.log(
      `Returning ${locations.length} locations for feature_id: ${feature_id}`
    );

    return {
      feature_id: feature_id,
      locations: locations,
    };
  } catch (error) {
    console.error("Handler error:", error);
    throw error;
  } finally {
    // Clean up database connection
    if (dbClient) {
      await dbClient.destroy();
      dbClient = null;
    }
  }
};
