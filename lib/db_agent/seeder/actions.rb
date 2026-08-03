module DbAgent
  class Seeder
    module Actions

      def install(from)
      end

      def insert_script(from, include_parents: true)
      end

      def flush_empty(to = "empty")
      end

      def flush(to, inherits = "empty")
      end

      def check_seeds
      end

    end # module Actions
  end # class Seeder
end # module DbAgent
