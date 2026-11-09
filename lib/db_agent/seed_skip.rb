module DbAgent
  # Skips a seed install when the database cannot have changed since this
  # process last installed the very same seed files
  # (DBAGENT_SEED_SKIP_UNCHANGED).
  #
  # Test runners such as webspicy reinstall a seed before every test case, and
  # many test cases write nothing (reads, refused requests). Reinstalling then
  # rewrites every table to the state it is already in.
  #
  # "Cannot have changed" is the database driver's call: the install is skipped
  # when the handler's data version (DbHandler#data_version) is the one it
  # answered right after the last install, which means nobody wrote since: the
  # application under test, another dbagent process, `rake db:seed`. A driver
  # without a data version never skips. A data version may change without the
  # data changing, which only makes this install again when it did not need to.
  #
  # The data version is read right after the install commits; a write landing
  # in that window would be taken as part of the seed. Fine for a test runner
  # that waits for the install to answer before it calls anything else.
  class SeedSkip

    def self.current
      DbAgent.flag?(ENV['DBAGENT_SEED_SKIP_UNCHANGED'], false) ? INSTANCE : Never
    end

    def initialize
      @last = nil
      @warned = false
    end

    # Whether installing `seed` (reading `seed_files`) through `handler` would
    # leave the database exactly as it is.
    def skippable?(handler, seed, seed_files)
      return false unless supported?(handler) && @last

      version = handler.data_version
      !version.nil? && @last == [seed, files_stamp(seed_files), version]
    end

    # Records that `seed` was just installed, for the next `skippable?`.
    def installed!(handler, seed, seed_files)
      version = supported?(handler) ? handler.data_version : nil
      @last = version && [seed, files_stamp(seed_files), version]
    end

    # Forgets the last install, so that the next one is never skipped.
    def forget!
      @last = nil
    end

  private

    def supported?(handler)
      return true if handler.supports_data_version?

      unless @warned
        LOGGER.warn("Ignoring DBAGENT_SEED_SKIP_UNCHANGED: #{handler.class.name} has no data version")
        @warned = true
      end
      false
    end

    # Which files the install read, and when they last changed on disk.
    def files_stamp(seed_files)
      seed_files.values.map{|f| [f.to_s, f.mtime] }
    end

    INSTANCE = new

    module Never
      def self.skippable?(handler, seed, seed_files)
        false
      end

      def self.installed!(handler, seed, seed_files)
      end

      def self.forget!
      end
    end

  end # class SeedSkip
end # module DbAgent
