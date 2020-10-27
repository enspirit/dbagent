module DbAgent
  module Viewpoint
    # Delegates all relation accesses to `child`.
    module Delegate

      def method_missing(name, *args, &bl)
        return super unless args.empty? and bl.nil?
        child.send(name)
      end

    end # module Delegate
  end # module Viewpoint
end # module DbAgent
