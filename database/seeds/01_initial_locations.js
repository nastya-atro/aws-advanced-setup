/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex("locations").del();

  // Inserts seed entries
  await knex("locations").insert([
    { name: "Moscow", latitude: 55.7558, longitude: 37.6173 },
    { name: "New York", latitude: 40.7128, longitude: -74.006 },
    { name: "London", latitude: 51.5074, longitude: -0.1278 },
    { name: "Tokyo", latitude: 35.6895, longitude: 139.6917 },
    { name: "Sydney", latitude: -33.8688, longitude: 151.2093 },
    { name: "Paris", latitude: 48.8566, longitude: 2.3522 },
    { name: "Cairo", latitude: 30.0444, longitude: 31.2357 },
    { name: "Rio de Janeiro", latitude: -22.9068, longitude: -43.1729 },
    { name: "Beijing", latitude: 39.9042, longitude: 116.4074 },
    { name: "New Delhi", latitude: 28.6139, longitude: 77.209 },
  ]);
};
