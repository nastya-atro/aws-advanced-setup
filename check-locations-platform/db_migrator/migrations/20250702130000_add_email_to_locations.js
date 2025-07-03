exports.up = function (knex) {
  return knex.schema.table("locations", function (table) {
    table.string("email");
  });
};

exports.down = function (knex) {
  return knex.schema.table("locations", function (table) {
    table.dropColumn("email");
  });
};
