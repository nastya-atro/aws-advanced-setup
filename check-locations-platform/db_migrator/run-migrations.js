const knex = require("knex");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");
const knexConfigTemplate = require("./knexfile").development;

// Create a client for Secrets Manager
const secretsManagerClient = new SecretsManagerClient({
  region: process.env.AWS_REGION,
});

// Function to retrieve the secret
async function getDbPassword() {
  const command = new GetSecretValueCommand({
    SecretId: process.env.DB_CREDENTIALS_SECRET_ARN,
  });

  try {
    const data = await secretsManagerClient.send(command);
    if ("SecretString" in data) {
      const secret = JSON.parse(data.SecretString);
      return secret.password;
    }
  } catch (error) {
    console.error("Error fetching secret from Secrets Manager:", error);
    throw error;
  }
}

exports.handler = async (event) => {
  console.log("Starting database migration process...");
  let db;

  try {
    // 1. Retrieve the password from Secrets Manager
    const password = await getDbPassword();
    if (!password) {
      throw new Error(
        "Failed to retrieve database password from Secrets Manager."
      );
    }
    console.log("Successfully retrieved DB password from Secrets Manager.");

    // 2. Build the full configuration for Knex
    const knexConfig = {
      ...knexConfigTemplate,
      connection: {
        ...knexConfigTemplate.connection,
        password: password, // Use the retrieved password
      },
    };

    // 3. Initialize Knex and run migrations/seeds
    db = knex(knexConfig);

    console.log("Running migrations...");
    const migrateResult = await db.migrate.latest();
    console.log("Migration result:", migrateResult);

    // By default, we don't run seeds.
    // Seeds should only be run during initial setup or when explicitly required.
    // To run, pass { "runSeeds": true } in the Lambda invocation payload.
    if (event.runSeeds === true) {
      console.log("Running seeds...");
      const seedResult = await db.seed.run();
      console.log("Seed result:", seedResult);
    }

    console.log("Process completed successfully.");
    return {
      statusCode: 200,
      body: JSON.stringify("Migrations and seeds processed successfully."),
    };
  } catch (error) {
    console.error("FATAL: Error during database migration process:", error);
    // Throw an error to fail the Lambda execution, which is crucial for CI/CD pipelines.
    throw new Error(`Migration failed: ${error.message}`);
  } finally {
    // Ensure the database connection is always destroyed.
    if (db) {
      await db.destroy();
      console.log("Database connection destroyed.");
    }
  }
};
