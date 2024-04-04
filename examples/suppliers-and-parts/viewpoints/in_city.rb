module DbAgent
  module Viewpoint
    class InCity
      include Delegate

      def initialize(db)
        @child = Base.new(db)
      end
      attr_reader :child

      def suppliers
        child
          .suppliers
          .restrict(city: city)
      end

      def parts
        child
          .parts
          .restrict(city: city)
      end

      def supplies
        child
          .supplies
          .matching(suppliers, [:sid])
          .matching(parts, [:pid])
      end
      alias :public__supplies :supplies

    private

      def city
        "London"
      end

    end # class InCity
  end # module Viewpoint
end # module DbAgent
