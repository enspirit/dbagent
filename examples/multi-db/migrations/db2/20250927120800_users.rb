Sequel.migration do
  up do
    run <<-SQL
      CREATE TABLE users (
        id          SERIAL       NOT NULL,
        name        VARCHAR(255) NOT NULL,
        PRIMARY KEY (id)
      );
    SQL
  end
end
