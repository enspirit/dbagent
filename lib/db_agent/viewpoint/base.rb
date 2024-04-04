module DbAgent
  module Viewpoint
    # Factors relations on top of a Sequel database.
    class Base

      def initialize(db)
        @db = db
      end
      attr_reader :db

      def method_missing(name, *args, &bl)
        return super unless args.empty? and bl.nil?
        Bmg.sequel(qualify_table(name), db)
      end

    private

      def qualify_table(name)
        if name.to_s =~ /__/
          Sequel.qualify(*name.to_s.split('__').map(&:to_sym))
        else
          name
        end
      end

    end # class Base
  end # module Viewpoint
end # module DbAgent
