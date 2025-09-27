module DbAgent
  class Seeder
    class Composite < Seeder

      def each_db_seeder
        handler.each_db_handler do |dbname, db_handler|
          yield(dbname, db_handler.seeder(dbname))
        end
      end

      Actions.public_instance_methods.each do |meth|
        define_method(meth) do |*args, &bl|
          each_db_seeder do |dbname, seeder|
            seeder.send(meth, *args, &bl)
          end
        end
      end

    end # class Composite
  end # class Seeder
end # module DbAgent
