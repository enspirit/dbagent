module DbAgent
  module Viewpoint
    # Forces typechecking on all child relations.
    class TypeCheck

      def initialize(db, child = nil)
        @db = db
        @child = child || DbAgent::Viewpoint::Base.new(db)
      end
      attr_reader :db, :child

      def method_missing(name, *args, &bl)
        return super unless args.empty? && bl.nil?
        child.send(name).with_typecheck
      end

    end # class TypeCheck
  end # module Viewpoint
end # module DbAgent
