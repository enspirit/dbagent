module DbAgent
  module SeedUtils

    def file2table(file)
      file.basename.rm_ext.to_s[/^\d+-(.*)/, 1]
    end

    def qualify_table(table_name)
      parts = table_name.to_s.split('.')
      parts.size === 2 ? Sequel.qualify(*parts.map(&:to_sym)) : table_name.to_sym
    end

  end # module SeedUtils
end # module DbAgent
