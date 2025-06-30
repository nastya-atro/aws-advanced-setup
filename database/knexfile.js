module.exports = {
  development: {
    client: "pg",
    connection: {
      // These values will be provided to the Lambda via environment variables
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      // SSL may be required for connecting to RDS
      ssl: { rejectUnauthorized: false },
    },
    migrations: {
      directory: "./migrations",
    },
    seeds: {
      directory: "./seeds",
    },
  },
};
