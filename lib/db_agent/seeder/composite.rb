module DbAgent
  class Seeder
    class Composite < Seeder

      def each_db_seeder
        handler.each_db_handler do |db_handler|
          yield(db_handler.seeder)
        end
      end

      Actions.public_instance_methods.each do |meth|
        define_method(meth) do |*args, &bl|
          each_db_seeder do |seeder|
            seeder.send(meth, *args, &bl)
          end
        end
      end

    end # class Composite
  end # class Seeder
end # module DbAgent
