module DbAgent
  class DbHandler
    class Composite < DbHandler

      def each_db_handler
        database_names.each do |name|
          yield(name, self.fork_config(database: name).fork({
            databases: nil,
            backup: @backup_folder/name,
            schema: @schema_folder/name,
            migrations: @migrations_folder/name,
          }))
        end
      end

      def database_names
        case dbs = options[:databases]
        when '/from-empty-seeds'
          (data_folder/'empty').glob('*').filter{|f| f.directory? }.map{|f| f.basename.to_s }
        when NilClass
          [config[:database]]
        else
          dbs.split(/\s*,\s*/)
        end
      end

      Actions.public_instance_methods.each do |meth|
        define_method(meth) do |*args, &bl|
          each_db_handler do |dbname, db|
            db.send(meth, *args, &bl)
          end
        end
      end

      def seeder(database_suffix = nil)
        Seeder::Composite.new(self)
      end

    end # class Composite
  end # class DbHandler
end # module DbAgent
