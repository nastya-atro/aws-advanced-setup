/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.seed = async function (knex) {
  // Deletes ALL existing entries
  await knex("locations").del();

  // Inserts seed entries
  await knex("locations").insert([
    {
      name: "Moscow",
      latitude: 55.7558,
      longitude: 37.6173,
      email: "belle.nastja@gmail.com",
    },
    {
      name: "New York",
      latitude: 40.7128,
      longitude: -74.006,
      email: "chevoska.dev@gmail.com",
    },
    {
      name: "London",
      latitude: 51.5074,
      longitude: -0.1278,
      email: "a.atroshchanka.work@gmail.com",
    },
    {
      name: "Tokyo",
      latitude: 35.6895,
      longitude: 139.6917,
      email: "belle.nastja@gmail.com",
    },
    {
      name: "Sydney",
      latitude: -33.8688,
      longitude: 151.2093,
      email: "chevoska.dev@gmail.com",
    },
    {
      name: "Paris",
      latitude: 48.8566,
      longitude: 2.3522,
      email: "a.atroshchanka.work@gmail.com",
    },
    {
      name: "Cairo",
      latitude: 30.0444,
      longitude: 31.2357,
      email: "belle.nastja@gmail.com",
    },
    {
      name: "Rio de Janeiro",
      latitude: -22.9068,
      longitude: -43.1729,
      email: "chevoska.dev@gmail.com",
    },
    {
      name: "Beijing",
      latitude: 39.9042,
      longitude: 116.4074,
      email: "a.atroshchanka.work@gmail.com",
    },
    {
      name: "New Delhi",
      latitude: 28.6139,
      longitude: 77.209,
      email: "belle.nastja@gmail.com",
    },
  ]);
};
