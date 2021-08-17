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
        Bmg.sequel(name, db)
      end

    end # class Base
  end # module Viewpoint
end # module DbAgent
