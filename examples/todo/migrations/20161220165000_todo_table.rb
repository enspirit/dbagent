Sequel.migration do
  up do
    run <<-SQL
      CREATE TABLE todo (
        id          SERIAL       NOT NULL,
        title       VARCHAR(255) NOT NULL,
        description TEXT         NOT NULL,
        done        BOOLEAN      NOT NULL DEFAULT false,
        PRIMARY KEY (id)
      )
    SQL
  end
end
