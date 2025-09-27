module DbAgent
  class DbHandler
    class Composite < DbHandler

      def each_db_handler
        database_names.each do |name|
          yield(self.fork_config(database: name))
        end
      end

      def database_names
        [ config[:database] ]
      end

      Actions.public_instance_methods.each do |meth|
        define_method(meth) do |*args, &bl|
          each_db_handler do |db|
            db.send(meth, *args, &bl)
          end
        end
      end

      def seeder
        Seeder::Composite.new(self)
      end

    end # class Composite
  end # class DbHandler
end # module DbAgent
