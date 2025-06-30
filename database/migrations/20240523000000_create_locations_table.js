/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.up = function (knex) {
  return knex.schema.createTable("locations", function (table) {
    table.increments("id").primary();
    table.string("name", 255).notNullable();
    table.decimal("latitude", 9, 6).notNullable();
    table.decimal("longitude", 9, 6).notNullable();
    table.timestamps(true, true);
  });
};

/**
 * @param { import("knex").Knex } knex
 * @returns { Promise<void> }
 */
exports.down = function (knex) {
  return knex.schema.dropTable("locations");
};
