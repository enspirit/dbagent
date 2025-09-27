module DbAgent
  class DbHandler
    module Relational

      def ping
        puts "Using #{config}"
        sequel_db.test_connection
        puts "Everything seems fine!"
      end

      def create
        raise NotImplementedError
      end

      def drop
        raise NotImplementedError
      end

      def backup
        raise NotImplementedError
      end

      def repl
        raise NotImplementedError
      end

      def wait_server
        require 'net/ping'
        raise "No host found" unless config[:host]
        check = Net::Ping::External.new(config[:host])
        print "Trying to ping `#{config[:host]}`\n"
        wait_timeout_in_seconds.downto(0) do |i|
          print "."
          if check.ping?
            print "\nServer found.\n"
            break
          elsif i == 0
            print "\n"
            raise "Server not found, I give up."
          else
            sleep(1)
          end
        end
      end

      def wait
        print "Using #{config}\n"
        wait_timeout_in_seconds.downto(0) do |i|
          print "."
          begin
            sequel_db.test_connection
            print "\nDatabase is there. Great.\n"
            break
          rescue Sequel::Error
            if i==0
              print "\n"
              raise
            end
            sleep(1)
          end
        end
      end

      def restore(t, args)
        raise NotImplementedError
      end

      def migrate(version = nil)
        Sequel.extension :migration
        sf = migrations_folder/'superuser'
        if sf.exists? && !sf.glob('*.rb').empty?
          Sequel::Migrator.run(sequel_superdb, migrations_folder/'superuser', table: superuser_migrations_table, target: version)
        end
        Sequel::Migrator.run(sequel_db, migrations_folder, table: migrations_table, target: version)
      end

      def repl
        raise NotImplementedError
      end

      def spy
        raise NotImplementedError
      end

    public

      def seeder
        Seeder::Relational.new(self)
      end

      def sequel_db
        @sequel_db ||= ::Sequel.connect(config)
      end

      def sequel_superdb
        raise "No superconfig set" if superconfig.nil?
        @sequel_superdb ||= ::Sequel.connect(superconfig)
      end

    end # module Relational
  end # class DbHandler
end # module DbAgent
