require 'tsort'
module DbAgent
  class TableOrderer

    def initialize(handler)
      @handler = handler
    end
    attr_reader :handler

    def db
      handler.sequel_db
    end

    def tsort
      @tsort ||= TSortComputation.new(db).to_a
    end

    def graph
      @graph ||= TSortComputation.new(db).graph
    end

    def dependencies(table)
      _dependencies(table, ds = {})
      ds
        .inject([]){|memo,(_,plus)| (memo + plus).uniq }
        .sort{|t1,t2| tsort.index(t1) - tsort.index(t2) }
        .reject{|x| x == table }
    end

    def _dependencies(table, ds)
      return ds if ds.has_key?(table)
      ds[table] = graph[table]
      ds[table].each do |child|
        _dependencies(child, ds)
      end
    end
    private :_dependencies

    class TSortComputation
      include TSort

      def initialize(db, except = [])
        @db = db
        @except = except
      end
      attr_reader :db, :except

      def graph
        g = Hash.new{|h,k| h[k] = [] }
        tsort_each_node.each do |table|
          tsort_each_child(table) do |child|
            g[child] << table
          end
        end
        g
      rescue TSort::Cyclic
        raise unless killed = to_kill
        TSortComputation.new(db, except + [killed]).graph
      end

      def to_a
        tsort.to_a
      rescue TSort::Cyclic
        raise unless killed = to_kill
        TSortComputation.new(db, except + [killed]).to_a
      end

      def tsort_each_node(&bl)
        db.tables.each(&bl)
      end

      def tsort_each_child(table, &bl)
        db.foreign_key_list(table)
          .map{|fk| fk[:table] }
          .reject{|t|
            except.any?{|killed| killed.first == table && killed.last == t }
          }
          .each(&bl)
      end

    private

      def to_kill
        each_strongly_connected_component
          .select{|scc| scc.size > 1 }
          .sort_by{|scc| scc.size }
          .first
      end

    end # class TSortComputation

  end # class TableOrderer
end # module Dbagent

