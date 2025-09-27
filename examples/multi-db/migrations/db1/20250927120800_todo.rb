Sequel.migration do
  up do
    run <<-SQL
      CREATE TABLE todo (
        id          SERIAL       NOT NULL,
        title       VARCHAR(255) NOT NULL,
        PRIMARY KEY (id)
      );
    SQL
  end
end
